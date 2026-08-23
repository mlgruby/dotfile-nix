#!/usr/bin/env bash

segment() {
  local bg="$1"
  local fg="$2"
  local prev_bg="$3"
  local text="$4"
  printf '#[fg=%s,bg=%s,nobold,nounderscore,noitalics]#[fg=%s,bg=%s] %s ' "$bg" "$prev_bg" "$fg" "$bg" "$text"
}

append_segment() {
  local bg="$1"
  local fg="$2"
  local text="$3"

  [ -n "$text" ] || return 0

  # Optional modules can leave two adjacent segments with the same background.
  # A powerline chevron between identical colours is invisible, so alternate the
  # neutral backgrounds automatically when that happens.
  if [ "$bg" = "$status_prev_bg" ]; then
    case "$bg" in
      "#3c3836") bg="#504945" ;;
      "#504945") bg="#3c3836" ;;
    esac
  fi

  status_output+=$(segment "$bg" "$fg" "$status_prev_bg" "$text")
  status_prev_bg="$bg"
}
