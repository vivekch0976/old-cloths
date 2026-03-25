# Database Initialization Scripts

SQL scripts for initializing and managing the PostgreSQL database used by VintageLoop.

## Design

| Property | Value |
|---|---|
| Database role | `old_clothes_app` |
| Database name | `old_clothes_db` |
| Schema | `app` |
| Schema owner | `old_clothes_app` |

### Tables (normalized sell-flow model)

| Table | Purpose |
|---|---|
| `users` | Seller account data (maps to `RegisterCreate`) |
| `categories` | Item category master list |
| `items` | Core listing identity and ownership (maps to `ListingCreate`) |
| `item_descriptions` | Description, tag, fit text, and presentation metadata |
| `item_pricing` | Price, payout method, and seller preferences |
| `item_shipping` | Location, shipping time, cost, and returns policy |
| `item_media` | Photos and videos per listing |
| `item_engagement` | Featured flag, saves, watchers, and price-drop counter |

## Script Order

| File | Purpose | Run as |
|---|---|---|
| `00_bootstrap_role_and_db.sql` | Create role and database | Superuser |
| `01_schema_and_security.sql` | Create schema, security model, extensions | App user |
| `02_tables.sql` | Create all tables, triggers, and trigger function | App user |
| `03_indexes.sql` | Create query-optimised indexes | App user |
| `04_seed_data.sql` | Seed data (empty by default) | App user |
| `05_purge.sql` | Drop all objects and recreate empty schema | App user |

## Usage

### 1. Create configuration file

```bash
cp backend/sql/db.conf.example backend/sql/db.conf
```

Edit `backend/sql/db.conf` with your connection values.
Required keys: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_SCHEMA`, `DB_APP_USER`.

> **Do not commit `db.conf`** — it may contain credentials.

### 2. Run initialization (full setup)

```bash
sh backend/sql/run_sql.sh \
  00_bootstrap_role_and_db.sql \
  01_schema_and_security.sql \
  02_tables.sql \
  03_indexes.sql \
  04_seed_data.sql
```

`00_bootstrap_role_and_db.sql` connects to `DB_BOOTSTRAP_NAME` (default `postgres`) so it can
create the role and database if they do not yet exist. The remaining scripts run against `DB_NAME`.

### 3. Run individual scripts

```bash
sh backend/sql/run_sql.sh 02_tables.sql
sh backend/sql/run_sql.sh 03_indexes.sql
```

### 4. Purge all objects (keep database)

```bash
sh backend/sql/run_sql.sh 05_purge.sql
```

Drops the schema and every object inside it (tables, triggers, functions, indexes, sequences),
then recreates an empty schema owned by the app role. The database, role, and any
database-level extensions (e.g. `pgcrypto`) are preserved.

> **This is destructive.** All data will be lost. Use only in development or staging
> environments, or when a full reset is intentional.

To rebuild immediately after purging:

```bash
sh backend/sql/run_sql.sh \
  05_purge.sql \
  02_tables.sql \
  03_indexes.sql
```

## Logging

Logs are written to `backend/sql/logs/run_sql_YYYYMMDD_HHMMSS.log`.

| Variable | Default | Description |
|---|---|---|
| `SQL_LOG_DIR` | `backend/sql/logs` | Directory for log files |
| `SQL_LOG_FILE` | auto-generated | Full path to log file |
| `SQL_LOG_LEVEL` | `INFO` | Set to `DEBUG` for verbose output |

## Password handling

| Variable | Value | Behaviour |
|---|---|---|
| `SQL_PROMPT_PASSWORD` | `always` (default) | Prompts interactively on every run |
| `SQL_PROMPT_PASSWORD` | `config` | Reads `DB_PASSWORD` from `db.conf` (non-interactive) |

## Schema enforcement

The runner validates that `DB_SCHEMA` matches the allowed schema before executing any script.
The default allowed value is `app`. Override with:

```bash
SQL_ALLOWED_SCHEMA=<schema_name> sh backend/sql/run_sql.sh 02_tables.sql
```

## Notes

- Change the default password in `00_bootstrap_role_and_db.sql` before production use.
- `04_seed_data.sql` is intentionally empty. Add test data in separate, non-production files.
- Scripts use `IF NOT EXISTS` / `IF EXISTS` guards wherever possible, making them safe to re-run.
