#!/usr/bin/env bash
# review-popup.sh - Interactive tmux popup to view and open pending GitHub PR review requests
set -euo pipefail

cache_dir="${TMPDIR:-/tmp}"
json_cache="${cache_dir}/tmux_gh_reviews_data_${UID:-0}.json"

fetch_reviews() {
  if command -v gh >/dev/null 2>&1; then
    gh api graphql -f query='
query {
  viewer {
    login
  }
  search(query: "is:pr is:open review-requested:@me", type: ISSUE, first: 30) {
    nodes {
      ... on PullRequest {
        number
        title
        url
        repository {
          name
        }
        reviewRequests(first: 10) {
          nodes {
            requestedReviewer {
              __typename
              ... on User {
                login
              }
              ... on Team {
                name
                slug
              }
            }
          }
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
  raw="$(fetch_reviews)"
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

if command -v fzf >/dev/null 2>&1; then
  selected="$(
    printf '%s\n' "$lines" | fzf \
      --delimiter=$'\t' \
      --with-nth=1,2 \
      --preview='printf "\033[1;33mReview Target:\033[0m %s\n\033[1;36mTitle:\033[0m %s\n\033[1;32mURL:\033[0m %s\n" {1} {2} {3}' \
      --preview-window=down:4:wrap \
      --header="PR Reviews | [direct] = requested you | [team] = requested your team | Enter: Open in browser" \
      --prompt="Review PR > "
  )" || true

  if [ -n "$selected" ]; then
    url="$(printf '%s' "$selected" | awk -F'\t' '{print $3}')"
    if [ -n "$url" ]; then
      open "$url" 2>/dev/null || xdg-open "$url" 2>/dev/null || true
    fi
  fi
else
  echo "Pending PR Reviews:"
  printf '%s\n' "$lines" | while IFS=$'\t' read -r pr title url; do
    echo "  • $pr: $title"
    echo "    $url"
  done
  echo ""
  read -r -p "Press Enter to close..."
fi
