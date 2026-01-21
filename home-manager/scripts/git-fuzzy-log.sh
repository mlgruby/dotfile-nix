#!/usr/bin/env bash
# git-fuzzy-log.sh - Interactive commit browser with diff preview
#
# Usage: git-fuzzy-log.sh
#
# Description:
#   Browse git commit history with fzf and preview diffs for selected commits.

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

# Browse commits with fzf and diff preview
git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr' | \
    fzf --ansi \
        --preview 'echo {} | grep -o "[a-f0-9]\{7\}" | head -1 | xargs -I % sh -c "git show --color=always %"' \
        --preview-window=right:60% \
        --prompt="Browse commits: " \
        --header="Press ENTER to view commit, ESC to exit" \
        --bind='enter:execute(echo {} | grep -o "[a-f0-9]\{7\}" | head -1 | xargs -I % sh -c "git show --color=always % | less -R")'
