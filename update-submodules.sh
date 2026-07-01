#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Updating all submodules to latest main..."
echo ""

# Update all submodules to latest remote
git submodule update --remote

echo ""
echo "Submodule status:"
git submodule status

echo ""
echo "Changes detected in:"
git diff --name-only

echo ""
echo "To commit and push these updates:"
echo "  git add -A && git commit -m 'chore: update all submodules to latest' && git push"
