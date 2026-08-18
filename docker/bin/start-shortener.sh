#!/bin/sh
set -e
cd /app/shortener
export PORT=3002
export DATABASE_URL="${SHORTENER_DATABASE_URL:?SHORTENER_DATABASE_URL is required}"
exec node dist/server/index.js
