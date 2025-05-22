# home-manager/modules/aws-cred.nix
#
# Custom AWS Credential Management via Zsh Function
#
# Purpose:
# - Defines a Zsh function to write credentials from ENV vars to ~/.aws/credentials
# - Provides profile switching aliases (assumes ENV vars are set first)
#
# Note: Using function instead of script for better shell integration.

{ config, pkgs, ... }: {

  programs.zsh = {
    # Function definition added to Zsh initialization
    initContent = ''
      # Function to write ENV credentials to ~/.aws/credentials profile
      set_aws_profile() {
        local profile_name="''${1:-default}"
        local creds_file="$HOME/.aws/credentials"
        local tmp_file

        # Check if required variables are set
        if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
          echo "Error: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be set." >&2
          return 1
        fi

        echo "Setting profile [$profile_name] in $creds_file..."

        # Ensure directory and file exist
        mkdir -p "$(dirname "$creds_file")"
        touch "$creds_file"

        # Use temp file for atomic update
        tmp_file=$(mktemp)
        if [ -f "$creds_file" ]; then
          # Copy existing content excluding the target profile
          sed "/^\\[$profile_name\\]/,/^$/d" "$creds_file" > "$tmp_file" || true
        fi

        # Append new credentials block
        {
          echo "[$profile_name]"
          echo "aws_access_key_id = $AWS_ACCESS_KEY_ID"
          echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY"
          # Only add session token line if the variable exists and is non-empty
          [[ -n "$AWS_SESSION_TOKEN" ]] && echo "aws_session_token = $AWS_SESSION_TOKEN"
        } >> "$tmp_file"

        # Atomically replace the original file
        if mv "$tmp_file" "$creds_file"; then
          echo "Successfully updated profile [$profile_name]."
          # Unset environment variables only on success
          unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
        else
          echo "Error: Failed to update $creds_file. Check permissions or temp file." >&2
          rm -f "$tmp_file" # Clean up temp file on failure
          return 1
        fi
      }
    ''; # End of initContent

    # Aliases now call the function defined above
    shellAliases = {
      awsdef = "set_aws_profile default";     # Use 'default' profile name
      awsprod = "set_aws_profile production"; # Use 'production' profile name
      awsdev = "set_aws_profile default";     # Map 'dev' alias to 'default' profile
      awsclear = "rm -f $HOME/.aws/credentials && unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE AWS_DEFAULT_PROFILE && echo \'AWS credentials file and ENV variables cleared\'";
    };
  };
} 