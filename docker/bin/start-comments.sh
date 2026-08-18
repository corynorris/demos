#!/bin/sh
set -e
cd /app/comments
export PORT=3001
export DATABASE_URL="${COMMENTS_DATABASE_URL:?COMMENTS_DATABASE_URL is required}"
exec node dist/server/index.js
