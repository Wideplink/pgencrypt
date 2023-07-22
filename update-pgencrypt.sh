#!/bin/bash

set -e

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

PGENCRYPT_VERSION="${PGENCRYPT_VERSION%%+*}"

# Load pgencrypt into both template_database and $POSTGRES_DB
for DB in template_pgencrypt "$POSTGRES_DB" "${@}"; do
    echo "Updating pgencrypt extensions '$DB' to $PGENCRYPT_VERSION"
    psql --dbname="$DB" -c "
        -- Upgrade pgencrypt
        CREATE EXTENSION IF NOT EXISTS pgencrypt VERSION '$PGENCRYPT_VERSION';
        ALTER EXTENSION pgencrypt UPDATE TO '$PGENCRYPT_VERSION';
    "
done
