#!/bin/bash
# setup-sops.sh
#
# SOPS Secrets Management Setup
#
# Purpose:
# - Initialize SOPS with your GPG key
# - Create your first encrypted secrets file
# - Guide through the SOPS workflow
#
# Prerequisites:
# - GPG key already set up (use ./setup-gpg-github.sh first)
# - user-config.nix configured with your information

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if user-config.nix exists
    if [[ ! -f "user-config.nix" ]]; then
        log_error "user-config.nix not found! Please create it first."
        exit 1
    fi
    
    # Check if GPG is available
    if ! command -v gpg &> /dev/null; then
        log_error "GPG not found! Please install it: brew install gnupg"
        exit 1
    fi
    
    # Check if SOPS is available
    if ! command -v sops &> /dev/null; then
        log_error "SOPS not found! Please install it: brew install sops"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Get user information
get_user_info() {
    log_step "Getting user information from user-config.nix..."
    
    # Extract email and signing key
    EMAIL=$(grep -o 'email = "[^"]*"' user-config.nix | sed 's/email = "//g' | sed 's/"//g')
    SIGNING_KEY=$(grep -o 'signingKey = "[^"]*"' user-config.nix | sed 's/signingKey = "//g' | sed 's/"//g')
    
    if [[ -z "$EMAIL" ]]; then
        log_error "Could not extract email from user-config.nix"
        exit 1
    fi
    
    if [[ -z "$SIGNING_KEY" ]]; then
        log_warning "No signing key found in user-config.nix"
        log_info "Run ./setup-gpg-github.sh first to set up GPG"
        exit 1
    fi
    
    log_success "Found user info: $EMAIL (GPG: $SIGNING_KEY)"
}

# Setup SOPS configuration
setup_sops_config() {
    log_step "Setting up SOPS configuration..."
    
    # Update .sops.yaml with actual GPG key
    if [[ -f ".sops.yaml" ]]; then
        log_info "Updating .sops.yaml with your GPG key: $SIGNING_KEY"
        sed -i.bak "s/{{ .GPG_KEY_ID }}/$SIGNING_KEY/g" .sops.yaml
        rm -f .sops.yaml.bak
        log_success "Updated .sops.yaml"
    else
        log_error ".sops.yaml not found! Make sure it exists in your dotfiles."
        exit 1
    fi
}

# Create initial secrets file
create_secrets_file() {
    log_step "Creating your first secrets file..."
    
    if [[ -f "secrets.yaml" ]]; then
        log_warning "secrets.yaml already exists"
        read -p "Do you want to recreate it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing secrets.yaml"
            return 0
        fi
    fi
    
    # Create unencrypted secrets template
    cat > secrets.yaml << EOF
# SOPS Secrets File
# This file contains sensitive configuration data
# It will be encrypted automatically by SOPS

# User information (sensitive)
user:
  email: "$EMAIL"
  signing_key: "$SIGNING_KEY"
  full_name: "$(grep -o 'fullName = "[^"]*"' user-config.nix | sed 's/fullName = "//g' | sed 's/"//g')"

# AWS configuration (example)
aws:
  account_production: "384822754266"
  account_staging: "588736812464"
  sso_url: "https://d-90670ca891.awsapps.com/start"

# GitHub configuration (example - add your actual token if needed)
github:
  token: "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  username: "$(grep -o 'githubUsername = "[^"]*"' user-config.nix | sed 's/githubUsername = "//g' | sed 's/"//g')"

# Add more secrets as needed
# database:
#   password: "your-db-password"
# api:
#   key: "your-api-key"
EOF
    
    log_success "Created secrets.yaml template"
}

# Encrypt the secrets file
encrypt_secrets() {
    log_step "Encrypting secrets.yaml..."
    
    log_info "Encrypting with SOPS using GPG key: $SIGNING_KEY"
    
    if sops -e -i secrets.yaml; then
        log_success "Successfully encrypted secrets.yaml"
        log_info "The file is now safe to commit to Git!"
    else
        log_error "Failed to encrypt secrets.yaml"
        exit 1
    fi
}

# Test decryption
test_decryption() {
    log_step "Testing decryption..."
    
    if sops -d secrets.yaml > /dev/null; then
        log_success "Decryption test passed - SOPS is working correctly!"
    else
        log_error "Decryption test failed"
        exit 1
    fi
}

# Show usage instructions
show_usage() {
    echo
    log_success "🎉 SOPS setup completed successfully!"
    echo
    echo -e "${GREEN}Your secrets are now encrypted and ready to use!${NC}"
    echo
    echo -e "${BLUE}Common SOPS commands:${NC}"
    echo -e "  ${YELLOW}sops secrets.yaml${NC}              # Edit secrets (decrypts automatically)"
    echo -e "  ${YELLOW}sops -d secrets.yaml${NC}           # View decrypted content"
    echo -e "  ${YELLOW}sops -e -i secrets.yaml${NC}        # Encrypt in-place (after editing)"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "1. Edit secrets: ${YELLOW}sops secrets.yaml${NC}"
    echo -e "2. Add your actual sensitive data (GitHub tokens, etc.)"
    echo -e "3. Test the system: ${YELLOW}rebuild${NC}"
    echo -e "4. Commit encrypted files: ${YELLOW}git add secrets.yaml .sops.yaml${NC}"
    echo
    echo -e "${BLUE}The encrypted secrets will be automatically decrypted during system builds!${NC}"
    echo
    echo -e "${GREEN}Example: Access secrets in Nix configuration:${NC}"
    echo -e "  ${YELLOW}config.sops.secrets.\"user/email\".path${NC}"
    echo -e "  ${YELLOW}config.sops.secrets.\"github/token\".path${NC}"
    echo
}

# Main function
main() {
    echo -e "${BLUE}=== SOPS Secrets Management Setup ===${NC}"
    echo
    echo -e "${BLUE}This script will:${NC}"
    echo -e "  • Set up SOPS with your GPG key"
    echo -e "  • Create an encrypted secrets file"
    echo -e "  • Test encryption/decryption"
    echo -e "  • Show you how to use SOPS"
    echo
    
    check_prerequisites
    get_user_info
    setup_sops_config
    create_secrets_file
    encrypt_secrets
    test_decryption
    show_usage
}

# Run main function
main "$@"
