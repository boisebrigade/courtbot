#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE DATABASE courtbot_test;
	GRANT ALL PRIVILEGES ON DATABASE courtbot_test TO $POSTGRES_USER;
EOSQL
