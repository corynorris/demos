#!/bin/sh
set -e
cd /app/srs
export PORT=3005
export HOST=0.0.0.0
export BASE_PATH=/srs
export DATABASE_URL="${SRS_DATABASE_URL:?SRS_DATABASE_URL is required}"
export BETTER_AUTH_URL="${BETTER_AUTH_URL:-https://demos.corynorris.me/srs}"
export BETTER_AUTH_SECRET="${BETTER_AUTH_SECRET:-change-me-dev-secret-min-32-chars}"
export LLM_BASE_URL="${LLM_BASE_URL:-}"
export LLM_MODEL="${LLM_MODEL:-}"
export LLM_API_KEY="${LLM_API_KEY:-}"
export LLM_TIMEOUT_MS="${LLM_TIMEOUT_MS:-60000}"
export AI_RATE_LIMIT_PER_USER="${AI_RATE_LIMIT_PER_USER:-5}"
export AI_RATE_LIMIT_WINDOW_MS="${AI_RATE_LIMIT_WINDOW_MS:-60000}"
exec ./docker-entrypoint.sh
