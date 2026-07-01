#!/usr/bin/env bash
# Pre-deploy setup — clones/updates all app repos into apps/.
# Dokploy runs this before docker compose build.
# Idempotent: skips repos that already exist (git pull if already cloned).
set -euo pipefail

APPS_DIR="$(cd "$(dirname "$0")/.." && pwd)/apps"
REPOS=(
  "roguelike"
  "life"
  "recipebox"
  "voting-app-react"
  "socket-io-chat-app"
  "react-comment-box"
  "url-shortener"
  "spaced-repitition"
  "video-api"
)

mkdir -p "$APPS_DIR"

for repo in "${REPOS[@]}"; do
  target="$APPS_DIR/$repo"
  if [ -d "$target/.git" ]; then
    echo "[setup] $repo: already cloned, pulling latest main..."
    git -C "$target" fetch origin main
    git -C "$target" checkout main
    git -C "$target" pull origin main
  else
    echo "[setup] $repo: cloning..."
    rm -rf "$target"
    git clone --depth 1 --single-branch --branch main \
      "https://github.com/corynorris/${repo}.git" "$target"
  fi
done

echo "[setup] all apps ready"
