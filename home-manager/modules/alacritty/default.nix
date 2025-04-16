# home-manager/modules/alacritty/default.nix
#
# Alacritty Configuration (Declarative)
#
# Purpose:
# - Manages Alacritty themes via activation script
# - Manages main config via programs.alacritty.settings
#
# Integration:
# - Imports config.toml
# - Uses Home Manager activation for themes
#
# Note:
# - Package from Homebrew

{ config, lib, pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    # Read settings directly from the TOML file
    settings = builtins.fromTOML (builtins.readFile ./config.toml);
  };

  # Activation script ONLY for managing themes repo
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
    # Symlink creation removed - handled by programs.alacritty
  '';
}
