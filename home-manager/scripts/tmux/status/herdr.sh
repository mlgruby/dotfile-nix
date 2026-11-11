#!/usr/bin/env bash
# herdr.sh - Collect active working agent count from local Herdr socket

tmux_status_collect_herdr() {
  herdr_status=""
  herdr_bg="#504945"
  herdr_fg="#83a598"

  if ! command -v herdr >/dev/null 2>&1; then
    return 0
  fi

  local socket="${XDG_CONFIG_HOME:-$HOME/.config}/herdr/herdr.sock"
  [ -S "$socket" ] || return 0

  local working_count
  working_count="$(
    herdr agent list 2>/dev/null | jq -r '
      [.result.agents[]? | select(.agent_status == "working")] | length
    ' 2>/dev/null || echo 0
  )"

  if [ -n "$working_count" ] && [ "$working_count" -gt 0 ] 2>/dev/null; then
    local label="agent"
    [ "$working_count" -gt 1 ] && label="agents"
    herdr_status="󰚩 ${working_count} ${label} working"
    herdr_bg="#504945"
    herdr_fg="#83a598"
  fi
}
