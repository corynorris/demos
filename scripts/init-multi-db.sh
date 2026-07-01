#!/bin/bash
# Runs once on first Postgres init (empty data dir) via
# /docker-entrypoint-initdb.d. Creates the shared databases.
#
#   spaced_repetition  -> Rust/Axum + GraphQL spaced repetition app
#   video_api          -> Elixir/Phoenix video transcoding platform

set -e

echo "init-multi-db: creating databases..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE spaced_repetition;
    CREATE DATABASE video_api;
EOSQL

echo "init-multi-db: done (spaced_repetition, video_api)"
