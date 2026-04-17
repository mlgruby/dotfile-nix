# home-manager/modules/alacritty/default.nix
#
# Alacritty Configuration (Declarative)
#
# Purpose:
# - Manages main config via programs.alacritty.settings
# - Uses the Nix-packaged Gruvbox theme
#
# Integration:
# - Imports config.toml
# - Overrides theme import with a Nix store path
#
# Note:
# - Package from Homebrew
{ pkgs, ... }:
let
  baseSettings = builtins.fromTOML (builtins.readFile ./config.toml);
in
{
  programs.alacritty = {
    enable = true;
    package = null;
    settings = baseSettings // {
      general.import = [ "${pkgs.alacritty-theme}/share/alacritty-theme/gruvbox_dark.toml" ];
    };
  };
}
