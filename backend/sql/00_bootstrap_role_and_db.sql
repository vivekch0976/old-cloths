-- Run this script as a PostgreSQL superuser in psql.
-- Update the password before using in non-local environments.

SELECT
    'CREATE ROLE vintage LOGIN PASSWORD ''S3LLyour0LdCloth35'' NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'vintage'
)
\gexec

SELECT
    'CREATE DATABASE vintagedb OWNER vintage ENCODING ''UTF8'' TEMPLATE template0'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_database WHERE datname = 'vintagedb'
)
\gexec

GRANT CONNECT, TEMP ON DATABASE vintagedb TO vintage;
