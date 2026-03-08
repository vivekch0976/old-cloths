#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SQL_CONFIG_FILE:-$SCRIPT_DIR/db.conf}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file not found: $CONFIG_FILE"
  echo "Copy $SCRIPT_DIR/db.conf.example to $SCRIPT_DIR/db.conf and edit values."
  exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

: "${DB_HOST:?DB_HOST is required in config}"
: "${DB_PORT:?DB_PORT is required in config}"
: "${DB_NAME:?DB_NAME is required in config}"
: "${DB_USER:?DB_USER is required in config}"
: "${DB_PASSWORD:?DB_PASSWORD is required in config}"

if ! command -v psql >/dev/null 2>&1; then
  echo "psql is not installed or not in PATH."
  exit 1
fi

if [[ "$#" -lt 1 ]]; then
  echo "Usage: $(basename "$0") <sql-file> [sql-file ...]"
  echo "Example: $(basename "$0") 00_bootstrap_role_and_db.sql 01_schema_and_security.sql"
  exit 1
fi

export PGPASSWORD="$DB_PASSWORD"

for arg in "$@"; do
  if [[ "$arg" = /* ]]; then
    sql_file="$arg"
  else
    sql_file="$SCRIPT_DIR/$arg"
  fi

  if [[ ! -f "$sql_file" ]]; then
    echo "SQL file not found: $sql_file"
    exit 1
  fi

  echo "Running: $sql_file"
  psql \
    --host="$DB_HOST" \
    --port="$DB_PORT" \
    --username="$DB_USER" \
    --dbname="$DB_NAME" \
    --file="$sql_file" \
    --set=ON_ERROR_STOP=1
done

echo "Done."

