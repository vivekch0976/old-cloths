-- Schema and security setup.
-- Uses psql variables from run_sql.sh:
--   :schema_name (from DB_SCHEMA)
--   :app_user    (from DB_APP_USER)

CREATE SCHEMA IF NOT EXISTS :"schema_name" AUTHORIZATION :"app_user";
ALTER SCHEMA :"schema_name" OWNER TO :"app_user";

-- Keep public schema unavailable to the app role.
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM :"app_user";

GRANT USAGE, CREATE ON SCHEMA :"schema_name" TO :"app_user";

-- If pgcrypto is available, allow UUID/random helpers later.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Default privilege model for future objects created by app owner.
ALTER DEFAULT PRIVILEGES FOR ROLE :"app_user" IN SCHEMA :"schema_name"
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO :"app_user";

ALTER DEFAULT PRIVILEGES FOR ROLE :"app_user" IN SCHEMA :"schema_name"
GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO :"app_user";

ALTER DEFAULT PRIVILEGES FOR ROLE :"app_user" IN SCHEMA :"schema_name"
GRANT EXECUTE ON FUNCTIONS TO :"app_user";
