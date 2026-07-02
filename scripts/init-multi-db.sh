#!/bin/sh
# Ensures all shared databases exist. IDEMPOTENT — safe to run on every deploy.
#
# Runs in two places:
#   1. As a Postgres first-boot hook (/docker-entrypoint-initdb.d) — only fires
#      once, on an empty data dir.
#   2. As the standalone `db-init` compose service — this is what actually
#      provisions databases on an ALREADY-initialized volume, because first-boot
#      hooks never re-run once the volume exists.
#
# Connection is driven entirely by PG* env vars (psql/createdb read these
# automatically), so the same script works from both contexts.
set -eu

: "${PGUSER:=${POSTGRES_USER:-demos}}"
: "${PGDATABASE:=${POSTGRES_DB:-postgres}}"
export PGUSER PGDATABASE

DATABASES="spaced_repetition video_api trello url_shortener comments"

echo "init-multi-db: ensuring databases exist..."
for db in $DATABASES; do
    if [ "$(psql -tAc "SELECT 1 FROM pg_database WHERE datname='$db'")" = "1" ]; then
        echo "  - $db already exists"
    else
        echo "  - creating $db"
        createdb "$db"
    fi
done
echo "init-multi-db: done ($DATABASES)"
