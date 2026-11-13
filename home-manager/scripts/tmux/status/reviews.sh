#!/usr/bin/env bash

tmux_status_collect_reviews() {
  reviews_status=""
  reviews_bg="#504945"
  reviews_fg="#fabd2f"

  local cache_dir="${TMPDIR:-/tmp}"
  local cache_file="${cache_dir}/tmux_gh_reviews_${UID:-0}.cache"
  local json_cache="${cache_dir}/tmux_gh_reviews_data_${UID:-0}.json"
  local lock_file="${cache_dir}/tmux_gh_reviews_${UID:-0}.lock"
  local now_s
  now_s="$(date +%s 2>/dev/null || echo 0)"

  # Refresh cache in background if missing or older than 180 seconds (3 mins)
  if ! tmux_status_cache_fresh "$cache_file" 180 "$now_s"; then
    if ! tmux_status_cache_fresh "$lock_file" 60 "$now_s"; then
      touch "$lock_file" 2>/dev/null || true
      (
        raw="$(tmux_status_fetch_gh_reviews_json || true)"
        if [ -n "$raw" ]; then
          printf '%s\n' "$raw" > "$json_cache" 2>/dev/null || true
          formatted="$(
            printf '%s' "$raw" | jq -r '
              .data.viewer.login as $me |
              [.data.search.nodes[]? |
                select(.title | test("^(build|chore)\\(deps.*\\):") | not) |
                select(.reviewRequests.nodes[]?.requestedReviewer | (.__typename == "User" and .login == $me))
              ] as $prs |
              ($prs | length) as $len |
              if $len == 0 then
                ""
              elif $len <= 2 then
                " " + ($prs | map("\(.repository.name)#\(.number)") | join(", "))
              else
                " " + ($prs[0:2] | map("\(.repository.name)#\(.number)") | join(", ")) + " (+" + (($len - 2) | tostring) + ")"
              end
            ' 2>/dev/null || true
          )"
          printf '%s\n' "$formatted" > "$cache_file" 2>/dev/null || true
        fi
        rm -f "$lock_file" 2>/dev/null || true
      ) </dev/null >/dev/null 2>&1 &
    fi
  fi

  # Read cached review string if available
  if [ -r "$cache_file" ]; then
    local cached
    cached="$(head -n 1 "$cache_file" 2>/dev/null || true)"
    if [ -n "$cached" ]; then
      reviews_status="$cached"
      reviews_bg="#504945"
      reviews_fg="#fabd2f"
    fi
  fi
}
