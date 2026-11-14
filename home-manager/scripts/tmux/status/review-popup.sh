#!/usr/bin/env bash
# review-popup.sh - Interactive tmux popup to view and open pending GitHub PR review requests
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lib.sh"

cache_dir="${TMPDIR:-/tmp}"
json_cache="${cache_dir}/tmux_gh_reviews_data_${UID:-0}.json"

if [ ! -s "$json_cache" ] || ! tmux_status_cache_fresh "$json_cache" 180; then
  raw="$(tmux_status_fetch_gh_reviews_json || echo "{}")"
  if [ -n "$raw" ] && [ "$raw" != "{}" ]; then
    printf '%s\n' "$raw" > "$json_cache" 2>/dev/null || true
  fi
fi

if [ ! -s "$json_cache" ]; then
  echo ""
  echo "  Could not retrieve GitHub PR reviews."
  echo "  Ensure 'gh auth status' is active."
  echo ""
  read -r -p "  Press Enter to close..."
  exit 0
fi

# Filter out automated bot bumps, sort direct reviews first, then team reviews
lines="$(
  jq -r '
    .data.viewer.login as $me |
    [.data.search.nodes[]? |
      select(.title | test("^(build|chore)\\(deps.*\\):") | not) |
      (
        if ([.reviewRequests.nodes[]?.requestedReviewer | select(.__typename == "User" and .login == $me)] | length) > 0 then
          "[direct] \(.repository.name)#\(.number)\t\(.title)\t\(.url)"
        else
          "[team] \(.repository.name)#\(.number)\t\(.title)\t\(.url)"
        end
      )
    ] |
    sort_by(startswith("[direct]") | not) |
    if length == 0 then
      empty
    else
      .[]
    end
  ' "$json_cache" 2>/dev/null || true
)"

if [ -z "$lines" ]; then
  echo ""
  echo "  ✓ No pending human PR reviews waiting for you or your teams!"
  echo ""
  read -r -p "  Press Enter to close..."
  exit 0
fi

tmux_status_fzf_open_url \
  "$lines" \
  'printf "\033[1;33mReview Target:\033[0m %s\n\033[1;36mTitle:\033[0m %s\n\033[1;32mURL:\033[0m %s\n" {1} {2} {3}' \
  "PR Reviews | [direct] = requested you | [team] = requested your team | Enter: Open in browser" \
  "Review PR > " \
  "Pending PR Reviews:"
