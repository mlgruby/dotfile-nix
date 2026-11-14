#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$script_dir/lib.sh"
source "$script_dir/calendar.sh"
source "$script_dir/herdr.sh"
source "$script_dir/reviews.sh"

tmux_status_collect_calendar
tmux_status_collect_herdr
tmux_status_collect_reviews

session_name="${1:-main}"

left_output=""
left_prev_bg=""

append_left_segment() {
  local bg="$1"
  local fg="$2"
  local text="$3"
  [ -n "$text" ] || return 0

  bg="$(tmux_status_alt_bg "$bg" "$left_prev_bg")"

  if [ -z "$left_prev_bg" ]; then
    left_output+="#[bg=${bg},fg=${fg}] ${text} "
  else
    left_output+="#[bg=${bg},fg=${left_prev_bg},nobold,noitalics,nounderscore]#[bg=${bg},fg=${fg}] ${text} "
  fi
  left_prev_bg="$bg"
}

# 1. Tmux Session Name
append_left_segment "#665c54" "#bdae93" "$session_name"

# 2. Herdr Active Agent Monitor (visible only when agents are working)
if [ -n "$herdr_status" ]; then
  append_left_segment "$herdr_bg" "$herdr_fg" "$herdr_status"
fi

# 3. Calendar Guard (Upcoming meeting notice / urgent alert)
if [ -n "$calendar_status" ]; then
  append_left_segment "$calendar_bg" "$calendar_fg" "$calendar_status"
fi

# 4. GitHub PR Reviews Waiting on You
if [ -n "$reviews_status" ]; then
  append_left_segment "$reviews_bg" "$reviews_fg" "$reviews_status"
fi

# Terminate smoothly into statusline dark background (#1d2021)
if [ -n "$left_prev_bg" ]; then
  left_output+="#[bg=#1d2021,fg=${left_prev_bg},nobold,noitalics,nounderscore]#[default]"
fi

printf '%s' "$left_output"
