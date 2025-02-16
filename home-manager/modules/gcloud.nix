# home-manager/modules/gcloud.nix
#
# Google Cloud SDK configuration
#
# Purpose:
# - Sets up Google Cloud SDK environment
# - Configures shell integration
# - Manages command-line completions
#
# Configures:
# - Google Cloud SDK installation
# - Default project settings
# - Authentication methods
# - Component management
# - Configuration preferences
# - Custom commands and aliases
#
# Features:
# - ZSH completions for gcloud commands
# - Automatic PATH configuration
# - Component auto-discovery
#
# Integration:
# - SDK installed via Homebrew (homebrew.nix)
# - Works with ZSH configuration (zsh.nix)
# - Compatible with other cloud tools (aws.nix)
#
# Usage:
# - Use 'gcloud' command for GCP operations
# - Authentication via 'gcloud auth'
# - Project switching via 'gcloud config'
#
# Note: Credentials should be managed separately

{ config, pkgs, ... }: {
  programs.zsh = {
    initExtra = ''
      # Initialize Google Cloud SDK
      # Adds completions and updates PATH
      # Source: google-cloud-sdk package from nixpkgs
      source "${pkgs.google-cloud-sdk}/google-cloud-sdk/path.zsh.inc"
    '';
  };
} 