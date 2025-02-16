# home-manager/modules/aws.nix
#
# AWS CLI configuration module
#
# Purpose:
# - Configures AWS CLI environment and defaults
# - Sets up shell integration and completions
# - Manages regional preferences
#
# Manages:
# - AWS CLI installation and setup
# - Default region settings
# - Output format preferences
# - CLI behavior configurations
# - AWS tools and utilities
# - Session management
#
# Features:
# - Command completion for AWS CLI
# - Default region set to us-west-2
# - Environment variable configuration
#
# Integration:
# - AWS CLI installed via Homebrew (homebrew.nix)
# - Credentials managed by aws-cred.nix
# - Works with ZSH configuration (zsh.nix)
# - Supports aliases defined in aliases.nix
#
# Note: Credentials are managed separately in aws-cred.nix

{ config, pkgs, ... }: {
  programs.zsh = {
    initExtra = ''
      # Enable AWS CLI command completion
      # Uses aws_completer from awscli2 package
      complete -C '${pkgs.awscli2}/bin/aws_completer' aws
      
      # Set AWS region defaults
      # Region: us-west-2 (Oregon)
      # Used by AWS CLI and SDKs
      export AWS_DEFAULT_REGION=us-west-2
      export AWS_REGION=us-west-2
    '';
  };
} 