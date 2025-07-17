#!/bin/bash

# AWS SSO Setup Script for Non-Nix Users
# Supports both bash and zsh shells automatically
# Includes short aliases and credential export functionality

set -e

echo "🚀 Setting up AWS SSO configuration for Lightricks..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first:"
    echo "   macOS: brew install awscli"
    echo "   Linux: curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\" && unzip awscliv2.zip && sudo ./aws/install"
    exit 1
fi

# Create .aws directory
mkdir -p ~/.aws

# Backup existing config if it exists
if [ -f ~/.aws/config ]; then
    backup_file="$HOME/.aws/config.backup.$(date +%Y%m%d_%H%M%S)"
    cp ~/.aws/config "$backup_file"
    echo "📋 Backed up existing AWS config to: $backup_file"
fi

# Create the AWS config file
cat > ~/.aws/config << 'EOF'
# Traditional profiles for Java/Scala applications (no SSO properties)
[default]
region = us-west-2
output = json

[profile production]
region = us-west-2
output = json

[profile staging]
region = us-west-2
output = json

[profile prod]
region = us-west-2
output = json

[profile dev]
region = us-west-2
output = json

# SSO profiles for CLI usage
[profile production-sso]
sso_start_url = https://d-90670ca891.awsapps.com/start
sso_region = us-east-1
sso_account_id = 384822754266
sso_role_name = DataPlatformTeam
region = us-west-2
output = json

[profile staging-sso]
sso_start_url = https://d-90670ca891.awsapps.com/start
sso_region = us-east-1
sso_account_id = 588736812464
sso_role_name = AdministratorAccess
region = us-west-2
output = json

[profile default-sso]
sso_start_url = https://d-90670ca891.awsapps.com/start
sso_region = us-east-1
sso_account_id = 588736812464
sso_role_name = AdministratorAccess
region = us-west-2
output = json
EOF

echo "✅ Created AWS configuration file at ~/.aws/config"

# Detect shell and appropriate config file
detect_shell_config() {
    # Check what shell the user is currently using
    current_shell=$(basename "$SHELL")
    
    case "$current_shell" in
        "zsh")
            echo "$HOME/.zshrc"
            ;;
        "bash")
            # Check which bash config file exists or should be used
            if [ -f "$HOME/.bash_profile" ]; then
                echo "$HOME/.bash_profile"
            elif [ -f "$HOME/.bashrc" ]; then
                echo "$HOME/.bashrc"
            else
                # Default to .bashrc for Linux, .bash_profile for macOS
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    echo "$HOME/.bash_profile"
                else
                    echo "$HOME/.bashrc"
                fi
            fi
            ;;
        *)
            echo ""
            ;;
    esac
}

# Get the appropriate shell config file
SHELL_CONFIG=$(detect_shell_config)
SHELL_NAME=$(basename "$SHELL")

if [ -n "$SHELL_CONFIG" ]; then
    echo "🔍 Detected $SHELL_NAME shell, using config file: $SHELL_CONFIG"
    
    # Check if functions already exist
    if [ -f "$SHELL_CONFIG" ] && grep -q "aws_sso_login" "$SHELL_CONFIG" 2>/dev/null; then
        echo "⚠️  AWS SSO functions already exist in $SHELL_CONFIG. Skipping..."
    else
        echo "📝 Adding AWS SSO functions to $SHELL_CONFIG..."
        
        # Create the config file if it doesn't exist
        touch "$SHELL_CONFIG"
        
        # Add the functions with shell-specific completion
        cat >> "$SHELL_CONFIG" << 'EOF'

# ==========================================
# AWS SSO Configuration - Added by setup script
# ==========================================
export AWS_DEFAULT_REGION="us-west-2"
export AWS_REGION="us-west-2"

