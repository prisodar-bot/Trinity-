#!/bin/bash

set -e

# Load database configuration
if [ ! -f .env ]; then
    echo "Error: .env file not found."
    exit 1
fi

set -a
source .env
set +a

# Check required variables
if [ -z "$DB_HOST" ] || [ -z "$DB_USER" ] || [ -z "$DB_NAME" ]; then
    echo "Error: Missing database configuration in .env."
    exit 1
fi

# Check MySQL client
if ! command -v mysql >/dev/null 2>&1; then
    echo "Error: MySQL client is not installed."
    exit 1
fi

# Function to execute a SQL file
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

# Execute all SQL files
if [ "$1" = "--all" ]; then
    shift

    if [ "$#" -gt 0 ]; then
        echo "Error: --all cannot be combined with filenames."
        exit 1
    fi

    shopt -s nullglob
    files=( *.sql )

    if [ "${#files[@]}" -eq 0 ]; then
        echo "No SQL files found."
        exit 0
    fi

    for file in "${files[@]}"; do
        run_sql "$file"
    done

# Execute specified SQL files
elif [ "$#" -gt 0 ]; then
    for file in "$@"; do
        run_sql "$file"
    done

else
    echo "Usage:"
    echo "  ./run.sh --all"
    echo "  ./run.sh file1.sql file2.sql ..."
    exit 1
fi

echo "All requested SQL files executed successfully."