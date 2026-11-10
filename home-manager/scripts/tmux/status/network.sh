#!/usr/bin/env bash

tmux_status_collect_network() {
  default_iface="$(route -n get default 2>/dev/null | awk '/interface:/ { print $2; exit }' || true)"

  # Transport bandwidth is passive noise during normal development.
  # Reserve statusbar space for actionable information: only surface network
  # state when offline (no default route or IP is up).
  network_label=""
  network_color="#fb4934"
  if [ -z "$default_iface" ] && ! ipconfig getifaddr en0 >/dev/null 2>&1; then
    network_label="󰖪 offline"
  fi
}
