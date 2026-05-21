#!/usr/bin/env bash

tmux_status_collect_network() {
  default_iface="$(route -n get default 2>/dev/null | awk '/interface:/ { print $2; exit }' || true)"

  wifi_active="no"
  lan_active="no"
  for iface in $(ifconfig -l 2>/dev/null); do
    case "$iface" in
      en0)
        if ipconfig getifaddr "$iface" >/dev/null 2>&1; then
          wifi_active="yes"
        fi
        ;;
      en*)
        if ipconfig getifaddr "$iface" >/dev/null 2>&1; then
          lan_active="yes"
        fi
        ;;
    esac
  done

  if [ "$wifi_active" = "yes" ] && [ "$lan_active" = "yes" ]; then
    if [ "$default_iface" = "en0" ]; then
      network_label="󰖩 wifi · 󰈀 lan"
    else
      network_label="󰈀 lan · 󰖩 wifi"
    fi
    network_color="#8ec07c"
  elif [ "$lan_active" = "yes" ]; then
    network_label="󰈀 lan"
    network_color="#83a598"
  elif [ "$wifi_active" = "yes" ]; then
    network_label="󰖩 wifi"
    network_color="#8ec07c"
  else
    network_label="󰖪 offline"
    network_color="#928374"
  fi

  net="$(DEFAULT_IFACE="$default_iface" python3 -c "
import os, subprocess, time

iface=os.environ.get('DEFAULT_IFACE') or 'en0'
cache=f'/tmp/tmux_net_cache_{iface}'
def get_bytes():
    out = subprocess.run(['netstat','-ib'], capture_output=True, text=True).stdout
    for line in out.split('\n'):
        if line.startswith(iface) and '<Link#' in line:
            parts = line.split()
            try: return int(parts[6]), int(parts[9]), time.time()
            except: pass
    return 0, 0, time.time()

rx2, tx2, t2 = get_bytes()
try:
    with open(cache) as f:
        parts = f.read().split()
        rx1, tx1, t1 = int(parts[0]), int(parts[1]), float(parts[2])
    dt = max(t2 - t1, 1)
    rx_kb = max(rx2 - rx1, 0) / dt / 1024
    tx_kb = max(tx2 - tx1, 0) / dt / 1024
    def fmt(k):
        return f'{k/1024:.1f}MiB/s' if k >= 1024 else f'{k:.0f}KiB/s'
    result = f'↓{fmt(rx_kb)} ↑{fmt(tx_kb)}'
except:
    result = '...'
with open(cache, 'w') as f:
    f.write(f'{rx2} {tx2} {t2}')
print(result)
" 2>/dev/null || echo "n/a")"
}
