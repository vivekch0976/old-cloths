#!/bin/sh
[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${SQL_CONFIG_FILE:-$SCRIPT_DIR/db.conf}"
LOG_DIR="${SQL_LOG_DIR:-$SCRIPT_DIR/logs}"
mkdir -p "$LOG_DIR"
LOG_FILE="${SQL_LOG_FILE:-$LOG_DIR/run_sql_$(date +%Y%m%d_%H%M%S).log}"
LOG_LEVEL="${SQL_LOG_LEVEL:-INFO}"

timestamp() {
  date +"%Y-%m-%dT%H:%M:%S%z"
}

is_debug_enabled() {
  [ "$LOG_LEVEL" = "DEBUG" ]
}

prompt_password_masked() {
  local prompt_text="${1:-Password: }"
  local password=""
  local char=""

  if [ ! -t 0 ] && [ ! -t 1 ]; then
    return 1
  fi

  printf "%s" "$prompt_text" >/dev/tty
  stty -echo </dev/tty
  while IFS= read -r -s -n1 char </dev/tty; do
    if [ -z "$char" ]; then
      break
    fi
    case "$char" in
    $'\n' | $'\r')
      break
      ;;
    $'\177' | $'\b')
      if [ -n "$password" ]; then
        password="${password%?}"
        printf '\b \b' >/dev/tty
      fi
      ;;
    *)
      password+="$char"
      printf '*' >/dev/tty
      ;;
    esac
  done
  stty echo </dev/tty
  printf '\n' >/dev/tty
  printf '%s' "$password"
}

log_info() {
  printf "%s [INFO] %s\n" "$(timestamp)" "$1" >>"$LOG_FILE"
}

log_debug() {
  if is_debug_enabled; then
    printf "%s [DEBUG] %s\n" "$(timestamp)" "$1" >>"$LOG_FILE"
  fi
}

log_error() {
  printf "%s [ERROR] %s\n" "$(timestamp)" "$1" >>"$LOG_FILE"
}

log_info "Starting SQL runner"
log_info "Using config file: $CONFIG_FILE"
log_info "Logging to: $LOG_FILE"

if [ ! -f "$CONFIG_FILE" ]; then
  log_error "Config file not found: $CONFIG_FILE"
  log_error "Copy $SCRIPT_DIR/db.conf.example to $SCRIPT_DIR/db.conf and edit values."
  exit 1
fi

. "$CONFIG_FILE"

for required in DB_HOST DB_PORT DB_NAME DB_SCHEMA; do
  eval "value=\${$required:-}"
  if [ -z "$value" ]; then
    log_error "$required is required in config"
    exit 1
  fi
done

if [ -z "${DB_APP_USER:-}" ]; then
  log_error "DB_APP_USER is required"
  exit 1
fi

ALLOWED_SCHEMA="${SQL_ALLOWED_SCHEMA:-vintage}"
if [ "$DB_SCHEMA" != "$ALLOWED_SCHEMA" ]; then
  log_error "DB_SCHEMA must be '$ALLOWED_SCHEMA' for DB_APP_USER operations. Current value: '$DB_SCHEMA'"
  exit 1
fi

if ! command -v psql >/dev/null 2>&1; then
  log_error "psql is not installed or not in PATH."
  exit 1
fi

if [ "$#" -lt 1 ]; then
  log_error "Usage: $(basename "$0") <sql-file> [sql-file ...]"
  log_error "Example: $(basename "$0") 00_bootstrap_role_and_db.sql 01_schema_and_security.sql"
  exit 1
fi

PASSWORD_MODE="${SQL_PROMPT_PASSWORD:-always}"
PSQL_PASSWORD_FLAG="-W"
if [ "$PASSWORD_MODE" = "config" ]; then
  if [ -z "${DB_PASSWORD:-}" ]; then
    log_error "DB_PASSWORD is required when SQL_PROMPT_PASSWORD=config"
    exit 1
  fi
  export PGPASSWORD="$DB_PASSWORD"
  PSQL_PASSWORD_FLAG=""
  log_info "Password mode: config"
else
  if ! DB_PASSWORD="$(prompt_password_masked "Database password for user '$DB_APP_USER' on database '$DB_NAME': ")"; then
    log_error "Interactive password prompt requires a terminal. Use SQL_PROMPT_PASSWORD=config for non-interactive runs."
    exit 1
  fi
  export PGPASSWORD="$DB_PASSWORD"
  PSQL_PASSWORD_FLAG=""
  log_info "Password mode: prompt(masked)"
fi

log_debug "DB_HOST=$DB_HOST DB_PORT=$DB_PORT DB_NAME=$DB_NAME DB_SCHEMA=$DB_SCHEMA DB_APP_USER=$DB_APP_USER"

for arg in "$@"; do
  case "$arg" in
  /*)
    sql_file="$arg"
    ;;
  *)
    sql_file="$SCRIPT_DIR/$arg"
    ;;
  esac

  if [ ! -f "$sql_file" ]; then
    log_error "SQL file not found: $sql_file"
    exit 1
  fi

  log_info "Running script: $sql_file"
  db_name="$DB_NAME"
  case "$(basename "$sql_file")" in
  00_bootstrap_role_and_db.sql)
    db_name="${DB_BOOTSTRAP_NAME:-postgres}"
    ;;
  esac
  log_debug "Connecting with database: $db_name"

  if ! psql \
    --host="$DB_HOST" \
    --port="$DB_PORT" \
    --username="$DB_APP_USER" \
    --dbname="$db_name" \
    $PSQL_PASSWORD_FLAG \
    --set=schema_name="$DB_SCHEMA" \
    --set=app_user="$DB_APP_USER" \
    --file="$sql_file" \
    --set=ON_ERROR_STOP=1 >>"$LOG_FILE" 2>&1; then
    log_error "Failed script: $sql_file"
    exit 1
  fi
  log_info "Completed script: $sql_file"
done

log_info "SQL runner completed successfully"
