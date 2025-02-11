# home-manager/modules/gcloud.nix
#
# Google Cloud SDK configuration
# Configures:
# - Google Cloud SDK installation
# - Default project settings
# - Authentication methods
# - Component management
# - Configuration preferences
# - Custom commands and aliases
#
# Note: Credentials should be managed separately

{ config, pkgs, ... }: {
  programs.zsh = {
    initExtra = ''
      # Google Cloud SDK completions and PATH
      source "${pkgs.google-cloud-sdk}/google-cloud-sdk/path.zsh.inc"
    '';
  };
} 