# AWS SSO Helper Functions
_aws_test_creds() {
  local profile="$1"
  if AWS_PROFILE="$profile" aws sts get-caller-identity > /dev/null 2>&1; then
    AWS_PROFILE="$profile" aws sts get-caller-identity --query Account --output text 2>/dev/null
    return 0
  fi
  return 1
}

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
  local profiles=("${@:-default-sso}")
  if [ $# -eq 0 ] || [ "$1" = "both" ]; then
    echo "🔐 Logging into both AWS SSO profiles..."
    _aws_sso_login_single "production-sso" "Production SSO login" || return 1
    echo ""
    _aws_sso_login_single "default-sso" "Default SSO login" || return 1
    echo ""
    echo "✅ Both SSO profiles logged in successfully!"
    export AWS_PROFILE="default-sso"
  else
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
  local profile="${1:-default}"
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
  local profile="${AWS_PROFILE:-default}"
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

# Export credentials to a file for sourcing
aws_export_to_file() {
  local profile="${1:-$AWS_PROFILE}"
  local output_file="${2:-$HOME/.aws/temp-creds.env}"
  [ -z "$profile" ] && { echo "❌ No profile specified"; return 1; }
  
  echo "📁 Exporting credentials from '$profile' to '$output_file'"
  if ! _aws_test_creds "$profile" > /dev/null; then
    echo "❌ Failed to get credentials. Profile may be expired."
    echo "💡 Try: aws_sso_login $profile"
    return 1
  fi
  
  if local temp_creds=$(aws configure export-credentials --profile "$profile" --format env 2>/dev/null); then
    echo "$temp_creds" > "$output_file"
    echo "✅ Credentials exported to: $output_file"
    echo "💡 To use: source $output_file"
    echo "💡 Or: eval \"\$(cat $output_file)\""
  else
    echo "❌ Failed to export credentials"
    return 1
  fi
}

# Show current AWS identity and profile info
aws_whoami() {
  echo "🔍 Current AWS Configuration:"
  echo "Profile: ${AWS_PROFILE:-default}"
  echo "Region: ${AWS_REGION:-$AWS_DEFAULT_REGION}"
  echo ""
  if aws sts get-caller-identity > /dev/null 2>&1; then
    local identity=$(aws sts get-caller-identity)
    local account=$(echo "$identity" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
    local arn=$(echo "$identity" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
    local user_id=$(echo "$identity" | grep -o '"UserId": "[^"]*"' | cut -d'"' -f4)
    echo "✅ Account: $account"
    echo "👤 User ID: $user_id"
    echo "🎭 ARN: $arn"
  else
    echo "❌ Not authenticated or credentials expired"
    echo "💡 Try: aws_sso_login"
  fi
}

# Clear AWS environment variables
aws_clear() {
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE
  echo "🧹 Cleared AWS environment variables"
}

# List all AWS profiles
aws_list_profiles() {
  echo "📋 Available AWS profiles:"
  aws configure list-profiles | sed 's/^/  /'
}

# ==========================================
# SHORT ALIASES
# ==========================================

# SSO Login aliases
alias awsl='aws_sso_login'                    # Quick SSO login
alias awslp='aws_sso_login production-sso'   # Login to production
alias awsld='aws_sso_login default-sso'      # Login to default/dev
alias awslb='aws_sso_login both'             # Login to both

# Profile switching aliases
alias awsp='aws_profile'                     # Switch profile
alias awspp='aws_profile production-sso'    # Switch to production
alias awspd='aws_profile default-sso'       # Switch to default/dev

# Credential export aliases
alias awse='aws_export_creds'               # Export to env vars
alias awsef='aws_export_to_file'            # Export to file
alias awsec='aws_export_creds && aws_whoami' # Export + show identity

# Utility aliases
alias awsw='aws_whoami'                     # Who am I?
alias awsc='aws_clear'                      # Clear credentials
alias awsls='aws_list_profiles'             # List profiles

# Common AWS commands with current profile
alias awsid='aws sts get-caller-identity'   # Quick identity check
alias awsr='aws configure list'             # Show current config

# ==========================================
# ENVIRONMENT EXPORT HELPERS
# ==========================================

# Export credentials and show copy-paste commands
aws_export_env() {
  local profile="${1:-$AWS_PROFILE}"
  [ -z "$profile" ] && { echo "❌ No profile specified"; return 1; }
  
  echo "🔑 Getting credentials for profile: $profile"
  if ! _aws_test_creds "$profile" > /dev/null; then
    echo "❌ Failed to get credentials. Profile may be expired."
    echo "💡 Try: aws_sso_login $profile"
    return 1
  fi
  
  local temp_creds=$(aws configure export-credentials --profile "$profile" --format env 2>/dev/null)
  if [ -n "$temp_creds" ]; then
    echo ""
    echo "📋 Copy and paste these commands to export credentials:"
    echo "# ===== AWS Credentials for $profile ====="
    echo "$temp_creds"
    echo "# ===== End AWS Credentials ====="
    echo ""
    echo "💡 Or run: awse (alias for aws_export_creds)"
  else
    echo "❌ Failed to get credentials"
    return 1
  fi
}

# Generate .env file for applications
aws_generate_env_file() {
  local profile="${1:-$AWS_PROFILE}"
  local env_file="${2:-.env}"
  [ -z "$profile" ] && { echo "❌ No profile specified"; return 1; }
  
  echo "📝 Generating .env file from profile: $profile"
  if ! _aws_test_creds "$profile" > /dev/null; then
    echo "❌ Failed to get credentials. Profile may be expired."
    echo "💡 Try: aws_sso_login $profile"
    return 1
  fi
  
  local temp_creds=$(aws configure export-credentials --profile "$profile" --format env 2>/dev/null)
  if [ -n "$temp_creds" ]; then
    # Backup existing .env if it exists
    [ -f "$env_file" ] && cp "$env_file" "${env_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    echo "# AWS Credentials - Generated $(date)" > "$env_file"
    echo "$temp_creds" >> "$env_file"
    echo "AWS_REGION=$AWS_REGION" >> "$env_file"
    echo "AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" >> "$env_file"
    
    echo "✅ Generated $env_file with AWS credentials"
    echo "💡 Use with: source $env_file"
  else
    echo "❌ Failed to generate .env file"
    return 1
  fi
}

# Short aliases for env export
alias awsenv='aws_export_env'               # Show export commands
alias awsgen='aws_generate_env_file'        # Generate .env file

EOF

        # Add shell-specific completion
        if [ "$SHELL_NAME" = "bash" ]; then
            cat >> "$SHELL_CONFIG" << 'EOF'
# Enable AWS CLI command completion for bash
if command -v aws_completer &> /dev/null; then
   complete -C aws_completer aws
fi
EOF
        elif [ "$SHELL_NAME" = "zsh" ]; then
            cat >> "$SHELL_CONFIG" << 'EOF'
# Enable AWS CLI command completion for zsh  
if command -v aws_completer &> /dev/null; then
   complete -C aws_completer aws
fi
EOF
        fi
        
        echo "✅ Added AWS SSO functions and aliases to $SHELL_CONFIG"
    fi
else
    echo "⚠️  Could not detect shell configuration file."
    echo "Please manually add the functions to your shell configuration."
    echo "Detected shell: $SHELL_NAME"
fi

echo ""
echo "🎉 AWS SSO setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Reload your shell configuration:"
if [ -n "$SHELL_CONFIG" ]; then
    echo "   source $SHELL_CONFIG"
else
    case "$SHELL_NAME" in
        "bash")
            echo "   source ~/.bashrc  # or ~/.bash_profile on macOS"
            ;;
        "zsh")
            echo "   source ~/.zshrc"
            ;;
        *)
            echo "   source your shell config file"
            ;;
    esac
