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

list_generations() {
    local current link gen target mtime mark
    current="$(readlink -f /run/current-system 2>/dev/null || true)"
    shopt -s nullglob
    for link in /nix/var/nix/profiles/system-*-link; do
        gen="${link##*/system-}"
        gen="${gen%-link}"
        target="$(readlink -f "$link" 2>/dev/null || true)"
        mtime="$(/usr/bin/stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S' "$link" 2>/dev/null || true)"
        mark=""
        if [[ -n "$current" && "$target" == "$current" ]]; then
            mark=" (current)"
        fi
        printf "%s  %s  %s%s\n" "$gen" "$mtime" "${target##*-darwin-system-}" "$mark"
    done | sort -rn
}

# Select generation
generation=$(list_generations | \
    fzf --header "Select a generation to roll back to (preview shows package diff vs current)" \
        --preview "if command -v nvd >/dev/null 2>&1; then nvd diff /run/current-system /nix/var/nix/profiles/system-{1}-link 2>/dev/null; else nix-store -q --references /nix/var/nix/profiles/system-{1}-link 2>/dev/null; fi" \
        --preview-window "right:65%:wrap" \
        --layout=reverse \
        --height=80% || true)

# If a generation was selected, perform rollback
if [ -n "$generation" ]; then
    generation_number=$(awk '{print $1}' <<< "$generation")

    echo "🔄 Rolling back to generation $generation_number..."

    if sudo darwin-rebuild switch --switch-generation "$generation_number"; then
        echo "✅ Rollback complete!"
    else
        echo "❌ Rollback failed" >&2
        exit 1
    fi
else
    echo "No generation selected"
    exit 0
fi
