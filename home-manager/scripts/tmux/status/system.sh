#!/usr/bin/env bash

tmux_status_collect_system() {
  local disk_cache="${TMPDIR:-/tmp}/tmux_disk_${UID:-0}.cache"
  if declare -F tmux_status_cache_fresh >/dev/null 2>&1 && tmux_status_cache_fresh "$disk_cache" 30; then
    IFS= read -r disk < "$disk_cache" 2>/dev/null || true
  else
    disk="$(
      df -h /System/Volumes/Data / 2>/dev/null \
        | awk 'NR==2{print $5 " " $3 "/" $2; exit}' \
        || echo "n/a"
    )"
    [ -n "$disk" ] || disk="n/a"
    printf '%s\n' "$disk" > "$disk_cache" 2>/dev/null || true
  fi
  disk_color="#b8bb26"
  disk_value="${disk%%% *}"
  if [ "$disk_value" -ge 90 ] 2>/dev/null; then
    disk_color="#fb4934"
  elif [ "$disk_value" -ge 75 ] 2>/dev/null; then
    disk_color="#fabd2f"
  fi
  # Percent is enough until space is critical; then show the capacity needed
  # to judge how much data must be removed.
  if [ "$disk_value" -lt 90 ] 2>/dev/null; then
    disk="${disk_value}%"
  fi

  hw_cache="${TMPDIR:-/tmp}/tmux_hw_$(id -u 2>/dev/null || echo 0).cache"
  logical_cpus=""
  mem_total_gb=""
  if [ -r "$hw_cache" ]; then
    read -r logical_cpus mem_total_gb < "$hw_cache" 2>/dev/null || true
  fi
  if [ -z "$logical_cpus" ] || [ -z "$mem_total_gb" ]; then
    logical_cpus="$(sysctl -n hw.logicalcpu 2>/dev/null || echo 1)"
    mem_total_gb="$(
      sysctl -n hw.memsize 2>/dev/null \
        | awk '{ if ($1 > 0) printf "%.0f", $1 / 1024 / 1024 / 1024 }' \
        || true
    )"
    [ -n "$mem_total_gb" ] || mem_total_gb="16"
    printf "%s %s\n" "$logical_cpus" "$mem_total_gb" > "$hw_cache" 2>/dev/null || true
  fi
  load_avg="$(sysctl -n vm.loadavg 2>/dev/null | awk '{ print $2 }' || true)"

  # Avoid `top -l 1` on macOS, which sleeps internally and takes ~1.5s per call.
  # Summing per-process `%cpu` from `ps` and normalizing by logical CPU count
  # takes ~20ms (60x faster) and yields the exact same 0-100% CPU utilization.
  cpu="$(
    ps -A -o %cpu= 2>/dev/null \
      | awk -v cpus="$logical_cpus" '
          { sum += $1 }
          END {
            if (cpus <= 0) cpus = 1
            pct = sum / cpus
            if (pct > 100) pct = 100
            printf "%.0f%%", pct
          }
        ' \
      || true
  )"
  [ -n "$cpu" ] || cpu="n/a"

  cpu_status=" $cpu"
  # macOS keeps spare RAM busy as cache. Its own free-memory percentage is a
  # more useful signal than summing active and inactive VM pages.
  mem_free_percent="$(
    memory_pressure -Q 2>/dev/null \
      | awk -F': ' '/System-wide memory free percentage/ { gsub(/%/, "", $2); print $2; exit }' \
      || true
  )"
  mem_used_percent=""
  mem_used_gb=""
  if [[ "$mem_free_percent" =~ ^[0-9]+$ ]] && [ -n "$mem_total_gb" ]; then
    mem_used_percent=$(( 100 - mem_free_percent ))
    mem_used_gb="$(awk -v total="$mem_total_gb" -v used="$mem_used_percent" 'BEGIN { printf "%.0f", total * used / 100 }')"
    mem="${mem_used_percent}%"
    if [ "$mem_used_percent" -ge 90 ]; then
      mem="${mem} ${mem_used_gb}G/${mem_total_gb}G"
    fi
  else
    mem="n/a"
  fi
  mem_color="#b8bb26"
  if [ "$mem_used_percent" -ge 90 ] 2>/dev/null; then
    mem_color="#fb4934"
  elif [ "$mem_used_percent" -ge 75 ] 2>/dev/null; then
    mem_color="#fabd2f"
  fi

  local batt_cache="${TMPDIR:-/tmp}/tmux_batt_${UID:-0}.cache"
  if declare -F tmux_status_cache_fresh >/dev/null 2>&1 && tmux_status_cache_fresh "$batt_cache" 30; then
    IFS= read -r batt_raw < "$batt_cache" 2>/dev/null || true
  else
    batt_raw="$(
      pmset -g batt 2>/dev/null | awk '
        /AC Power/ { ac=1 }
        /%/ {
          pct = $0
          sub(/^.*\t/, "", pct)
          sub(/;.*/, "", pct)
          gsub(/^ +| +$/, "", pct)
          if (ac && /charged|charging/ && !/dischar/) chg="yes"; else chg="no"
          printf "%s\t%s\n", (pct ? pct : "n/a"), chg
          found=1
          exit
        }
        END { if (!found) print "n/a\tno" }
      ' 2>/dev/null || printf '%s\t%s\n' "n/a" "no"
    )"
    printf '%s\n' "$batt_raw" > "$batt_cache" 2>/dev/null || true
  fi
  battery="${batt_raw%%	*}"
  battery_charging="${batt_raw##*	}"
  [ -n "$battery" ] || battery="n/a"

  cpu_color="#b8bb26"
  cpu_value="${cpu%%%}"
  if [ "$cpu_value" != "$cpu" ] && [ "$cpu_value" -ge 80 ] 2>/dev/null; then
    cpu_color="#fb4934"
  elif [ "$cpu_value" != "$cpu" ] && [ "$cpu_value" -ge 50 ] 2>/dev/null; then
    cpu_color="#fabd2f"
  fi

  if [ -n "$load_avg" ] && [ "$logical_cpus" -gt 0 ] 2>/dev/null; then
    load_pressure="$(
      awk -v ld_val="$load_avg" -v cpus="$logical_cpus" 'BEGIN { printf "%.0f", (ld_val / cpus) * 100 }' 2>/dev/null \
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
