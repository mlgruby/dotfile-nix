# home-manager/modules/gcloud.nix
#
# Google Cloud SDK Shell Setup
#
# Purpose:
# - Adds gcloud to shell PATH
# - Enables command completion
#
# Features:
# - SDK installed via Homebrew
# - Works with ZSH configuration
#
# Integration:
# - SDK installed via Homebrew
# - Works with ZSH configuration
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