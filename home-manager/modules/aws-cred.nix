# home-manager/modules/aws-cred.nix
#
# AWS Credential Scripts
#
# Purpose:
# - Creates credential helper scripts
# - Provides profile switching aliases
#
# Features:
# - Credential file generation
# - Environment cleanup
# - Profile switching:
#   - awsdef (default)
#   - awsprod (production)
#   - awsdev (development)
#
# Integration:
# - Works with aws.nix
# - Uses ZSH aliases

{ config, pkgs, ... }: {
  # Create directory for AWS credential management scripts
  home.file = {
    # Create directory for AWS credentials script
    ".local/bin/aws_cred_copy" = {
      source = pkgs.writeScript "aws_cred_copy" ''
        #!/bin/bash
        mkdir -p $HOME/.aws
        
        # Get profile name from argument or use default
        PROFILE_NAME="''${1:-default}"
        
        # Create or update the credentials file
        if [ ! -f $HOME/.aws/credentials ]; then
          touch $HOME/.aws/credentials
        fi
        
        # Create a temporary file
        TMP_FILE=$(mktemp)
        
        # Copy existing credentials without the target profile
        sed "/^\[$PROFILE_NAME\]/,/^$/d" "$HOME/.aws/credentials" > "$TMP_FILE"
        
        # Add new profile
        echo "[$PROFILE_NAME]" >> "$TMP_FILE"
        echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> "$TMP_FILE"
        echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> "$TMP_FILE"
        echo "aws_session_token = $AWS_SESSION_TOKEN" >> "$TMP_FILE"
        
        # Move temporary file back
        mv "$TMP_FILE" "$HOME/.aws/credentials"
        
        # Clean up environment variables
        unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
      '';
      executable = true;
    };

    # Create the copy_and_unset script
    ".local/bin/copy_and_unset" = {
      text = ''
        #!/bin/bash
        $HOME/.local/bin/aws_cred_copy "$1"
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
      awsclear = "rm -f ~/.aws/credentials && unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE AWS_DEFAULT_PROFILE && echo 'AWS credentials cleared'";
    };
  };
}
