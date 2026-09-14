#!/usr/bin/env bash
# home-manager/scripts/screenshots/capture-and-copy-path.sh
#
# Interactive screenshot capture:
# - Invoked via Karabiner Cmd+Shift+4.
# - Captures selection directly to ~/Screenshots.
# - Automatically copies the absolute file path to the macOS clipboard so
#   you can immediately Cmd+V inside AI coding agents (Antigravity, Codex, Claude).

set -euo pipefail

SHOT_DIR="$HOME/Screenshots"
mkdir -p "$SHOT_DIR"

TIMESTAMP="$(date '+%Y-%m-%d at %H.%M.%S')"
FILE="$SHOT_DIR/Screenshot $TIMESTAMP.png"

# -i : interactive selection
# If user cancels (e.g. hits Escape), screencapture exits non-zero without creating a file.
if /usr/sbin/screencapture -i "$FILE"; then
  if [ -f "$FILE" ]; then
    printf '%s' "$FILE" | /usr/bin/pbcopy
  fi
fi
