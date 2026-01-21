#!/usr/bin/env bash
# git-fuzzy-stash.sh - Interactive stash browser and applicator
#
# Usage: git-fuzzy-stash.sh
#
# Description:
#   Browse git stashes with fzf, preview their contents, and apply selected stash.

set -euo pipefail

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not a git repository" >&2
    exit 1
fi

# Check if fzf is available
if ! command -v fzf &> /dev/null; then
    echo "Error: fzf is required but not installed" >&2
    exit 1
fi

# Check if there are any stashes
if ! git stash list &> /dev/null || [ -z "$(git stash list)" ]; then
    echo "No stashes found"
    exit 0
fi

# Select and apply stash
selected_stash=$(git stash list | \
    fzf --preview 'echo {} | cut -d: -f1 | xargs -I % sh -c "git stash show --color=always %"' \
        --preview-window=right:60% \
        --prompt="Select stash: " \
        --header="Select a stash to apply" \
        --height=80% | \
    cut -d: -f1)

# If a stash was selected, apply it
if [ -n "$selected_stash" ]; then
    echo "Applying stash: $selected_stash"
    git stash apply "$selected_stash"
else
    echo "No stash selected"
    exit 0
fi
