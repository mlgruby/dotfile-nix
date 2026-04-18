#!/usr/bin/env bash
# Bootstrap LazyVim when no Neovim config exists yet.

set -euo pipefail

config_dir="$HOME/.config/nvim"
backup_dir="$HOME/.config/nvim-backups"
backup_suffix=".bak.$(date +%Y%m%d_%H%M%S)"

if [ -d "$config_dir" ]; then
  echo "LazyVim is already installed."
  exit 0
fi

echo "Installing LazyVim..."
mkdir -p "$backup_dir"

for dir in "$HOME/.config/nvim" "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"; do
  if [ -e "$dir" ]; then
    echo "Backing up $(basename "$dir") to $backup_dir/"
    mv "$dir" "$backup_dir/$(basename "$dir")$backup_suffix" 2>/dev/null || true
  fi
done

if git clone --depth 1 https://github.com/LazyVim/starter "$config_dir"; then
  rm -rf "$config_dir/.git"
  echo "LazyVim installed successfully."
  echo "Backups stored in: $backup_dir"
  echo "Run 'nvim' to complete the setup."
else
  echo "Failed to clone LazyVim starter." >&2
  exit 1
fi
