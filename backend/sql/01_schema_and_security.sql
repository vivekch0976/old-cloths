-- Run this against database old_clothes_app.
-- Example: psql -U postgres -d vintagedb -f backend/sql/01_schema_and_security.sql

CREATE SCHEMA IF NOT EXISTS VINTAGE AUTHORIZATION vintage;
ALTER SCHEMA VINTAGE OWNER TO vintage;

-- Keep public schema unavailable to the app role.
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM vintage;

GRANT USAGE, CREATE ON SCHEMA VINTAGE TO vintage;

-- If pgcrypto is available, allow UUID/random helpers later.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Default privilege model for future objects created by app owner.
ALTER DEFAULT PRIVILEGES FOR ROLE vintage IN SCHEMA VINTAGE
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO vintage;

ALTER DEFAULT PRIVILEGES FOR ROLE vintage IN SCHEMA VINTAGE
GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO vintage;
