#!/bin/sh
set -e
cd /app/voting
export PORT=8090
exec node dist-server/server/index.js
