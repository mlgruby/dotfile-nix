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

  status_output+=$(segment "$bg" "$fg" "$status_prev_bg" "$text")
  status_prev_bg="$bg"
}
