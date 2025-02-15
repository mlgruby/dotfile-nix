# home-manager/modules/alacritty/default.nix
#
# Alacritty terminal configuration
#
# Features:
# - GPU-accelerated terminal emulator
# - Custom color scheme
# - Font configuration
# - Window and cursor settings
# - Key bindings

{ config, lib, pkgs, ... }:

{
  # Clone alacritty-theme repository
  home.activation.alacrittyThemes = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -d "$HOME/.config/alacritty/themes" ]; then
      ${pkgs.git}/bin/git clone https://github.com/alacritty/alacritty-theme \
        "$HOME/.config/alacritty/themes"
    else
      if [ -d "$HOME/.config/alacritty/themes/.git" ]; then
        cd "$HOME/.config/alacritty/themes"
        ${pkgs.git}/bin/git pull
      fi
    fi

    # Create symlink directly from repo's config.toml to alacritty.toml
    ln -sf "${toString ./config.toml}" "$HOME/.config/alacritty/alacritty.toml"
  '';
} 