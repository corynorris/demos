#!/bin/sh
# Sets the Vite `base` option for an app whose config lacks one (or updates an
# existing one). Usage: set-vite-base.sh <base-path>
set -eu

BASE="$1"
for f in vite.config.ts vite.config.js; do
    [ -f "$f" ] || continue
    if grep -q "base:" "$f"; then
        sed -i "s|base: *['\"][^'\"]*['\"]|base: '${BASE}'|" "$f"
    else
        sed -i "s|defineConfig({|defineConfig({ base: '${BASE}',|" "$f"
    fi
done
