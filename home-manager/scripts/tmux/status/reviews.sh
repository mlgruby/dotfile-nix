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
          raw="$(gh search prs --review-requested=@me --state=open --json number,title 2>/dev/null || true)"
          if [ -n "$raw" ]; then
            count="$(
              printf '%s' "$raw" | jq -r '
                [.[] | select(.title | test("^(build|chore)\\(deps.*\\):") | not)] | length
              ' 2>/dev/null || echo 0
            )"
            printf '%s\n' "$count" > "$cache_file" 2>/dev/null || true
          fi
        fi
        rm -f "$lock_file" 2>/dev/null || true
      ) &
    fi
  fi

  # Read cached review count if available
  if [ -r "$cache_file" ]; then
    local cached
    cached="$(head -n 1 "$cache_file" 2>/dev/null || true)"
    if [ -n "$cached" ] && [ "$cached" -gt 0 ] 2>/dev/null; then
      local plural="s"
      [ "$cached" -eq 1 ] && plural=""
      reviews_status=" ${cached} review${plural}"
      reviews_bg="#504945"
      reviews_fg="#fabd2f"
    fi
  fi
}
