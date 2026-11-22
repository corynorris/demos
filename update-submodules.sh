#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Apps built into the deploy image and therefore pinned in
# docker/submodule-pins.txt. Keep in sync with the root Dockerfile.
# video-api is a submodule but is not part of the deployed stack, so it is
# deliberately not pinned.
PINNED_APPS=(
	roguelike
	life
	recipebox
	tilemap
	voting-app-react
	socket-io-chat-app
	react-comment-box
	url-shortener
	spaced-repitition
	trello
)

echo "Updating all submodules to latest main..."
git submodule update --remote --merge
echo

# The Dokku Dockerfile clones each app at the SHA in this file (Dokku does not
# check out submodules), so the pins must move with the submodule pointers or
# the deploy silently builds the previous app commits.
PINS_FILE="docker/submodule-pins.txt"
tmp="$(mktemp)"
{
	echo "# Pinned commits for the app submodules (mirror of git submodule status)."
	echo "# Kept in sync manually when submodules are bumped; used by the root Dockerfile"
	echo "# to clone each app at the exact commit deployed."
	for app in "${PINNED_APPS[@]}"; do
		sha="$(git submodule status "apps/${app}" | awk '{print $1}' | sed 's/^[+-]//')"
		if [ -z "$sha" ]; then
			echo "error: apps/${app} is not an initialised submodule" >&2
			rm -f "$tmp"
			exit 1
		fi
		echo "${app} ${sha}"
	done
} >"$tmp"
mv "$tmp" "$PINS_FILE"

echo "Submodule status:"
git submodule status
echo
echo "Changes staged for review:"
git add apps "${PINS_FILE}"
git diff --cached --stat
echo
echo "Next steps:"
echo "  git commit -m 'chore: update submodules to latest'"
echo "  git push origin main"
echo "  git push dokku main   # deploys to https://demos.corynorris.me"
