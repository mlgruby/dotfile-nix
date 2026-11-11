#!/usr/bin/env bash
# my-prs.sh - Collect CI failure alerts for your own open pull requests

_tmux_my_prs_mtime() {
  local target="$1"
  /usr/bin/stat -f %m "$target" 2>/dev/null || stat -c %Y "$target" 2>/dev/null || echo 0
}

tmux_status_collect_my_prs() {
  my_prs_status=""
  my_prs_bg="#fb4934"
  my_prs_fg="#1d2021"

  local cache_dir="${TMPDIR:-/tmp}"
  local cache_file="${cache_dir}/tmux_my_prs_${UID:-0}.cache"
  local json_cache="${cache_dir}/tmux_my_prs_data_${UID:-0}.json"
  local lock_file="${cache_dir}/tmux_my_prs_${UID:-0}.lock"
  local now_s
  now_s="$(date +%s 2>/dev/null || echo 0)"

  local cache_mtime=0
  if [ -f "$cache_file" ]; then
    cache_mtime="$(_tmux_my_prs_mtime "$cache_file")"
  fi

  local cache_age=$(( now_s - cache_mtime ))

  # Refresh cache in background if missing or older than 180 seconds (3 mins)
  if [ "$cache_age" -ge 180 ] || [ ! -f "$cache_file" ]; then
    local lock_mtime=0
    if [ -f "$lock_file" ]; then
      lock_mtime="$(_tmux_my_prs_mtime "$lock_file")"
    fi
    local lock_age=$(( now_s - lock_mtime ))

    if [ ! -f "$lock_file" ] || [ "$lock_age" -ge 60 ]; then
      touch "$lock_file" 2>/dev/null || true
      (
        if command -v gh >/dev/null 2>&1; then
          raw="$(gh api graphql -f query='
query {
  viewer {
    pullRequests(first: 10, states: [OPEN], orderBy: {field: UPDATED_AT, direction: DESC}) {
      nodes {
        number
        title
        url
        repository { name }
        commits(last: 1) {
          nodes {
            commit {
              statusCheckRollup {
                state
              }
            }
          }
        }
        reviewDecision
      }
    }
  }
}
' 2>/dev/null || true)"
          if [ -n "$raw" ]; then
            printf '%s\n' "$raw" > "$json_cache" 2>/dev/null || true
            formatted="$(
              printf '%s' "$raw" | jq -r '
                [.data.viewer.pullRequests.nodes[]? |
                  select(.commits.nodes[0]?.commit?.statusCheckRollup?.state == "FAILURE")
                ] as $failed |
                ($failed | length) as $len |
                if $len == 0 then
                  ""
                elif $len <= 2 then
                  " " + ($failed | map("\(.repository.name)#\(.number)") | join(", ")) + " CI failed"
                else
                  " " + ($failed[0:2] | map("\(.repository.name)#\(.number)") | join(", ")) + " (+" + (($len - 2) | tostring) + ") CI failed"
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

  # Read cached string if available
  if [ -r "$cache_file" ]; then
    local cached
    cached="$(head -n 1 "$cache_file" 2>/dev/null || true)"
    if [ -n "$cached" ]; then
      my_prs_status="$cached"
      my_prs_bg="#fb4934"
      my_prs_fg="#1d2021"
    fi
  fi
}
