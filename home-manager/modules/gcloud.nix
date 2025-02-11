{ config, pkgs, ... }: {
  programs.zsh = {
    initExtra = ''
      # Google Cloud SDK completions and PATH
      source "${pkgs.google-cloud-sdk}/google-cloud-sdk/path.zsh.inc"
    '';
  };
} 