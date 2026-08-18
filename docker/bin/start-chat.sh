#!/bin/sh
set -e
cd /app/chat
export PORT=3000
exec node dist/server/index.js
