#!/bin/bash

# Create the 'template_pgencrypt' template db
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE DATABASE template_pgencrypt IS_TEMPLATE true;
EOSQL

# Load pgencrypt into both template_database and $POSTGRES_DB
for DB in template_pgencrypt "$POSTGRES_DB"; do
        echo "Loading pgencrypt extensions into $DB"
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
                CREATE EXTENSION IF NOT EXISTS pgencrypt;
		EOSQL
done
