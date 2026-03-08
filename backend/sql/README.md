# Database Initialization Scripts

This folder contains ordered SQL scripts to initialize PostgreSQL for this application.

## Design

- Dedicated database role: `old_clothes_app_user`
- Dedicated database: `old_clothes_app`
- Dedicated schema: `app`
- Schema owner: `old_clothes_app_user`
- All application tables live under `app`
- Normalized core model:
  - `app.users`
  - `app.categories`
  - `app.items` (linked to user + category)

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

3. Run selected scripts by passing file names as arguments:

```bash
backend/sql/run_sql.sh 01_schema_and_security.sql 02_tables.sql
```

Run bootstrap as a superuser (for example `postgres`) because role/database creation requires elevated privileges:

```sql
\i backend/sql/00_bootstrap_role_and_db.sql
\i backend/sql/01_schema_and_security.sql
\i backend/sql/02_tables.sql
\i backend/sql/03_indexes.sql
\i backend/sql/04_seed_data.sql
```

## Notes

- Change the default password in `00_bootstrap_role_and_db.sql` before production use.
- Do not commit `backend/sql/db.conf` if it contains real credentials.
- The provided scripts intentionally avoid inserting table data.
