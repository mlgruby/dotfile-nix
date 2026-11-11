#!/usr/bin/env bash
# herdr-popup.sh - Interactive tmux popup to view and jump to running Herdr agents
set -euo pipefail

if ! command -v herdr >/dev/null 2>&1; then
  echo "Herdr CLI is not installed."
  read -r -p "Press Enter to close..."
  exit 0
fi

raw="$(herdr agent list 2>/dev/null || true)"
if [ -z "$raw" ]; then
  echo ""
  echo "  No running Herdr agents or server socket not available."
  echo ""
  read -r -p "  Press Enter to close..."
  exit 0
fi

lines="$(
  printf '%s' "$raw" | jq -r '
    [.result.agents[]? |
      "[\(.agent_status | ascii_upcase)] \(.agent | ascii_upcase) (\(.workspace_id))\t\(.terminal_title // .cwd)\t\(.workspace_id)\t\(.pane_id)\t\(.cwd)"
    ] |
    sort_by(startswith("[WORKING]") | not) |
    if length == 0 then
      empty
    else
      .[]
    end
  ' 2>/dev/null || true
)"

if [ -z "$lines" ]; then
  echo ""
  echo "  ✓ No active agents in Herdr."
  echo ""
  read -r -p "  Press Enter to close..."
  exit 0
fi

if command -v fzf >/dev/null 2>&1; then
  selected="$(
    printf '%s\n' "$lines" | fzf \
      --delimiter=$'\t' \
      --with-nth=1,2 \
      --preview='printf "\033[1;33mAgent & Status:\033[0m %s\n\033[1;36mTask / Title:\033[0m %s\n\033[1;32mWorkspace:\033[0m %s\n\033[1;35mPane ID:\033[0m %s\n\033[1;34mDirectory:\033[0m %s\n" {1} {2} {3} {4} {5}' \
      --preview-window=down:5:wrap \
      --header="Herdr Agents | Enter: Focus Agent Workspace & Pane | Esc: Close" \
      --prompt="Select Agent > "
  )" || true

  if [ -n "$selected" ]; then
    ws="$(printf '%s' "$selected" | awk -F'\t' '{print $3}')"
    pane="$(printf '%s' "$selected" | awk -F'\t' '{print $4}')"
    if [ -n "$ws" ]; then
      herdr workspace focus "$ws" >/dev/null 2>&1 || true
    fi
    if [ -n "$pane" ]; then
      herdr pane focus --pane "$pane" >/dev/null 2>&1 || true
    fi
  fi
else
  echo "Herdr Agents:"
  printf '%s\n' "$lines" | while IFS=$'\t' read -r agent title ws pane cwd; do
    echo "  • $agent ($ws): $title"
  done
  echo ""
  read -r -p "Press Enter to close..."
fi