fi
echo ""
echo "2. Login to AWS SSO:"
echo "   awsl  # or aws_sso_login"
echo ""
echo "3. Test your setup:"
echo "   awsw  # or aws_whoami"
echo ""

# Print comprehensive usage guide
echo "🚀 QUICK REFERENCE:"
echo ""
echo "📱 LOGIN & PROFILES:"
echo "   awsl              # Login to default SSO"
echo "   awslp             # Login to production"
echo "   awsld             # Login to default/dev"
echo "   awslb             # Login to both profiles"
echo "   awsp <profile>    # Switch to profile"
echo "   awspp             # Switch to production"
echo "   awspd             # Switch to default/dev"
echo ""
echo "🔑 CREDENTIAL EXPORT:"
echo "   awse              # Export to environment variables"
echo "   awsef <profile>   # Export profile to file"
echo "   awsenv            # Show export commands to copy/paste"
echo "   awsgen            # Generate .env file"
echo ""
echo "🔍 UTILITIES:"
echo "   awsw              # Who am I? (show current identity)"
echo "   awsc              # Clear all AWS env variables"
echo "   awsls             # List all profiles"
echo "   awsid             # Quick identity check"
echo ""
echo "📋 Available profiles:"
echo "   default-sso, production-sso, staging-sso"
echo "   default, production, staging, prod, dev"
echo ""
echo "ℹ️  Shell detected: $SHELL_NAME"
if [ -n "$SHELL_CONFIG" ]; then
    echo "ℹ️  Config file used: $SHELL_CONFIG"
fi
echo ""
echo "⚠️  Note: You'll need access to the Lightricks AWS SSO portal"
echo "   Contact your admin if you don't have access." 
