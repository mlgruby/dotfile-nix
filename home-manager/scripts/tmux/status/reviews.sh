#!/usr/bin/env bash

_tmux_reviews_mtime() {
  local target="$1"
  /usr/bin/stat -f %m "$target" 2>/dev/null || stat -c %Y "$target" 2>/dev/null || stat -f %m "$target" 2>/dev/null || echo 0
}

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

  local cache_mtime=0
  if [ -f "$cache_file" ]; then
    cache_mtime="$(_tmux_reviews_mtime "$cache_file")"
  fi

  local cache_age=$(( now_s - cache_mtime ))

  # Refresh cache in background if missing or older than 180 seconds (3 mins)
  if [ "$cache_age" -ge 180 ] || [ ! -f "$cache_file" ]; then
    local lock_mtime=0
    if [ -f "$lock_file" ]; then
      lock_mtime="$(_tmux_reviews_mtime "$lock_file")"
    fi
    local lock_age=$(( now_s - lock_mtime ))

    if [ ! -f "$lock_file" ] || [ "$lock_age" -ge 60 ]; then
      touch "$lock_file" 2>/dev/null || true
      (
        if command -v gh >/dev/null 2>&1; then
          raw="$(gh search prs --review-requested=@me --state=open --json number,title,repository,url 2>/dev/null || true)"
          if [ -n "$raw" ]; then
            printf '%s\n' "$raw" > "$json_cache" 2>/dev/null || true
            formatted="$(
              printf '%s' "$raw" | jq -r '
                [.[] | select(.title | test("^(build|chore)\\(deps.*\\):") | not)] as $prs |
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
