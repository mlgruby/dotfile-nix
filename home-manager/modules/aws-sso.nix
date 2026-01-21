# home-manager/modules/aws-sso.nix
#
# AWS Configuration (Consolidated)
#
# Purpose:
# - Configures AWS CLI for SSO authentication
# - Manages multiple AWS accounts through SSO
# - Provides convenient profile switching functions
# - Sets up AWS CLI command completion
#
# Features:
# - AWS CLI command completion
# - Automatic SSO authentication flow
# - Credential auto-refresh
# - Easy account switching
# - Integration with existing aliases
#
# Accounts:
# - Vortexa Production (501857513371)
# - Vortexa Development (045251666112)
{pkgs, ...}: let
  defaults = import ../config.nix;
  inherit (defaults.aws) region ssoStartUrl ssoRoleName;
  inherit (defaults.aws.accounts) production staging;
in {
  # AWS SSO Configuration
  home.file.".aws/config".text = ''
    # Traditional profiles for Java/Scala applications (no SSO properties)
    [default]
    region = ${region}
    output = json

    [profile production]
    region = ${region}
    output = json

    [profile staging]
    region = ${region}
    output = json

    [profile prod]
    region = ${region}
    output = json

    [profile dev]
    region = ${region}
    output = json

    # SSO profiles for CLI usage
    [profile production-sso]
    sso_start_url = ${ssoStartUrl}
    sso_region = ${region}
    sso_account_id = ${production}
    sso_role_name = ${ssoRoleName}
    region = ${region}
    output = json

    [profile staging-sso]
    sso_start_url = ${ssoStartUrl}
    sso_region = ${region}
    sso_account_id = ${staging}
    sso_role_name = ${ssoRoleName}
    region = ${region}
    output = json

    [profile default-sso]
    sso_start_url = ${ssoStartUrl}
    sso_region = ${region}
    sso_account_id = ${staging}
    sso_role_name = ${ssoRoleName}
    region = ${region}
    output = json
  '';

  programs.zsh = {
    initContent = ''
            # Enable AWS CLI command completion
            # Uses aws_completer from awscli2 package
            if command -v aws_completer &> /dev/null; then
               complete -C aws_completer aws
            elif [ -x "${pkgs.awscli2}/bin/aws_completer" ]; then # Check Nix pkg path
               complete -C "${pkgs.awscli2}/bin/aws_completer" aws
            fi

            # Set AWS default regions
            export AWS_DEFAULT_REGION="${region}"
            export AWS_REGION="${region}"

            # Lazy load AWS SSO functions to speed up shell startup
            _aws_sso_loaded=false

            _load_aws_sso() {
              [ "$_aws_sso_loaded" = true ] && return
              _aws_sso_loaded=true

              # AWS SSO Helper Functions - Optimized & Streamlined

              # Helper: Parse credentials from env format output
              # Usage: eval "$(_parse_creds "$creds_env" "varprefix")"
              # Sets: varprefix_access, varprefix_secret, varprefix_token
              _parse_creds() {
                local creds="$1" prefix="$2"
                echo "''${prefix}_access=$(echo "$creds" | grep 'AWS_ACCESS_KEY_ID=' | cut -d'=' -f2-)"
                echo "''${prefix}_secret=$(echo "$creds" | grep 'AWS_SECRET_ACCESS_KEY=' | cut -d'=' -f2-)"
                echo "''${prefix}_token=$(echo "$creds" | grep 'AWS_SESSION_TOKEN=' | cut -d'=' -f2-)"
              }

              # Helper: Test AWS credentials and return account info
              _aws_test_creds() {
                local profile="$1"
                if AWS_PROFILE="$profile" aws sts get-caller-identity > /dev/null 2>&1; then
                  AWS_PROFILE="$profile" aws sts get-caller-identity --query Account --output text 2>/dev/null
                  return 0
                fi
                return 1
              }

              # Helper: SSO login for single profile
              _aws_sso_login_single() {
                local profile="$1"
                local label="$2"
                echo "🔐 $label..."
                aws sso login --profile "$profile"
                if [ $? -eq 0 ]; then
                  echo "✅ $label successful"
                  return 0
                else
                  echo "❌ $label failed"
                  return 1
                fi
              }

              # Core SSO login function (single or both)
              aws_sso_login() {
                local profiles=("''${@:-default-sso}")

                if [ $# -eq 0 ] || [ "$1" = "both" ]; then
                  # Login to both profiles
                  echo "🔐 Logging into both AWS SSO profiles..."
                  _aws_sso_login_single "production-sso" "Production SSO login" || return 1
                  echo ""
                  _aws_sso_login_single "default-sso" "Default SSO login" || return 1
                  echo ""
                  echo "✅ Both SSO profiles logged in successfully!"
                  export AWS_PROFILE="default-sso"
                else
                  # Login to single profile
                  _aws_sso_login_single "$1" "Logging into AWS SSO for profile: $1" || return 1
                  export AWS_PROFILE="$1"
                  sleep 2
                  if local account_id=$(_aws_test_creds "$1"); then
                    echo "✅ SSO credentials working - Account: $account_id"
                  else
                    echo "⚠️  SSO login succeeded but credentials not ready"
                  fi
                fi
                echo "🎯 Active profile: $AWS_PROFILE"
              }

              # Profile switching with credential testing
              aws_profile() {
                local profile="''${1:-default}"
                if ! aws configure list-profiles | grep -q "^$profile$"; then
                  echo "❌ Profile '$profile' not found. Available:"
                  aws configure list-profiles
                  return 1
                fi

                unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
                export AWS_PROFILE="$profile"
                echo "🎯 Switched to AWS profile: $AWS_PROFILE"

                if local account_id=$(_aws_test_creds "$profile"); then
                  local user_arn=$(AWS_PROFILE="$profile" aws sts get-caller-identity --query Arn --output text 2>/dev/null)
                  echo "✅ Profile working - Account: $account_id"
                  echo "👤 Identity: $user_arn"
                else
                  echo "⚠️  Profile credentials may be expired. Run: aws_sso_login $profile"
                fi
              }

              # Export credentials as environment variables
              aws_export_creds() {
                local profile="''${AWS_PROFILE:-default}"
                [ -z "$profile" ] && { echo "❌ No AWS profile set"; return 1; }

                echo "📤 Exporting credentials for profile: $profile"
                if ! _aws_test_creds "$profile" > /dev/null; then
                  echo "❌ Failed to get credentials. Profile may be expired."
                  echo "💡 Try: aws_sso_login $profile"
                  return 1
                fi

                if local temp_creds=$(aws configure export-credentials --profile "$profile" --format env 2>/dev/null); then
                  echo "✅ Exporting temporary credentials as environment variables..."
                  eval "$temp_creds"
                  echo "🔑 Credentials exported: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN"
                  if local account_id=$(_aws_test_creds "$profile"); then
                    echo "✅ Environment credentials verified - Account: $account_id"
                  fi
                else
                  echo "⚠️  Could not export credentials as environment variables"
                fi
              }

              # Export credentials to ~/.aws/credentials file
              aws_export_to_file() {
                local source_profile="''${1:-$AWS_PROFILE}"
                local target_profile="''${2:-$source_profile}"
                [ -z "$source_profile" ] && { echo "❌ No profile specified"; return 1; }

                echo "📁 Exporting credentials from '$source_profile' to '$target_profile' in ~/.aws/credentials"

                local temp_creds_env=$(aws configure export-credentials --profile "$source_profile" --format env 2>/dev/null)
                if [ $? -ne 0 ] || [ -z "$temp_creds_env" ]; then
                  echo "❌ Failed to get credentials for profile '$source_profile'"
                  echo "💡 Try: aws_sso_login $source_profile"
                  return 1
                fi

                # Parse credentials using helper
                eval "$(_parse_creds "$temp_creds_env" "cred")"
                local access_key="$cred_access" secret_key="$cred_secret" session_token="$cred_token"

                [ -z "$access_key" ] || [ -z "$secret_key" ] || [ -z "$session_token" ] && {
                  echo "❌ Failed to parse credentials"; return 1;
                }

                [ -f "$HOME/.aws/credentials" ] && {
                  cp "$HOME/.aws/credentials" "$HOME/.aws/credentials.backup.$(date +%Y%m%d_%H%M%S)"
                  echo "📋 Backed up existing credentials file"
                }

                mkdir -p "$HOME/.aws"
                /bin/cat > "$HOME/.aws/credentials" << EOF
      [$target_profile]
      aws_access_key_id = $access_key
      aws_secret_access_key = $secret_key
      aws_session_token = $session_token
      EOF

                echo "✅ Credentials written to ~/.aws/credentials as [$target_profile]"
                if local account_id=$(_aws_test_creds "$target_profile"); then
                  echo "✅ File credentials verified - Account: $account_id"
                fi
              }

              # Export credentials to ~/.aws/credentials file
              aws_export_both_to_file() {
                echo "📁 Exporting both profiles to ~/.aws/credentials"

                [ -f "$HOME/.aws/credentials" ] && {
                  cp "$HOME/.aws/credentials" "$HOME/.aws/credentials.backup.$(date +%Y%m%d_%H%M%S)"
                  echo "📋 Backed up existing credentials file"
                }

                # Get both credential sets
                local prod_creds=$(aws configure export-credentials --profile "production-sso" --format env 2>/dev/null)
                local default_creds=$(aws configure export-credentials --profile "default-sso" --format env 2>/dev/null)

                [ -z "$prod_creds" ] && { echo "❌ Failed to get production credentials"; return 1; }
                [ -z "$default_creds" ] && { echo "❌ Failed to get default credentials"; return 1; }

                # Parse credentials using helper
                eval "$(_parse_creds "$prod_creds" "prod")"
                eval "$(_parse_creds "$default_creds" "default")"

                # Write both profiles
                mkdir -p "$HOME/.aws"
                /bin/cat > "$HOME/.aws/credentials" << EOF
      [production]
      aws_access_key_id = $prod_access
      aws_secret_access_key = $prod_secret
      aws_session_token = $prod_token

      [default]
      aws_access_key_id = $default_access
      aws_secret_access_key = $default_secret
      aws_session_token = $default_token
      EOF

                echo "✅ Both profiles written to ~/.aws/credentials"
                echo "🎉 Ready for Scala/Java applications!"
              }

              # Utility functions
              aws_clear() {
                echo "🧹 Clearing ALL AWS credentials and SSO sessions..."
                unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE AWS_DEFAULT_REGION AWS_REGION
                aws sso logout 2>/dev/null || echo "⚠️  No active SSO session to logout"
                echo "✅ All AWS credentials and sessions cleared"
              }

              aws_status() {
                echo "📊 AWS SSO Configuration Status:"
                echo "  Current Profile: ''${AWS_PROFILE:-none}"
                echo "  Region: ''${AWS_DEFAULT_REGION:-eu-west-1}"
                [ -n "$AWS_ACCESS_KEY_ID" ] && echo "  Access Key: Set (***''${AWS_ACCESS_KEY_ID: -4})"

                if [ -n "$AWS_PROFILE" ] && local account_id=$(_aws_test_creds "$AWS_PROFILE"); then
                  local user_arn=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)
                  echo "✅ Active - Account: $account_id"
                  echo "👤 Identity: $user_arn"
                else
                  echo "❌ No active credentials"
                fi
              }

              # Workflow functions (using core functions)
              aws_prod_env() {
                echo "🚀 Setting production profile and exporting credentials..."
                aws_profile production-sso && aws_export_creds && {
                  echo "📁 Also exporting to ~/.aws/credentials file..."
                  aws_export_to_file production-sso production
                }
              }

              aws_default_env() {
                echo "🏠 Setting default profile and exporting credentials..."
                aws_profile default-sso && aws_export_creds && {
                  echo "📁 Also exporting to ~/.aws/credentials file..."
                  aws_export_to_file default-sso default
                }
              }

              aws_super_workflow() {
                echo "🚀 AWS Super Workflow: Login Both SSO → Export Both Credentials"
                aws_sso_login both && {
                  echo "3️⃣ Exporting both profiles to credentials file..."
                  aws_export_both_to_file && {
                    echo "🎉 Super workflow complete! Ready for Java/Scala applications!"
                  }
                }
              }

              # Simple aliases for backward compatibility
              aws_prod() { aws_profile production-sso; }
              aws_staging() { aws_profile staging-sso; }
              aws_dev() { aws_profile staging-sso; }
              aws_refresh() { aws_sso_login "''${1:-both}"; }
              aws_refresh_both() { aws_sso_login both; }
              aws_logout() { aws_clear; }
            }

            # Lazy wrapper functions that load AWS SSO on first use
            # First, remove any existing aliases that might conflict
            unalias awsp awsd awse awsf awsc awsl awsr awsw awsb awsall awsprod awsdefault awsprod-trad awsdefault-trad awsrp awsrs awsrd 2>/dev/null || true

            awsp() { _load_aws_sso && aws_prod_env "$@"; }
            awsd() { _load_aws_sso && aws_default_env "$@"; }
            awse() { _load_aws_sso && aws_export_creds "$@"; }
            awsf() { _load_aws_sso && aws_super_workflow "$@"; }
            awsc() { _load_aws_sso && aws_clear "$@"; }
            awsl() { _load_aws_sso && aws_sso_login both "$@"; }
            awsr() { _load_aws_sso && aws_refresh_both "$@"; }
            awsw() { _load_aws_sso && aws_export_to_file "$@"; }
            awsb() { _load_aws_sso && aws_export_both_to_file "$@"; }
            awsall() { _load_aws_sso && aws_super_workflow "$@"; }

            # Individual profile aliases
            awsprod() { _load_aws_sso && aws_prod "$@"; }
            awsdefault() { _load_aws_sso && aws_profile default-sso "$@"; }
            awsprod-trad() { _load_aws_sso && aws_profile production "$@"; }
            awsdefault-trad() { _load_aws_sso && aws_profile default "$@"; }
            awsrp() { _load_aws_sso && aws_sso_login production-sso "$@"; }
            awsrs() { _load_aws_sso && aws_sso_login staging-sso "$@"; }
            awsrd() { _load_aws_sso && aws_sso_login default-sso "$@"; }
    '';

    sessionVariables = {
      # AWS defaults
      AWS_DEFAULT_REGION = region;
      AWS_REGION = region;
    };
  };
}
