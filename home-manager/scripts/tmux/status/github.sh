#!/usr/bin/env bash

tmux_status_collect_github() {
  github_status=""
  github_bg="#fabd2f"
  github_fg="#1d2021"

  local cache_dir="${TMPDIR:-/tmp}"
  local cache_file="${cache_dir}/tmux_github_status_${UID:-0}.cache"
  local lock_file="${cache_dir}/tmux_github_status_${UID:-0}.lock"
  local now_s
  now_s="$(date +%s 2>/dev/null || echo 0)"

  # Refresh cache in background if missing or older than 180 seconds (3 mins)
  if ! tmux_status_cache_fresh "$cache_file" 180 "$now_s"; then
    # Only spawn if no lock exists or previous lock is stale (> 60s)
    if ! tmux_status_cache_fresh "$lock_file" 60 "$now_s"; then
      touch "$lock_file" 2>/dev/null || true
      (
        raw="$(curl -fsSL --connect-timeout 2 --max-time 4 "https://www.githubstatus.com/api/v2/summary.json" 2>/dev/null || true)"
        if [ -n "$raw" ]; then
          parsed="$(
            printf '%s' "$raw" | jq -r '
              .status.indicator as $ind |
              if $ind == "none" then
                "none|"
              else
                ([.components[] | select(.status != "operational" and .group != true) | .name] | join(", ")) as $degraded |
                if ($degraded | length) > 0 and ($degraded | length) < 30 then
                  "\($ind)|\($degraded)"
                else
                  "\($ind)|\(.status.description)"
                end
              end
            ' 2>/dev/null || true
          )"
          if [ -n "$parsed" ]; then
            printf '%s\n' "$parsed" > "$cache_file" 2>/dev/null || true
          fi
        fi
        rm -f "$lock_file" 2>/dev/null || true
      ) &
    fi
  fi

  # Read cached status if available
  if [ -r "$cache_file" ]; then
    local cached
    cached="$(head -n 1 "$cache_file" 2>/dev/null || true)"
    if [ -n "$cached" ]; then
      local indicator="${cached%%|*}"
      local detail="${cached#*|}"
      case "$indicator" in
        minor)
          github_bg="#fabd2f"
          github_fg="#1d2021"
          github_status=" GH: ${detail}"
          ;;
        major|critical)
          github_bg="#fb4934"
          github_fg="#ffffff"
          github_status=" GH: ${detail}"
          ;;
        maintenance)
          github_bg="#83a598"
          github_fg="#1d2021"
          github_status=" GH: ${detail}"
          ;;
        *)
          github_status=""
          ;;
      esac
    fi
  fi
}
