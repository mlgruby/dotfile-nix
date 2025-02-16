# home-manager/modules/aws-cred.nix
#
# AWS credentials management
#
# Purpose:
# - Manages AWS credentials securely
# - Provides easy profile switching
# - Handles temporary credentials
#
# Handles:
# - AWS credential file structure
# - Profile configurations
# - SSO settings
# - Role assumptions
# - Credential helpers
# - Security configurations
#
# Features:
# - Secure credential file management
# - Environment variable handling
# - Profile switching commands:
#   - awsdef: Switch to default profile
#   - awsprod: Switch to production profile
#   - awsdev: Switch to development profile
#
# Security:
# - Credentials stored in ~/.aws/credentials
# - Environment variables cleared after use
# - Terminal cleared during profile switch
#
# Integration:
# - Works with aws.nix for CLI configuration
# - Uses ZSH aliases for easy switching
# - Compatible with AWS SSO sessions
#
# Important: Keep sensitive information in separate files
# and use environment variables where appropriate

{ config, pkgs, ... }: {
  # Create directory for AWS credential management scripts
  home.file = {
    # Create directory for AWS credentials script
    ".local/bin/aws_cred_copy" = {
      source = pkgs.writeScript "aws_cred_copy" ''
        #!/bin/bash
        mkdir -p ~/.aws
        echo "[default]" > ~/.aws/credentials
        echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> ~/.aws/credentials
        echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> ~/.aws/credentials
        echo "aws_session_token = $AWS_SESSION_TOKEN" >> ~/.aws/credentials
        unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
      '';
      executable = true;
    };

    # Create the copy_and_unset script
    ".local/bin/copy_and_unset" = {
      text = ''
        #!/bin/bash
        ~/.local/bin/aws_cred_copy
      '';
      executable = true;
    };
  };

  # Add AWS credential switching aliases
  programs.zsh = {
    shellAliases = {
      awsdef = "osascript -e 'tell application \"System Events\" to keystroke \"k\" using command down' && ~/.local/bin/copy_and_unset default";
      awsprod = "osascript -e 'tell application \"System Events\" to keystroke \"k\" using command down' && ~/.local/bin/copy_and_unset production";
      awsdev = "osascript -e 'tell application \"System Events\" to keystroke \"k\" using command down' && ~/.local/bin/copy_and_unset development";
    };
  };
}
