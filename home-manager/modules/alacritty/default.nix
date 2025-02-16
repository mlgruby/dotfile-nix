# home-manager/modules/alacritty/default.nix
#
# Alacritty terminal configuration
#
# Purpose:
# - Sets up Alacritty configuration and themes
# - Manages theme repository and updates
# - Links configuration files to correct locations
#
# Features:
# - GPU-accelerated terminal emulator
# - Automatic theme management:
#   - Clones alacritty-theme repository
#   - Updates themes on rebuild
#   - Uses Gruvbox Dark theme
#
# Integration:
# - Uses config.toml for main configuration
# - Symlinks configuration to ~/.config/alacritty/
# - Works with Home Manager activation system
#
# Note:
# - Alacritty package is installed via Homebrew (homebrew.nix)
# - Main configuration is in ./config.toml

{ config, lib, pkgs, ... }:

{
  # Set up Alacritty themes and configuration
  # This runs after configuration files are written
  home.activation.alacrittyThemes = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Clone or update alacritty-theme repository
    if [ ! -d "$HOME/.config/alacritty/themes" ]; then
      ${pkgs.git}/bin/git clone https://github.com/alacritty/alacritty-theme \
        "$HOME/.config/alacritty/themes"
    else
      if [ -d "$HOME/.config/alacritty/themes/.git" ]; then
        cd "$HOME/.config/alacritty/themes"
        ${pkgs.git}/bin/git pull
      fi
    fi

    # Link our configuration file to Alacritty's expected location
    # Using symlink to maintain single source of truth
    ln -sf "${toString ./config.toml}" "$HOME/.config/alacritty/alacritty.toml"
  '';
} 