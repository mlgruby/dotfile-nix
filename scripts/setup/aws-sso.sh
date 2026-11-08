#!/usr/bin/env bash
#
# AWS SSO Setup Script for Non-Nix Users
#
# Canonical Nix users should use home-manager/modules/aws-sso.nix. This script
# exists only for standalone shell environments that do not load Home Manager.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
AWS_SSO_ZSH="$ROOT_DIR/home-manager/scripts/aws-sso.zsh"

echo "🚀 Setting up AWS SSO configuration for Vortexa..."
echo "ℹ️  Nix/Home Manager users already get this from home-manager/modules/aws-sso.nix."

if ! command -v aws &> /dev/null; then
  echo "❌ AWS CLI is not installed. Please install it first:"
  echo "   dotfile: add awscli2 to home-manager/modules/packages/cloud.nix and rebuild"
  exit 1
fi

mkdir -p ~/.aws

if [ -f ~/.aws/config ]; then
  backup_file="$HOME/.aws/config.backup.$(date +%Y%m%d_%H%M%S)"
  cp ~/.aws/config "$backup_file"
  echo "📋 Backed up existing AWS config to: $backup_file"
fi

cat > ~/.aws/config << 'EOF'
# Traditional profiles for Java/Scala applications (no SSO properties)
[default]
region = eu-west-1
output = json

[profile production]
region = eu-west-1
output = json

[profile staging]
region = eu-west-1
output = json

[profile stg]
region = eu-west-1
output = json

[profile prod]
region = eu-west-1
output = json

[profile prd]
region = eu-west-1
output = json

[profile dev]
region = eu-west-1
output = json

[profile develop]
region = eu-west-1
output = json

[profile development]
region = eu-west-1
output = json

[profile root]
region = eu-west-1
output = json

[profile vortexa]
region = eu-west-1
output = json

# SSO profiles for CLI usage
[profile production-sso]
sso_start_url = https://vortexa.awsapps.com/start
sso_region = eu-west-1
sso_account_id = 501857513371
sso_role_name = PMMT
region = eu-west-1
output = json

[profile staging-sso]
sso_start_url = https://vortexa.awsapps.com/start
sso_region = eu-west-1
sso_account_id = 045251666112
sso_role_name = PMMT
region = eu-west-1
output = json

[profile default-sso]
sso_start_url = https://vortexa.awsapps.com/start
sso_region = eu-west-1
sso_account_id = 045251666112
sso_role_name = PMMT
region = eu-west-1
output = json

[profile root-sso]
sso_start_url = https://vortexa.awsapps.com/start
sso_region = eu-west-1
sso_account_id = 874568069660
sso_role_name = PMMT
region = eu-west-1
output = json

[profile vortexa-sso]
sso_start_url = https://vortexa.awsapps.com/start
sso_region = eu-west-1
sso_account_id = 874568069660
sso_role_name = PMMT
region = eu-west-1
output = json
EOF

echo "✅ Created AWS configuration file at ~/.aws/config"

detect_shell_config() {
  local current_shell
  current_shell="$(basename "${SHELL:-zsh}")"
  case "$current_shell" in
    zsh) echo "$HOME/.zshrc" ;;
    bash)
      if [ -f "$HOME/.bash_profile" ]; then
        echo "$HOME/.bash_profile"
      elif [[ "${OSTYPE:-}" == "darwin"* ]]; then
        echo "$HOME/.bash_profile"
      else
        echo "$HOME/.bashrc"
      fi
      ;;
    *) echo "" ;;
  esac
}

SHELL_CONFIG="$(detect_shell_config)"
SHELL_NAME="$(basename "${SHELL:-zsh}")"

if [ -n "$SHELL_CONFIG" ]; then
  echo "🔍 Detected $SHELL_NAME shell, using config file: $SHELL_CONFIG"
  if [ -f "$SHELL_CONFIG" ] && grep -q "aws-sso.zsh" "$SHELL_CONFIG" 2>/dev/null; then
    echo "⚠️  AWS SSO helper source line already exists in $SHELL_CONFIG. Skipping..."
  else
    touch "$SHELL_CONFIG"
    cat >> "$SHELL_CONFIG" << EOF

# AWS SSO Configuration - Added by scripts/setup/aws-sso.sh
export AWS_DEFAULT_REGION="eu-west-1"
export AWS_REGION="eu-west-1"
[ -r "$AWS_SSO_ZSH" ] && source "$AWS_SSO_ZSH"
EOF
    echo "✅ Added AWS SSO helper source line to $SHELL_CONFIG"
  fi
fi

echo ""
echo "🎉 AWS SSO setup complete! Run 'source ${SHELL_CONFIG:-~/.zshrc}' and then 'awsl' to log in."
