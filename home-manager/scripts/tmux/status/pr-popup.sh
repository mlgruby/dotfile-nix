#!/usr/bin/env bash
# pr-popup.sh - Interactive tmux popup to view and open your own GitHub PRs with live CI status
set -euo pipefail

cache_dir="${TMPDIR:-/tmp}"
json_cache="${cache_dir}/tmux_my_prs_data_${UID:-0}.json"

fetch_prs() {
  if command -v gh >/dev/null 2>&1; then
    gh api graphql -f query='
query {
  viewer {
    pullRequests(first: 15, states: [OPEN], orderBy: {field: UPDATED_AT, direction: DESC}) {
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
' 2>/dev/null || echo "{}"
  else
    echo "{}"
  fi
}

now_s="$(date +%s 2>/dev/null || echo 0)"
cache_mtime=0
if [ -f "$json_cache" ]; then
  cache_mtime="$(/usr/bin/stat -f %m "$json_cache" 2>/dev/null || stat -c %Y "$json_cache" 2>/dev/null || echo 0)"
fi
cache_age=$(( now_s - cache_mtime ))

if [ ! -s "$json_cache" ] || [ "$cache_age" -ge 180 ]; then
  raw="$(fetch_prs)"
  if [ -n "$raw" ] && [ "$raw" != "{}" ]; then
    printf '%s\n' "$raw" > "$json_cache" 2>/dev/null || true
  fi
fi

if [ ! -s "$json_cache" ]; then
  echo ""
  echo "  Could not retrieve open pull requests."
  echo "  Ensure 'gh auth status' is active."
  echo ""
  read -r -p "  Press Enter to close..."
  exit 0
fi

lines="$(
  jq -r '
    .data.viewer.pullRequests.nodes[]? |
    (
      (.commits.nodes[0]?.commit?.statusCheckRollup?.state // "NO_CHECKS") as $ci |
      (if $ci == "SUCCESS" then "✓ PASS" elif $ci == "FAILURE" then " FAIL" elif $ci == "PENDING" then "󰑮 PEND" else "• NONE" end) as $ci_icon |
      (.reviewDecision // "NO_REVIEW") as $rev |
      "[\($ci_icon)] \(.repository.name)#\(.number)\t\(.title) (\($rev))\t\(.url)"
    )
  ' "$json_cache" 2>/dev/null || true
)"

if [ -z "$lines" ]; then
  echo ""
  echo "  ✓ No open pull requests found."
  echo ""
  read -r -p "  Press Enter to close..."
  exit 0
fi

if command -v fzf >/dev/null 2>&1; then
  selected="$(
    printf '%s\n' "$lines" | fzf \
      --delimiter=$'\t' \
      --with-nth=1,2 \
      --preview='printf "\033[1;33mPR / Status:\033[0m %s\n\033[1;36mTitle & Review:\033[0m %s\n\033[1;32mURL:\033[0m %s\n" {1} {2} {3}' \
      --preview-window=down:4:wrap \
      --header="Your Open PRs | Enter: Open in browser | Esc: Close" \
      --prompt="Select PR > "
  )" || true

  if [ -n "$selected" ]; then
    url="$(printf '%s' "$selected" | awk -F'\t' '{print $3}')"
    if [ -n "$url" ]; then
      open "$url" 2>/dev/null || xdg-open "$url" 2>/dev/null || true
    fi
  fi
else
  echo "Your Open Pull Requests:"
  printf '%s\n' "$lines" | while IFS=$'\t' read -r pr title url; do
    echo "  • $pr: $title"
    echo "    $url"
  done
  echo ""
  read -r -p "Press Enter to close..."
fi
