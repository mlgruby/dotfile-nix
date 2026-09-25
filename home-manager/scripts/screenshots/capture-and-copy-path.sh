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
    # Multi-representation pasteboard via compiled Swift helper (image data + file path string):
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    HELPER="$HOME/bin/copy-screenshot-pasteboard"
    SWIFT_SRC="$SCRIPT_DIR/copy-screenshot-pasteboard.swift"

    # Auto-compile helper if missing or if source was updated
    if [ ! -x "$HELPER" ] || [ -f "$SWIFT_SRC" -a "$SWIFT_SRC" -nt "$HELPER" ]; then
      if [ -f "$SWIFT_SRC" ] && command -v swiftc >/dev/null 2>&1; then
        mkdir -p "$HOME/bin"
        swiftc -O "$SWIFT_SRC" -o "$HELPER" 2>/dev/null || true
      fi
    fi

    # Populate pasteboard using native Swift binary, falling back to pbcopy if unavailable
    if [ -x "$HELPER" ]; then
      "$HELPER" "$FILE" || printf '%s' "$FILE" | /usr/bin/pbcopy
    else
      printf '%s' "$FILE" | /usr/bin/pbcopy
    fi

    # Auto-prune screenshots older than 3 days by safely moving to macOS Trash in background
    (
      find "$SHOT_DIR" -type f \( -name "Screenshot *.png" -o -name "clip_*.png" \) -mtime +3 -print0 2>/dev/null \
        | xargs -0 -r /usr/bin/trash 2>/dev/null || true
    ) &
  fi
fi
