# home-manager/modules/aws.nix
#
# AWS CLI Basic Setup
#
# Purpose:
# - Enables AWS CLI command completion
# - Sets default AWS region
#
# Integration:
# - AWS CLI installed via Homebrew (homebrew.nix)
# - Credentials managed by aws-cred.nix

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
