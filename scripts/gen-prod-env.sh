#!/usr/bin/env bash
# Interactive generator for a demos production .env (paste into Dokploy).
#
# Auto-generates every secret with openssl and prompts for the few values only
# you know (domain). Press Enter to accept the default in [brackets].
#
# Usage:
#   ./scripts/gen-prod-env.sh            # writes .env.prod
#   ./scripts/gen-prod-env.sh out.env    # custom output path
#
# WARNING: POSTGRES_PASSWORD is baked into the data volume on FIRST boot.
# Do NOT regenerate it after a successful deploy or the volume will reject
# the new credentials.
set -euo pipefail

OUT="${1:-.env.prod}"

if ! command -v openssl >/dev/null 2>&1; then
  echo "error: openssl not found (required to generate secrets)" >&2
  exit 1
fi

if [ -e "$OUT" ]; then
  read -rp "$OUT exists — overwrite? [y/N]: " reply
  case "$reply" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "aborted." >&2; exit 1 ;;
  esac
fi

gen() { openssl rand -hex "${1:-24}"; }

ask() {
  local ans
  read -rp "$1 [${2}]: " ans
  printf '%s' "${ans:-$2}"
}

echo
echo "  demos.corynorris.me — prod env generator"
echo "  ─────────────────────────────────────────"
echo "  Press Enter to accept defaults in [brackets]."
echo "  Secrets are auto-generated with openssl."
echo

DOMAIN=$(ask "Domain" "demos.corynorris.me")
SHORTENER_URL=$(ask "URL shortener base URL" "https://${DOMAIN}/s")
VIDEO_KEY_BASE=$(gen 64)
VIDEO_SECRET=$(gen 32)

cat > "$OUT" <<EOF
# demos.corynorris.me production env — generated $(date -u +%FT%TZ)
# Paste into Dokploy. Only DB_PASSWORD must keep its value across redeploys.

# ===================
# PostgreSQL (shared) — databases: spaced_repetition, video_api
# do NOT change after first successful deploy
# ===================
POSTGRES_USER=demos
POSTGRES_PASSWORD=$(gen 24)

# ===================
# URL Shortener
# ===================
BASE_URL=${SHORTENER_URL}

# ===================
# Spaced Repetition (Rust/Axum)
# ===================
DATABASE_URL=postgres://demos:\${POSTGRES_PASSWORD}@db:5432/spaced_repetition

# ===================
# Video API (Elixir/Phoenix)
# ===================
VIDEO_SECRET_KEY_BASE=${VIDEO_KEY_BASE}
VIDEO_SECRET_KEY=${VIDEO_SECRET}

# ===================
# Public domain
# ===================
DOMAIN=${DOMAIN}
EOF

chmod 600 "$OUT"

echo
echo "─────────────────────────────────────────"
echo "Wrote $OUT (chmod 600)."
echo
echo "Paste into Dokploy → Environment variables:"
echo "  cat $OUT"
echo
echo "WARNING: POSTGRES_PASSWORD is written into the volume on first boot."
echo "Do NOT regenerate it after the first successful deploy."
