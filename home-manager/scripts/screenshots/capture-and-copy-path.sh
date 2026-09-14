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

    # Play native macOS camera shutter / screen capture sound
    SOUND="/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Screen Capture.aif"
    if [ ! -f "$SOUND" ]; then
      SOUND="/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Shutter.aif"
    fi
    if [ -f "$SOUND" ]; then
      /usr/bin/afplay "$SOUND"
    fi

    # Auto-prune screenshots older than 3 days by safely moving to macOS Trash in background
    (
      find "$SHOT_DIR" -type f \( -name "Screenshot *.png" -o -name "clip_*.png" \) -mtime +3 -print0 2>/dev/null \
        | xargs -0 -r /usr/bin/trash 2>/dev/null || true
    ) &
  fi
fi
