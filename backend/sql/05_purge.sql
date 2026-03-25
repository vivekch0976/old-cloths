-- Purge all application objects from the schema while keeping the database.
-- Drops the schema and everything inside it (tables, triggers, functions, indexes,
-- sequences, constraints), then recreates an empty schema owned by the app role.
--
-- Uses psql variables supplied by run_sql.sh:
--   :schema_name  (from DB_SCHEMA in db.conf)
--   :app_user     (from DB_APP_USER in db.conf)
--
-- WARNING: This is destructive and irreversible.
-- All data will be lost. Run only in development/staging environments or
-- when a full reset is intentional.
--
-- The database itself, the application role, and any extensions installed
-- at the database level (e.g. pgcrypto) are preserved.

-- Drop the schema and all objects it contains in one statement.
DROP SCHEMA IF EXISTS :"schema_name" CASCADE;

-- Recreate the schema owned by the app role so subsequent init scripts can run
-- without requiring a superuser session.
CREATE SCHEMA :"schema_name" AUTHORIZATION :"app_user";
ALTER SCHEMA :"schema_name" OWNER TO :"app_user";

-- Restore schema-level privileges that 01_schema_and_security.sql would have set.
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM :"app_user";
GRANT USAGE, CREATE ON SCHEMA :"schema_name" TO :"app_user";

-- Restore default object-creation privileges for the app role.
ALTER DEFAULT PRIVILEGES FOR ROLE :"app_user" IN SCHEMA :"schema_name"
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO :"app_user";

ALTER DEFAULT PRIVILEGES FOR ROLE :"app_user" IN SCHEMA :"schema_name"
GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO :"app_user";

ALTER DEFAULT PRIVILEGES FOR ROLE :"app_user" IN SCHEMA :"schema_name"
GRANT EXECUTE ON FUNCTIONS TO :"app_user";
