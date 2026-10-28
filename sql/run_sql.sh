#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MYSQL_DIR="$SCRIPT_DIR/mysql"

if [ -f "$REPO_ROOT/backend/.env" ]; then
    ENV_FILE="$REPO_ROOT/backend/.env"
elif [ -f "$REPO_ROOT/.env" ]; then
    ENV_FILE="$REPO_ROOT/.env"
else
    echo "Error: .env file not found (looked in backend/.env and repo root)."
    exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if [ -z "$DB_HOST" ] || [ -z "$DB_USER" ] || [ -z "$DB_NAME" ]; then
    echo "Error: Missing database configuration in $ENV_FILE."
    exit 1
fi

if ! command -v mysql >/dev/null 2>&1; then
    echo "Error: MySQL client is not installed."
    exit 1
fi

run_sql() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "Error: File '$file' not found."
        exit 1
    fi

    if [[ "$file" != *.sql ]]; then
        echo "Error: '$file' is not a SQL file."
        exit 1
    fi

    echo "Executing $file..."

    MYSQL_PWD="$DB_PASSWORD" mysql \
        --host="$DB_HOST" \
        --port="${DB_PORT:-3306}" \
        --user="$DB_USER" \
        "$DB_NAME" < "$file"

    echo "Successfully executed $file."
}

if [ "$1" = "--all" ]; then
    shift

    if [ "$#" -gt 0 ]; then
        echo "Error: --all cannot be combined with filenames."
        exit 1
    fi

    shopt -s nullglob
    files=( "$MYSQL_DIR"/*.sql )

    if [ "${#files[@]}" -eq 0 ]; then
        echo "No SQL files found in $MYSQL_DIR."
        exit 0
    fi

    for file in "${files[@]}"; do
        run_sql "$file"
    done

elif [ "$#" -gt 0 ]; then
    for file in "$@"; do
        if [ -f "$file" ]; then
            run_sql "$file"
        elif [ -f "$MYSQL_DIR/$file" ]; then
            run_sql "$MYSQL_DIR/$file"
        elif [ -f "$SCRIPT_DIR/$file" ]; then
            run_sql "$SCRIPT_DIR/$file"
        else
            echo "Error: File '$file' not found."
            exit 1
        fi
    done

else
    echo "Usage:"
    echo "  ./sql/run_sql.sh --all"
    echo "  ./sql/run_sql.sh sql/mysql/creation.sql"
    echo "  ./sql/run_sql.sh creation.sql"
    exit 1
fi

echo "All requested SQL files executed successfully."
