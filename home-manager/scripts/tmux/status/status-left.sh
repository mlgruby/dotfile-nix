#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$script_dir/lib.sh"
source "$script_dir/calendar.sh"
source "$script_dir/herdr.sh"
source "$script_dir/my-prs.sh"
source "$script_dir/reviews.sh"
source "$script_dir/aws.sh"

tmux_status_collect_calendar
tmux_status_collect_herdr
tmux_status_collect_my_prs
tmux_status_collect_reviews
tmux_status_collect_aws

session_name="${1:-main}"

left_output=""
left_prev_bg=""

append_left_segment() {
  local bg="$1"
  local fg="$2"
  local text="$3"
  [ -n "$text" ] || return 0

  if [ "$bg" = "$left_prev_bg" ]; then
    case "$bg" in
      "#3c3836") bg="#504945" ;;
      "#504945") bg="#3c3836" ;;
      "#fb4934") bg="#cc241d" ;;
      "#cc241d") bg="#fb4934" ;;
      "#fabd2f") bg="#d79921" ;;
      "#d79921") bg="#fabd2f" ;;
    esac
  fi

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

# 4. Own PR CI Watchdog (Red alert when your open PR has a failed check)
if [ -n "$my_prs_status" ]; then
  append_left_segment "$my_prs_bg" "$my_prs_fg" "$my_prs_status"
fi

# 5. GitHub PR Reviews Waiting on You
if [ -n "$reviews_status" ]; then
  append_left_segment "$reviews_bg" "$reviews_fg" "$reviews_status"
fi

# 6. AWS Proactive Expiry Alert (warns when <= 15m remaining or expired)
if [ -n "$aws_alert" ]; then
  append_left_segment "$aws_alert_bg" "$aws_alert_fg" "$aws_alert"
fi

# 4. Terminate smoothly into statusline dark background (#1d2021)
if [ -n "$left_prev_bg" ]; then
  left_output+="#[bg=#1d2021,fg=${left_prev_bg},nobold,noitalics,nounderscore]#[default]"
fi

printf '%s' "$left_output"
