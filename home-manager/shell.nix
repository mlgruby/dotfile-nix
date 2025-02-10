# home/shell.nix
{ config, pkgs, ... }:

{
  # Configure starship prompt
  programs.starship = {
    enable = true;
  };

  # FZF configuration
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}