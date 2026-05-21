#!/usr/bin/env bash

tmux_status_collect_system() {
  disk="$(
    df -h /System/Volumes/Data / 2>/dev/null \
      | awk 'NR==2{print $5 " " $3 "/" $2; exit}' \
      || echo "n/a"
  )"
  [ -n "$disk" ] || disk="n/a"
  disk_color="#b8bb26"
  disk_value="${disk%%% *}"
  if [ "$disk_value" -ge 90 ] 2>/dev/null; then
    disk_color="#fb4934"
  elif [ "$disk_value" -ge 75 ] 2>/dev/null; then
    disk_color="#fabd2f"
  fi

  k8s_status="$(
    if command -v kubectl >/dev/null 2>&1; then
      context="$(kubectl config current-context 2>/dev/null || true)"
      namespace="$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null || true)"
      [ -n "$namespace" ] || namespace="default"
      [ -n "$context" ] && printf '󱃾 %s/%s' "$context" "$namespace"
    fi
  )"

  nix_generation="$(
    readlink /nix/var/nix/profiles/system 2>/dev/null \
      | sed -n 's/^system-\([0-9][0-9]*\)-link$/\1/p' \
      || true
  )"
  nix_status=""
  [ -n "$nix_generation" ] && nix_status=" $nix_generation"

  load_avg="$(uptime 2>/dev/null | awk -F'load averages?: ' '{ print $2 }' | awk '{ gsub(",", "", $1); print $1; exit }' || true)"
  cpu="$(
    top -l 1 2>/dev/null \
      | awk -F'[:,%]' '/CPU usage/ { gsub(/^ +| +$/, "", $2); gsub(/^ +| +$/, "", $4); printf "%.0f%%", $2 + $4; exit }' \
      || true
  )"
  [ -n "$cpu" ] || cpu="n/a"

  cpu_status=" $cpu"
  [ -n "$load_avg" ] && cpu_status="$cpu_status · 󰓅 $load_avg"

  mem="$(
    vm_stat 2>/dev/null | awk '
      /page size of/ { pageSize = $8 }
      /Pages active/ { active = $3 }
      /Pages inactive/ { inactive = $3 }
      /Pages speculative/ { speculative = $3 }
      /Pages wired down/ { wired = $4 }
      END {
        gsub(/\./, "", active);
        gsub(/\./, "", inactive);
        gsub(/\./, "", speculative);
        gsub(/\./, "", wired);
        used = (active + inactive + speculative + wired) * pageSize / 1024 / 1024 / 1024;
        if (used > 0) {
          printf "%.1fG", used;
        }
      }
    ' \
    || true
  )"
  [ -n "$mem" ] || mem="n/a"
  mem_color="#ebdbb2"
  mem_pressure="$(
    vm_stat 2>/dev/null | awk '
      /page size of/ { pageSize = $8 }
      /Pages active/ { active = $3 }
      /Pages inactive/ { inactive = $3 }
      /Pages speculative/ { speculative = $3 }
      /Pages wired down/ { wired = $4 }
      /Pages free/ { free = $3 }
      /Pages purgeable/ { purgeable = $3 }
      /Pages compressed/ { compressed = $3 }
      END {
        gsub(/\./, "", active);
        gsub(/\./, "", inactive);
        gsub(/\./, "", speculative);
        gsub(/\./, "", wired);
        gsub(/\./, "", free);
        gsub(/\./, "", purgeable);
        gsub(/\./, "", compressed);
        used = active + inactive + speculative + wired + compressed;
        total = used + free + purgeable;
        if (total > 0) printf "%.0f", (used / total) * 100;
      }
    ' \
    || true
  )"
  if [ "$mem_pressure" -ge 90 ] 2>/dev/null; then
    mem_color="#fb4934"
  elif [ "$mem_pressure" -ge 75 ] 2>/dev/null; then
    mem_color="#fabd2f"
  fi

  battery="$(
    pmset -g batt 2>/dev/null \
      | awk -F';' '/%/ { gsub(/^ +| +$/, "", $1); sub(/^.*\t/, "", $1); print $1; exit }' \
      || true
  )"
  [ -n "$battery" ] || battery="n/a"

  battery_charging="$(
    pmset -g batt 2>/dev/null \
      | awk '/AC Power/ { ac=1 } /charged|charging/ { if (ac && !/dischar/) print "yes"; exit }' \
      || true
  )"

  cpu_color="#b8bb26"
  cpu_value="${cpu%%%}"
  if [ "$cpu_value" != "$cpu" ] && [ "$cpu_value" -ge 80 ] 2>/dev/null; then
    cpu_color="#fb4934"
  elif [ "$cpu_value" != "$cpu" ] && [ "$cpu_value" -ge 50 ] 2>/dev/null; then
    cpu_color="#fabd2f"
  fi

  logical_cpus="$(sysctl -n hw.logicalcpu 2>/dev/null || echo 0)"
  if [ -n "$load_avg" ] && [ "$logical_cpus" -gt 0 ] 2>/dev/null; then
    load_pressure="$(
      awk -v load="$load_avg" -v cpus="$logical_cpus" 'BEGIN { printf "%.0f", (load / cpus) * 100 }' \
        || echo 0
    )"
    if [ "$load_pressure" -ge 100 ] 2>/dev/null; then
      cpu_color="#fb4934"
    elif [ "$load_pressure" -ge 70 ] 2>/dev/null && [ "$cpu_color" = "#b8bb26" ]; then
      cpu_color="#fabd2f"
    fi
  fi

  battery_color="#b8bb26"
  battery_value="${battery%%%}"
  if [ "$battery_value" != "$battery" ] && [ "$battery_value" -le 20 ] 2>/dev/null; then
    battery_color="#fb4934"
  elif [ "$battery_value" != "$battery" ] && [ "$battery_value" -le 50 ] 2>/dev/null; then
    battery_color="#fabd2f"
  fi

  if [ "$battery_charging" = "yes" ]; then
    batt_icon="󰂄"
  else
    batt_icon="󰁹"
  fi

  datetime="$(date "+%d-%b-%Y %H:%M" | tr '[:lower:]' '[:upper:]')"
}
