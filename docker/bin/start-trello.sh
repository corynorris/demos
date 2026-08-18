#!/bin/sh
set -e
cd /app/trello
export MIX_ENV=prod
export PORT=4000
export BASE_PATH=/trello
export SECRET_KEY_BASE="${TRELLO_SECRET_KEY_BASE:?TRELLO_SECRET_KEY_BASE is required}"
export SECRET_KEY="${TRELLO_SECRET_KEY:?TRELLO_SECRET_KEY is required}"
export DATABASE_URL="${TRELLO_DATABASE_URL:?TRELLO_DATABASE_URL is required}"
export PHX_HOST="${DOMAIN:-demos.corynorris.me}"
mix ecto.migrate
exec mix phx.server
