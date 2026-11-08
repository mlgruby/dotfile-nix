#!/usr/bin/env bash

tmux_status_collect_network() {
  default_iface="$(route -n get default 2>/dev/null | awk '/interface:/ { print $2; exit }' || true)"

  # Transport is not useful when connected; reserve bar space for actionable
  # information. Only surface network state when no default route / IP is up.
  network_label=""
  network_color="#fb4934"
  if [ -z "$default_iface" ] && ! ipconfig getifaddr en0 >/dev/null 2>&1; then
    network_label="󰖪 offline"
  fi

  local iface="${default_iface:-en0}"
  local cache_file="/tmp/tmux_net_cache_${iface}"
  local now_s
  now_s="$(date +%s)"

  net="$(
    netstat -ib 2>/dev/null | awk -v iface="$iface" -v cache="$cache_file" -v now="$now_s" '
      $1 == iface && $3 ~ /^<Link#/ {
        if (NF >= 11) {
          rx2 = $7 + 0
          tx2 = $10 + 0
        } else {
          rx2 = $6 + 0
          tx2 = $9 + 0
        }
        found = 1
        exit
      }
      END {
        if (!found) {
          rx2 = 0
          tx2 = 0
        }
        if ((getline line < cache) > 0) {
          close(cache)
          split(line, parts, " ")
          rx1 = parts[1] + 0
          tx1 = parts[2] + 0
          t1 = parts[3] + 0
          dt = now - t1
          if (dt < 1) dt = 1
          rx_kb = (rx2 > rx1 ? rx2 - rx1 : 0) / dt / 1024
          tx_kb = (tx2 > tx1 ? tx2 - tx1 : 0) / dt / 1024
          rx_str = (rx_kb >= 1024) ? sprintf("%.1fMiB/s", rx_kb / 1024) : sprintf("%.0fKiB/s", rx_kb)
          tx_str = (tx_kb >= 1024) ? sprintf("%.1fMiB/s", tx_kb / 1024) : sprintf("%.0fKiB/s", tx_kb)
          printf "↓%s ↑%s\n", rx_str, tx_str
        } else {
          print "..."
        }
        printf "%d %d %d\n", rx2, tx2, now > cache
        close(cache)
      }
    ' 2>/dev/null || echo "n/a"
  )"
}
