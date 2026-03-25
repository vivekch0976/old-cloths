-- Schema and security setup.
-- Uses psql variables supplied by run_sql.sh:
--   :schema_name  (from DB_SCHEMA in db.conf)
--   :app_user     (from DB_APP_USER in db.conf)

CREATE SCHEMA IF NOT EXISTS :"schema_name" AUTHORIZATION :"app_user";
ALTER SCHEMA :"schema_name" OWNER TO :"app_user";

-- Prevent the app role from accessing the public schema.
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM :"app_user";

-- Grant the app role full use of its own schema.
GRANT USAGE, CREATE ON SCHEMA :"schema_name" TO :"app_user";

-- Enable pgcrypto for password hashing and UUID helpers.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Default privileges for objects created later by the app role.
ALTER DEFAULT PRIVILEGES FOR ROLE :"app_user" IN SCHEMA :"schema_name"
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO :"app_user";

ALTER DEFAULT PRIVILEGES FOR ROLE :"app_user" IN SCHEMA :"schema_name"
GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO :"app_user";

ALTER DEFAULT PRIVILEGES FOR ROLE :"app_user" IN SCHEMA :"schema_name"
GRANT EXECUTE ON FUNCTIONS TO :"app_user";
