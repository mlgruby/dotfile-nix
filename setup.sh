#!/bin/bash

# Setup Script for Nix-Darwin Configuration
# ==========================================
# 
# This script downloads and runs the full installation script.
# It's designed to be run with a simple curl command:
#
#   curl -sSL https://raw.githubusercontent.com/mlgruby/dotfile-nix/main/setup.sh | bash
#
# Or downloaded and run locally:
#
#   curl -o setup.sh https://raw.githubusercontent.com/mlgruby/dotfile-nix/main/setup.sh
#   chmod +x setup.sh
#   ./setup.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://raw.githubusercontent.com/mlgruby/dotfile-nix/main"
SCRIPT_NAME="pre-nix-installation.sh"
TEMP_DIR="/tmp/nix-darwin-setup"

# Utility functions
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

handle_error() {
    log_error "$1"
    exit 1
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main setup function
main() {
    echo -e "${BLUE}🚀 Nix-Darwin Setup Bootstrapper${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    
    # System checks
    log_info "Performing system checks..."
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        handle_error "This script is only supported on macOS"
    fi
    
    # Check if curl is available
    if ! command_exists curl; then
        handle_error "curl is required but not installed"
    fi
    
    # Check if we have internet connectivity
    if ! curl -s --head --fail "https://github.com" >/dev/null; then
        handle_error "No internet connection or GitHub is unreachable"
    fi
    
    log_success "System checks passed"
    
    # Create temporary directory
    log_info "Creating temporary directory..."
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Download the installation script
    log_info "Downloading installation script..."
    if curl -sSL "$REPO_URL/$SCRIPT_NAME" -o "$SCRIPT_NAME"; then
        log_success "Installation script downloaded successfully"
    else
        handle_error "Failed to download installation script from $REPO_URL/$SCRIPT_NAME"
    fi
    
    # Verify the script was downloaded and is not empty
    if [[ ! -s "$SCRIPT_NAME" ]]; then
        handle_error "Downloaded script is empty or corrupted"
    fi
    
    # Make the script executable
    log_info "Making script executable..."
    chmod +x "$SCRIPT_NAME"
    
    # Show script info
    log_info "Script information:"
    echo -e "  • Source: $REPO_URL/$SCRIPT_NAME"
    echo -e "  • Size: $(wc -c < "$SCRIPT_NAME") bytes"
    echo -e "  • Lines: $(wc -l < "$SCRIPT_NAME") lines"
    echo ""
    
    # Ask for confirmation
    echo -e "${YELLOW}This script will:${NC}"
    echo -e "  • Install Xcode Command Line Tools"
    echo -e "  • Install Homebrew"
    echo -e "  • Install essential CLI tools"
    echo -e "  • Set up GitHub authentication"
    echo -e "  • Generate/configure SSH keys"
    echo -e "  • Install Nix package manager"
    echo -e "  • Install nix-darwin"
    echo -e "  • Configure your system declaratively"
    echo ""
    
    # Interactive confirmation unless running in CI or with --yes flag
    if [[ "${CI:-false}" == "true" ]] || [[ "$1" == "--yes" ]] || [[ "$1" == "-y" ]]; then
        log_info "Running in non-interactive mode, proceeding automatically..."
    elif [[ ! -t 0 ]]; then
        # Script is being piped, can't read from stdin
        log_warning "Script is being piped, cannot read user input"
        echo -e "${BLUE}To run interactively, download and run locally:${NC}"
        echo -e "${BLUE}  curl -o setup.sh https://raw.githubusercontent.com/mlgruby/dotfile-nix/main/setup.sh${NC}"
        echo -e "${BLUE}  chmod +x setup.sh${NC}"
        echo -e "${BLUE}  ./setup.sh${NC}"
        echo ""
        echo -e "${BLUE}Or continue automatically in 5 seconds (press Ctrl+C to cancel)...${NC}"
        sleep 5
        log_info "Proceeding automatically..."
    else
        echo -e "${BLUE}Do you want to proceed with the installation? (y/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled by user"
            exit 0
        fi
    fi
    
    # Run the installation script
    log_info "Starting installation..."
    echo ""
    
    # Execute the downloaded script
    if bash "$SCRIPT_NAME"; then
        log_success "Installation completed successfully!"
    else
        log_error "Installation failed!"
        log_info "The installation script is available at: $TEMP_DIR/$SCRIPT_NAME"
        log_info "You can inspect it and run it manually if needed"
        exit 1
    fi
    
    # Cleanup
    log_info "Cleaning up temporary files..."
    cd "$HOME"
    rm -rf "$TEMP_DIR"
    
    echo ""
    log_success "Setup complete! 🎉"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "  1. Restart your terminal"
    echo -e "  2. Navigate to your dotfiles directory in ~/Documents/"
    echo -e "  3. Run system rebuild: ${YELLOW}sudo darwin-rebuild switch --flake .#\$(hostname -s)${NC}"
    echo ""
    echo -e "${BLUE}For help and troubleshooting:${NC}"
    echo -e "  • Run the SSH validator: ${YELLOW}./validate-ssh.sh${NC}"
    echo -e "  • Check the documentation"
    echo -e "  • Review the configuration files"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --yes, -y    Skip confirmation prompt"
        echo "  --help, -h   Show this help message"
        echo ""
        echo "This script downloads and runs the Nix-Darwin installation script."
        echo "It will set up a complete declarative macOS development environment."
        exit 0
        ;;
    --version|-v)
        echo "Nix-Darwin Setup Bootstrapper v1.0.0"
        exit 0
        ;;
esac

# Run main function
main "$@"
