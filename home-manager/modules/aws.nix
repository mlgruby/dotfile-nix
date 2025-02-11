# home-manager/modules/aws.nix
#
# AWS CLI configuration module
# Manages:
# - AWS CLI installation and setup
# - Default region settings
# - Output format preferences
# - CLI behavior configurations
# - AWS tools and utilities
# - Session management
#
# Note: Credentials are managed separately in aws-cred.nix

{ config, pkgs, ... }: {
  programs.zsh = {
    initExtra = ''
      # AWS CLI completions
      complete -C '${pkgs.awscli2}/bin/aws_completer' aws
      
      # Set default AWS region
      export AWS_DEFAULT_REGION=us-west-2
      export AWS_REGION=us-west-2
    '';
  };
} 