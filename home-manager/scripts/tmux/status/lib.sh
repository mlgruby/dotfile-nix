#!/usr/bin/env bash

tmux_status_mtime() {
  local target="$1"
  /usr/bin/stat -f %m "$target" 2>/dev/null || stat -c %Y "$target" 2>/dev/null || echo 0
}

tmux_status_cache_fresh() {
  local target="$1"
  local ttl="$2"
  local now_s="${3:-$(date +%s 2>/dev/null || echo 0)}"
  [ -r "$target" ] || return 1
  local mtime
  mtime="$(tmux_status_mtime "$target")"
  [ $(( now_s - mtime )) -lt "$ttl" ]
}

tmux_status_alt_bg() {
  local bg="$1"
  local prev_bg="$2"
  if [ "$bg" = "$prev_bg" ]; then
    case "$bg" in
      "#3c3836") bg="#504945" ;;
      "#504945") bg="#3c3836" ;;
      "#fb4934") bg="#cc241d" ;;
      "#cc241d") bg="#fb4934" ;;
      "#fabd2f") bg="#d79921" ;;
      "#d79921") bg="#fabd2f" ;;
    esac
  fi
  printf '%s' "$bg"
}

segment() {
  local bg="$1"
  local fg="$2"
  local prev_bg="$3"
  local text="$4"
  printf '#[fg=%s,bg=%s,nobold,nounderscore,noitalics]#[fg=%s,bg=%s] %s ' "$bg" "$prev_bg" "$fg" "$bg" "$text"
}

append_segment() {
  local bg="$1"
  local fg="$2"
  local text="$3"

  [ -n "$text" ] || return 0

  bg="$(tmux_status_alt_bg "$bg" "$status_prev_bg")"
  status_output+=$(segment "$bg" "$fg" "$status_prev_bg" "$text")
  status_prev_bg="$bg"
}

tmux_status_fetch_gh_reviews_json() {
  command -v gh >/dev/null 2>&1 || return 1
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
}
' 2>/dev/null
}

tmux_status_fzf_open_url() {
  local lines="$1"
  local preview_fmt="$2"
  local header="$3"
  local prompt="$4"
  local fallback_title="$5"

  if command -v fzf >/dev/null 2>&1; then
    local selected url
    selected="$(
      printf '%s\n' "$lines" | fzf \
        --delimiter=$'\t' \
        --with-nth=1,2 \
        --preview="$preview_fmt" \
        --preview-window=down:4:wrap \
        --header="$header" \
        --prompt="$prompt"
    )" || true

    if [ -n "$selected" ]; then
      url="$(printf '%s' "$selected" | awk -F'\t' '{print $3}')"
      if [ -n "$url" ]; then
        open "$url" 2>/dev/null || xdg-open "$url" 2>/dev/null || true
      fi
    fi
  else
    echo "$fallback_title"
    printf '%s\n' "$lines" | while IFS=$'\t' read -r item title url; do
      echo "  • $item: $title"
      echo "    $url"
    done
    echo ""
    read -r -p "Press Enter to close..."
  fi
}
