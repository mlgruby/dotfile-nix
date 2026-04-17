# AWS SSO helper functions.
#
# This file is sourced by Home Manager from aws-sso.nix. Keep shell behavior
# here so the Nix module stays focused on declarative AWS config.

# Lazy load AWS SSO functions to speed up shell startup.
_aws_sso_loaded=false

_load_aws_sso() {
  [ "$_aws_sso_loaded" = true ] && return
  _aws_sso_loaded=true

  _aws_profile_default="${AWS_SSO_DEFAULT_PROFILE:-default-sso}"
  _aws_profile_production="${AWS_SSO_PRODUCTION_PROFILE:-production-sso}"
  _aws_profile_staging="${AWS_SSO_STAGING_PROFILE:-staging-sso}"

  # Helper: Parse credentials from AWS CLI env output.
  _aws_credential_value() {
    local creds="$1" key="$2"
    printf '%s\n' "$creds" |
      awk -F= -v key="$key" '
        $1 == key || $1 == "export " key {
          sub(/^[^=]*=/, "")
          gsub(/^"|"$/, "")
          print
          exit
        }
      '
  }

  # Helper: Export credentials without eval.
  _aws_export_env_output() {
    local creds="$1"
    local access_key secret_key session_token

    access_key="$(_aws_credential_value "$creds" "AWS_ACCESS_KEY_ID")"
    secret_key="$(_aws_credential_value "$creds" "AWS_SECRET_ACCESS_KEY")"
    session_token="$(_aws_credential_value "$creds" "AWS_SESSION_TOKEN")"

    [ -n "$access_key" ] && export AWS_ACCESS_KEY_ID="$access_key"
    [ -n "$secret_key" ] && export AWS_SECRET_ACCESS_KEY="$secret_key"
    [ -n "$session_token" ] && export AWS_SESSION_TOKEN="$session_token"

    [ -n "$access_key" ] && [ -n "$secret_key" ] && [ -n "$session_token" ]
  }

  # Helper: Test AWS credentials and return account info.
  _aws_test_creds() {
    local profile="$1"
    if AWS_PROFILE="$profile" aws sts get-caller-identity > /dev/null 2>&1; then
      AWS_PROFILE="$profile" aws sts get-caller-identity --query Account --output text 2>/dev/null
      return 0
    fi
    return 1
  }

  # Helper: SSO login for single profile.
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

  # Helper: Write credentials atomically with restrictive permissions.
  _aws_write_credentials_file() {
    local content="$1"
    local credentials_file="$HOME/.aws/credentials"
    local credentials_dir="$HOME/.aws"
    local temp_file

    mkdir -p "$credentials_dir"
    chmod 700 "$credentials_dir" 2>/dev/null || true
    temp_file="$(mktemp "$credentials_dir/credentials.XXXXXX")" || return 1
    chmod 600 "$temp_file"
    printf '%s\n' "$content" > "$temp_file"
    mv "$temp_file" "$credentials_file"
    chmod 600 "$credentials_file"
  }

  # Core SSO login function (single or both).
  aws_sso_login() {
    if [ $# -eq 0 ] || [ "$1" = "both" ]; then
      echo "🔐 Logging into both AWS SSO profiles..."
      _aws_sso_login_single "$_aws_profile_production" "Production SSO login" || return 1
      echo ""
      _aws_sso_login_single "$_aws_profile_default" "Default SSO login" || return 1
      echo ""
      echo "✅ Both SSO profiles logged in successfully!"
      export AWS_PROFILE="$_aws_profile_default"
    else
      _aws_sso_login_single "$1" "Logging into AWS SSO for profile: $1" || return 1
      export AWS_PROFILE="$1"
      sleep 2
      local account_id
      if account_id="$(_aws_test_creds "$1")"; then
        echo "✅ SSO credentials working - Account: $account_id"
      else
        echo "⚠️  SSO login succeeded but credentials not ready"
      fi
    fi
    echo "🎯 Active profile: $AWS_PROFILE"
  }

  # Profile switching with credential testing.
  aws_profile() {
    local profile="${1:-default}"
    if ! aws configure list-profiles | grep -Fxq "$profile"; then
      echo "❌ Profile '$profile' not found. Available:"
      aws configure list-profiles
      return 1
    fi

    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
    export AWS_PROFILE="$profile"
    echo "🎯 Switched to AWS profile: $AWS_PROFILE"

    local account_id
    if account_id="$(_aws_test_creds "$profile")"; then
      local user_arn
      user_arn=$(AWS_PROFILE="$profile" aws sts get-caller-identity --query Arn --output text 2>/dev/null)
      echo "✅ Profile working - Account: $account_id"
      echo "👤 Identity: $user_arn"
    else
      echo "⚠️  Profile credentials may be expired. Run: aws_sso_login $profile"
    fi
  }

  # Export credentials as environment variables.
  aws_export_creds() {
    local profile="${AWS_PROFILE:-default}"
    [ -z "$profile" ] && { echo "❌ No AWS profile set"; return 1; }

    echo "📤 Exporting credentials for profile: $profile"
    if ! _aws_test_creds "$profile" > /dev/null; then
      echo "❌ Failed to get credentials. Profile may be expired."
      echo "💡 Try: aws_sso_login $profile"
      return 1
    fi

    local temp_creds
    temp_creds=$(aws configure export-credentials --profile "$profile" --format env 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$temp_creds" ] && _aws_export_env_output "$temp_creds"; then
      echo "✅ Exporting temporary credentials as environment variables..."
      echo "🔑 Credentials exported: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN"
      local account_id
      if account_id="$(_aws_test_creds "$profile")"; then
        echo "✅ Environment credentials verified - Account: $account_id"
      fi
    else
      echo "⚠️  Could not export credentials as environment variables"
      return 1
    fi
  }

  # Export credentials to ~/.aws/credentials file.
  aws_export_to_file() {
    local source_profile="${1:-$AWS_PROFILE}"
    local target_profile="${2:-$source_profile}"
    [ -z "$source_profile" ] && { echo "❌ No profile specified"; return 1; }

    echo "📁 Exporting credentials from '$source_profile' to '$target_profile' in ~/.aws/credentials"

    local temp_creds_env
    temp_creds_env=$(aws configure export-credentials --profile "$source_profile" --format env 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$temp_creds_env" ]; then
      echo "❌ Failed to get credentials for profile '$source_profile'"
      echo "💡 Try: aws_sso_login $source_profile"
      return 1
    fi

    local access_key secret_key session_token
    access_key="$(_aws_credential_value "$temp_creds_env" "AWS_ACCESS_KEY_ID")"
    secret_key="$(_aws_credential_value "$temp_creds_env" "AWS_SECRET_ACCESS_KEY")"
    session_token="$(_aws_credential_value "$temp_creds_env" "AWS_SESSION_TOKEN")"

    [ -z "$access_key" ] || [ -z "$secret_key" ] || [ -z "$session_token" ] && {
      echo "❌ Failed to parse credentials"; return 1;
    }

    [ -f "$HOME/.aws/credentials" ] && {
      cp "$HOME/.aws/credentials" "$HOME/.aws/credentials.backup.$(date +%Y%m%d_%H%M%S)"
      chmod 600 "$HOME/.aws/credentials.backup."* 2>/dev/null || true
      echo "📋 Backed up existing credentials file"
    }

    _aws_write_credentials_file "[$target_profile]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
aws_session_token = $session_token" || return 1

    echo "✅ Credentials written to ~/.aws/credentials as [$target_profile]"
    local account_id
    if account_id="$(_aws_test_creds "$target_profile")"; then
      echo "✅ File credentials verified - Account: $account_id"
    fi
  }

  # Export both profiles to ~/.aws/credentials file.
  aws_export_both_to_file() {
    echo "📁 Exporting both profiles to ~/.aws/credentials"

    [ -f "$HOME/.aws/credentials" ] && {
      cp "$HOME/.aws/credentials" "$HOME/.aws/credentials.backup.$(date +%Y%m%d_%H%M%S)"
      chmod 600 "$HOME/.aws/credentials.backup."* 2>/dev/null || true
      echo "📋 Backed up existing credentials file"
    }

    local prod_creds default_creds
    prod_creds=$(aws configure export-credentials --profile "$_aws_profile_production" --format env 2>/dev/null)
    default_creds=$(aws configure export-credentials --profile "$_aws_profile_default" --format env 2>/dev/null)

    [ -z "$prod_creds" ] && { echo "❌ Failed to get production credentials"; return 1; }
    [ -z "$default_creds" ] && { echo "❌ Failed to get default credentials"; return 1; }

    local prod_access prod_secret prod_token default_access default_secret default_token
    prod_access="$(_aws_credential_value "$prod_creds" "AWS_ACCESS_KEY_ID")"
    prod_secret="$(_aws_credential_value "$prod_creds" "AWS_SECRET_ACCESS_KEY")"
    prod_token="$(_aws_credential_value "$prod_creds" "AWS_SESSION_TOKEN")"
    default_access="$(_aws_credential_value "$default_creds" "AWS_ACCESS_KEY_ID")"
    default_secret="$(_aws_credential_value "$default_creds" "AWS_SECRET_ACCESS_KEY")"
    default_token="$(_aws_credential_value "$default_creds" "AWS_SESSION_TOKEN")"

    [ -z "$prod_access" ] || [ -z "$prod_secret" ] || [ -z "$prod_token" ] && {
      echo "❌ Failed to parse production credentials"; return 1;
    }
    [ -z "$default_access" ] || [ -z "$default_secret" ] || [ -z "$default_token" ] && {
      echo "❌ Failed to parse default credentials"; return 1;
    }

    _aws_write_credentials_file "[production]
aws_access_key_id = $prod_access
aws_secret_access_key = $prod_secret
aws_session_token = $prod_token

[default]
aws_access_key_id = $default_access
aws_secret_access_key = $default_secret
aws_session_token = $default_token" || return 1

    echo "✅ Both profiles written to ~/.aws/credentials"
    echo "🎉 Ready for Scala/Java applications!"
  }

  # Utility functions.
  aws_clear() {
    echo "🧹 Clearing ALL AWS credentials and SSO sessions..."
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE AWS_DEFAULT_REGION AWS_REGION
    aws sso logout 2>/dev/null || echo "⚠️  No active SSO session to logout"
    echo "✅ All AWS credentials and sessions cleared"
  }

  aws_status() {
    echo "📊 AWS SSO Configuration Status:"
    echo "  Current Profile: ${AWS_PROFILE:-none}"
    echo "  Region: ${AWS_DEFAULT_REGION:-eu-west-1}"
    [ -n "$AWS_ACCESS_KEY_ID" ] && echo "  Access Key: Set (***${AWS_ACCESS_KEY_ID: -4})"

    local account_id
    if [ -n "$AWS_PROFILE" ] && account_id="$(_aws_test_creds "$AWS_PROFILE")"; then
      local user_arn
      user_arn=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)
      echo "✅ Active - Account: $account_id"
      echo "👤 Identity: $user_arn"
    else
      echo "❌ No active credentials"
    fi
  }

  # Workflow functions.
  aws_prod_env() {
    echo "🚀 Setting production profile and exporting credentials..."
    aws_profile "$_aws_profile_production" && aws_export_creds && {
      echo "📁 Also exporting to ~/.aws/credentials file..."
      aws_export_to_file "$_aws_profile_production" production
    }
  }

  aws_default_env() {
    echo "🏠 Setting default profile and exporting credentials..."
    aws_profile "$_aws_profile_default" && aws_export_creds && {
      echo "📁 Also exporting to ~/.aws/credentials file..."
      aws_export_to_file "$_aws_profile_default" default
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

  # Backward-compatible names.
  aws_prod() { aws_profile "$_aws_profile_production"; }
  aws_staging() { aws_profile "$_aws_profile_staging"; }
  aws_dev() { aws_profile "$_aws_profile_staging"; }
  aws_refresh() { aws_sso_login "${1:-both}"; }
  aws_refresh_both() { aws_sso_login both; }
  aws_logout() { aws_clear; }
}

# Lazy wrapper functions that load AWS SSO on first use.
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

awsprod() { _load_aws_sso && aws_prod "$@"; }
awsdefault() { _load_aws_sso && aws_profile "${AWS_SSO_DEFAULT_PROFILE:-default-sso}" "$@"; }
awsprod-trad() { _load_aws_sso && aws_profile production "$@"; }
awsdefault-trad() { _load_aws_sso && aws_profile default "$@"; }
awsrp() { _load_aws_sso && aws_sso_login "${AWS_SSO_PRODUCTION_PROFILE:-production-sso}" "$@"; }
awsrs() { _load_aws_sso && aws_sso_login "${AWS_SSO_STAGING_PROFILE:-staging-sso}" "$@"; }
awsrd() { _load_aws_sso && aws_sso_login "${AWS_SSO_DEFAULT_PROFILE:-default-sso}" "$@"; }
