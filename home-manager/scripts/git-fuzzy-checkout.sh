#!/usr/bin/env bash
# git-fuzzy-checkout.sh - Interactive branch checkout with commit preview
#
# Usage: git-fuzzy-checkout.sh
#
# Description:
#   Lists all git branches and uses fzf to interactively select and checkout a branch.
#   Shows a preview of recent commits for each branch.

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

# List all branches, filter out HEAD, and use fzf for selection
selected_branch=$(git branch --all | \
    grep -v HEAD | \
    fzf --preview 'git log --oneline --graph --date=short --color=always --pretty="%C(auto)%cd %h%d %s" {1}' \
        --preview-window=right:60% \
        --prompt="Select branch: " \
        --header="Select a branch to checkout" \
        --height=80% | \
    sed 's/.* //' | \
    sed 's#remotes/[^/]*/##')

# If a branch was selected, check it out
if [ -n "$selected_branch" ]; then
    echo "Checking out: $selected_branch"
    git checkout "$selected_branch"
else
    echo "No branch selected"
    exit 0
fi
