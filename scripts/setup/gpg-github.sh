#!/bin/bash
# setup-gpg-github.sh
#
# Automated GPG Key Setup for GitHub
#
# This script will:
# 1. Check if GPG key already exists
# 2. Generate a new GPG key if needed
# 3. Upload the public key to GitHub via gh CLI
# 4. Update user-config.nix with the key ID
# 5. Rebuild the configuration
#
# Prerequisites:
# - gh CLI installed (already in homebrew.nix)
# - user-config.nix file exists
# - GitHub authentication via gh CLI

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if required files exist
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if user-config.nix exists
    if [[ ! -f "user-config.nix" ]]; then
        log_error "user-config.nix not found! Please create it from user-config.template.nix first."
        exit 1
    fi
    
    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) not found! Please install it via Homebrew."
        exit 1
    fi
    
    # Check if gpg is available
    if ! command -v gpg &> /dev/null; then
        log_error "GPG not found! Please install it via Homebrew."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Extract user information from user-config.nix
extract_user_info() {
    log_info "Extracting user information from user-config.nix..."
    
    # Extract full name
    FULL_NAME=$(grep -o 'fullName = "[^"]*"' user-config.nix | sed 's/fullName = "//g' | sed 's/"//g')
    
    # Extract email
    EMAIL=$(grep -o 'email = "[^"]*"' user-config.nix | sed 's/email = "//g' | sed 's/"//g')
    
    # Extract existing signing key (if any)
    EXISTING_KEY=$(grep -o 'signingKey = "[^"]*"' user-config.nix | sed 's/signingKey = "//g' | sed 's/"//g') || true
    
    if [[ -z "$FULL_NAME" || -z "$EMAIL" ]]; then
        log_error "Could not extract full name or email from user-config.nix"
        exit 1
    fi
    
    log_success "User info extracted: $FULL_NAME <$EMAIL>"
}

# Check if GPG key already exists
check_existing_gpg_key() {
    log_info "Checking for existing GPG keys..."
    
    # Check if we have any secret keys for this email
    if gpg --list-secret-keys --keyid-format LONG | grep -q "$EMAIL"; then
        GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep "sec.*rsa4096" | cut -d'/' -f2 | cut -d' ' -f1)
        log_success "Found existing GPG key: $GPG_KEY_ID"
        return 0
    else
        log_warning "No existing GPG key found for $EMAIL"
        return 1
    fi
}

# Generate new GPG key
generate_gpg_key() {
    log_info "Generating new GPG key for $EMAIL..."
    
    # Create GPG key generation config
    cat > /tmp/gpg_gen_config <<EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $FULL_NAME
Name-Email: $EMAIL
Expire-Date: 0
%no-protection
%commit
%echo GPG key generated successfully
EOF
    
    # Generate the key
    gpg --batch --generate-key /tmp/gpg_gen_config
    
    # Clean up temp file
    rm -f /tmp/gpg_gen_config
    
    # Get the new key ID
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep "sec.*rsa4096" | cut -d'/' -f2 | cut -d' ' -f1)
    
    log_success "GPG key generated successfully: $GPG_KEY_ID"
}

# Check GitHub authentication
check_github_auth() {
    log_info "Checking GitHub authentication..."
    
    if ! gh auth status &> /dev/null; then
        log_warning "Not authenticated with GitHub. Please run 'gh auth login' first."
        read -p "Would you like to authenticate now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gh auth login
        else
            log_error "GitHub authentication required. Please run 'gh auth login' and try again."
            exit 1
        fi
    fi
    
    log_success "GitHub authentication confirmed"
}

# Check if GPG key already exists on GitHub
check_github_gpg_key() {
    log_info "Checking if GPG key already exists on GitHub..."
    
    # Check if key exists on GitHub
    if gh api user/gpg_keys | jq -r '.[].key_id' | grep -q "$GPG_KEY_ID"; then
        log_success "GPG key already exists on GitHub"
        return 0
    else
        log_warning "GPG key not found on GitHub"
        return 1
    fi
}

