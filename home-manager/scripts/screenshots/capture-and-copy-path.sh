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
    # Multi-representation pasteboard:
    # 1. Plain text file path (for terminals & CLI AI agents like agy / Claude / Codex)
    # 2. Raw PNG image binary (for web apps, chat, Slack, Discord, Google Docs, Figma)
    # 3. File URL (for Finder, file pickers, drag & drop)
    /usr/bin/osascript -l JavaScript - "$FILE" <<'EOF' || printf '%s' "$FILE" | /usr/bin/pbcopy
function run(argv) {
  ObjC.import("AppKit");
  var filePath = argv[0];
  var pb = $.NSPasteboard.generalPasteboard;
  pb.clearContents;

  var item = $.NSPasteboardItem.alloc.init;
  item.setStringForType($(filePath), $.NSPasteboardTypeString);

  var fileUrl = $.NSURL.fileURLWithPath($(filePath));
  var imgData = $.NSData.dataWithContentsOfURL(fileUrl);
  if (imgData) {
    item.setDataForType(imgData, $.NSPasteboardTypePNG);
  }
  item.setStringForType(fileUrl.absoluteString, $.NSPasteboardTypeFileURL);

  pb.writeObjects($([item]));
}
EOF

    # Auto-prune screenshots older than 3 days by safely moving to macOS Trash in background
    (
      find "$SHOT_DIR" -type f \( -name "Screenshot *.png" -o -name "clip_*.png" \) -mtime +3 -print0 2>/dev/null \
        | xargs -0 -r /usr/bin/trash 2>/dev/null || true
    ) &
  fi
fi
