#!/usr/bin/env bash
# system-rollback.sh - Interactive system generation rollback for darwin-rebuild
#
# Usage: system-rollback.sh
#
# Description:
#   Lists all system generations and uses fzf to select and rollback to a previous generation.
#   macOS/nix-darwin only.

set -euo pipefail

# Check if darwin-rebuild is available
if ! command -v darwin-rebuild &> /dev/null; then
    echo "Error: darwin-rebuild not found. This script is for macOS/nix-darwin only." >&2
    exit 1
fi

# Check if fzf is available
if ! command -v fzf &> /dev/null; then
    echo "Error: fzf is required but not installed" >&2
    exit 1
fi

# Select generation
generation=$(darwin-rebuild --list-generations 2>/dev/null | \
    fzf --header "Select a generation to roll back to" \
        --preview "echo {} | grep -o '[0-9]\+' | xargs -I % sh -c 'nix-store -q --references /nix/var/nix/profiles/system-% 2>/dev/null || echo \"Preview unavailable\"'" \
        --preview-window "right:60%" \
        --layout=reverse \
        --height=80%)

# If a generation was selected, perform rollback
if [ -n "$generation" ]; then
    generation_number=$(echo "$generation" | grep -o '[0-9]\+' | head -1)

    echo "🔄 Rolling back to generation $generation_number..."

    if darwin-rebuild switch --switch-generation "$generation_number"; then
        echo "✅ Rollback complete!"
    else
        echo "❌ Rollback failed" >&2
        exit 1
    fi
else
    echo "No generation selected"
    exit 0
fi
