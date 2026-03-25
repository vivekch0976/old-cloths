-- Run this script as a PostgreSQL superuser (e.g. postgres) in psql.
-- It creates the application role and database if they do not already exist.
--
-- IMPORTANT: Replace the placeholder password below with a strong, randomly
-- generated value before running in any shared, staging, or production
-- environment. Never commit a real password to source control.

SELECT
    'CREATE ROLE old_clothes_app LOGIN PASSWORD ''Ch4ng3M3!'' NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'old_clothes_app'
)
\gexec

SELECT
    'CREATE DATABASE old_clothes_db OWNER old_clothes_app ENCODING ''UTF8'' TEMPLATE template0'
WHERE NOT EXISTS (
    SELECT 1 FROM pg_database WHERE datname = 'old_clothes_db'
)
\gexec

GRANT CONNECT, TEMP ON DATABASE old_clothes_db TO old_clothes_app;
