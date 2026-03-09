# Database Initialization Scripts

This folder contains ordered SQL scripts to initialize PostgreSQL for this application.

## Design

- Dedicated database role: `old_clothes_app_user`
- Dedicated database: `old_clothes_app`
- Dedicated schema: `app`
- Schema owner: `old_clothes_app_user`
- All application tables live under `app`
- Normalized sell-flow model:
  - `users` (seller/account data)
  - `categories` (item category master)
  - `items` (core listing + ownership)
  - `item_descriptions` (description/tag/fit text)
  - `item_pricing` (price, payout, listing preferences)
  - `item_shipping` (location/shipping/returns)
  - `item_media` (photos/videos per item)
  - `item_engagement` (featured/saves/watchers/price drops)

## Script Order

1. `00_bootstrap_role_and_db.sql`
2. `01_schema_and_security.sql`
3. `02_tables.sql`
4. `03_indexes.sql`
5. `04_seed_data.sql` (no inserts by default)

## Usage

1. Create config file:

```bash
cp backend/sql/db.conf.example backend/sql/db.conf
```

2. Edit `backend/sql/db.conf` with your DB connection.
Required keys include: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_SCHEMA`, `DB_APP_USER`.

3. Run selected scripts by passing file names as arguments:

```bash
sh backend/sql/run_sql.sh 01_schema_and_security.sql 02_tables.sql
```

Logs:
- Default log location: `backend/sql/logs/run_sql_YYYYMMDD_HHMMSS.log`
- Optional overrides:
  - `SQL_LOG_DIR=/custom/path`
  - `SQL_LOG_FILE=/custom/path/sql.log`
  - `SQL_LOG_LEVEL=DEBUG` (default is `INFO`)

Password behavior:
- Default: prompts interactively every run (`SQL_PROMPT_PASSWORD=always`)
- Optional non-interactive mode: `SQL_PROMPT_PASSWORD=config` (uses `DB_PASSWORD` from config)

Bootstrap note: `00_bootstrap_role_and_db.sql` is executed against `DB_BOOTSTRAP_NAME` (default `postgres`) so it can create `DB_NAME` if it does not exist yet.
Schema note: `01/02/03` scripts create objects only inside `DB_SCHEMA`.
Enforcement note: runner allows app-user execution only when `DB_SCHEMA=vintage` by default.
Override (if needed): `SQL_ALLOWED_SCHEMA=<schema_name>`.

Run full initialization (bootstrap requires a superuser such as `postgres`):

```bash
sh backend/sql/run_sql.sh \
  00_bootstrap_role_and_db.sql \
  01_schema_and_security.sql \
  02_tables.sql \
  03_indexes.sql \
  04_seed_data.sql
```

## Notes

- Change the default password in `00_bootstrap_role_and_db.sql` before production use.
- Do not commit `backend/sql/db.conf` if it contains real credentials.
- The provided scripts intentionally avoid inserting table data.