# Upload GPG key to GitHub
upload_gpg_key() {
    log_info "Uploading GPG key to GitHub..."
    
    # Export the public key
    PUBLIC_KEY=$(gpg --armor --export "$GPG_KEY_ID")
    
    # Create a temporary file for the key
    TEMP_KEY_FILE=$(mktemp)
    echo "$PUBLIC_KEY" > "$TEMP_KEY_FILE"
    
    # Upload to GitHub
    if gh api user/gpg_keys --method POST -F armored_public_key=@"$TEMP_KEY_FILE" -f name="Auto-generated GPG key" > /dev/null; then
        log_success "GPG key uploaded to GitHub successfully"
    else
        log_error "Failed to upload GPG key to GitHub"
        rm -f "$TEMP_KEY_FILE"
        exit 1
    fi
    
    # Clean up
    rm -f "$TEMP_KEY_FILE"
}

# Update user-config.nix with GPG key ID
update_user_config() {
    log_info "Updating user-config.nix with GPG key ID..."
    
    # Check if signingKey is already set
    if [[ -n "$EXISTING_KEY" && "$EXISTING_KEY" != "" ]]; then
        log_warning "signingKey already set to: $EXISTING_KEY"
        if [[ "$EXISTING_KEY" == "$GPG_KEY_ID" ]]; then
            log_success "signingKey already correctly set"
            return 0
        else
            read -p "Replace existing key ID with new one? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Keeping existing key ID"
                return 0
            fi
        fi
    fi
    
    # Update the signing key in user-config.nix
    sed -i.bak "s/signingKey = \"[^\"]*\"/signingKey = \"$GPG_KEY_ID\"/" user-config.nix
    
    log_success "Updated user-config.nix with GPG key ID: $GPG_KEY_ID"
}

# Rebuild the configuration
rebuild_config() {
    log_info "Rebuilding Darwin configuration..."
    
    if darwin-rebuild switch --flake . &> /dev/null; then
        log_success "Darwin configuration rebuilt successfully"
    else
        log_error "Failed to rebuild Darwin configuration"
        log_info "You may need to run 'darwin-rebuild switch --flake .' manually"
        exit 1
    fi
}

# Test GPG signing
test_gpg_signing() {
    log_info "Testing GPG signing..."
    
    # Test GPG signing
    if echo "test" | gpg --clearsign --default-key "$GPG_KEY_ID" > /dev/null 2>&1; then
        log_success "GPG signing test passed"
    else
        log_error "GPG signing test failed"
        exit 1
    fi
    
    # Test git signing configuration
    if git config --get commit.gpgsign | grep -q "true"; then
        log_success "Git signing is enabled"
    else
        log_warning "Git signing is not enabled - configuration may need rebuild"
    fi
}

# Main function
main() {
    echo -e "${BLUE}=== Automated GPG Setup for GitHub ===${NC}"
    echo
    
    # Check prerequisites
    check_prerequisites
    
    # Extract user information
    extract_user_info
    
    # Check for existing GPG key
    if check_existing_gpg_key; then
        log_info "Using existing GPG key: $GPG_KEY_ID"
    else
        # Generate new GPG key
        generate_gpg_key
    fi
    
    # Check GitHub authentication
    check_github_auth
    
    # Check if key exists on GitHub
    if check_github_gpg_key; then
        log_info "GPG key already exists on GitHub"
    else
        # Upload GPG key to GitHub
        upload_gpg_key
    fi
    
    # Update user configuration
    update_user_config
    
    # Rebuild configuration
    rebuild_config
    
    # Test GPG signing
    test_gpg_signing
    
    echo
    log_success "GPG setup completed successfully!"
    echo
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Make a test commit: git commit -m 'Test GPG signing'"
    echo "2. Push to GitHub: git push origin main"
    echo "3. Check GitHub for the 'Verified' badge"
    echo "4. Your GPG key ID is: $GPG_KEY_ID"
    echo
}

# Run main function
main "$@" 