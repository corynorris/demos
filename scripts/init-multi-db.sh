#!/bin/bash
# Runs once on first Postgres init (empty data dir) via
# /docker-entrypoint-initdb.d. Creates the shared databases.

set -e

echo "init-multi-db: creating databases..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE spaced_repetition;
    CREATE DATABASE video_api;
    CREATE DATABASE trello;
    CREATE DATABASE url_shortener;
    CREATE DATABASE comments;
EOSQL

echo "init-multi-db: done (spaced_repetition, video_api, trello, url_shortener, comments)"
