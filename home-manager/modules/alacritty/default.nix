# home-manager/modules/alacritty/default.nix
#
# Alacritty Theme Management
#
# Purpose:
# - Manages Alacritty themes
# - Links configuration file
#
# Integration:
# - Links config.toml
# - Uses Home Manager activation
#
# Note:
# - Package from Homebrew
# - Config in config.toml

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