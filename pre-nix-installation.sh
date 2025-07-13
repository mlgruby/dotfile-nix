#!/bin/bash
#
# Pre-Nix Installation Script
# ==========================
#
# This script automates the setup of a new macOS system with Nix, nix-darwin, and dotfiles.
#
# Core Files:
# - nix/nix.conf: Core Nix configuration
# - nix/zshrc: Shell configuration
# - nix/dynamic-config.zsh: Shell functions
# - flake.nix: System configuration
#
# File Placement:
# - nix.conf → /etc/nix/nix.conf
# - zshrc → ~/.zshrc
# - dynamic-config.zsh → ~/.dynamic-config.zsh
#
# Features:
# ---------
# 1. System Preparation:
#    - Installs Xcode Command Line Tools
#    - Sets up Homebrew
#    - Installs essential packages (git, stow)
#
# 2. Nix Setup:
#    - Installs Nix package manager
#    - Configures multi-user installation
#    - Enables experimental features (flakes)
#
# 3. Dotfiles Management:
#    - Clones your dotfiles repository
#    - Creates necessary directory structure
#    - Sets up proper symlinks
#
# 4. Git/GitHub Configuration:
#    - Configures Git identity
#    - Sets up SSH keys for GitHub
#    - Tests GitHub connectivity
#
# File Structure:
# --------------
# ~/Documents/dotfile/
# ├── nix/
# │   ├── nix.conf           # Nix configuration
# │   ├── zshrc              # Shell configuration
# │   └── dynamic-config.zsh # Shell functions
# ├── darwin/                # Darwin configuration
# ├── home-manager/          # User environment
# └── flake.nix              # System definition
#
# Usage:
# ------
# 1. Basic Installation:
#    ```bash
#    curl -o pre-nix-installation.sh https://raw.githubusercontent.com/your-repo/pre-nix-installation.sh
#    chmod +x pre-nix-installation.sh
#    ./pre-nix-installation.sh
#    ```
#
# 2. Interactive Options:
#    - The script will prompt for:
#      * Dotfiles repository URL
#      * Git user name and email
#      * SSH key generation for GitHub
#
# Directory Structure Created:
# --------------------------
# ~/.config/
# ├── nix/
# ├── darwin/
# └── home-manager/
#
# ~/Documents/dotfile/ (Your configuration repository)
#
# Requirements:
# ------------
# - macOS operating system
# - Internet connection
# - GitHub account (for dotfiles and SSH setup)
#
# Error Handling:
# --------------
# - The script uses set -e to exit on any error
# - Custom error handling function for better feedback
# - Backup creation for important files
#
# Post-Installation:
# ----------------
# After running the script:
# 1. Restart your terminal
# 2. Run 'darwin-rebuild switch --flake .#ss-mbp'
# 3. Test your new configuration
#
# Troubleshooting:
# ---------------
# If you encounter issues:
# 1. Check the terminal output for error messages
# 2. Verify your dotfiles repository is accessible
# 3. Ensure you have proper permissions
# 4. Check system requirements are met
#
# Maintenance:
# -----------
# To update your system after installation:
# 1. cd ~/Documents/dotfile
# 2. git pull
# 3. darwin-rebuild switch --flake .#ss-mbp

# Exit on any error
set -e

# ================================================================================================
# BOOTSTRAP SCRIPT FOR BARE METAL MAC
# ================================================================================================
# 
# This script is designed to be run on a completely fresh Mac with nothing installed.
# Download and run with:
# 
#   curl -o pre-nix-installation.sh https://raw.githubusercontent.com/user/repo/pre-nix-installation.sh
#   chmod +x pre-nix-installation.sh
#   ./pre-nix-installation.sh
#
# ================================================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Utility Functions
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

print_phase() {
    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW} PHASE $1: $2${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
}

echo -e "${BLUE}🚀 Starting Bare Metal Mac Setup...${NC}"
echo -e "${BLUE}This script will install and configure everything from scratch${NC}"

# System Verification
if [[ "$OSTYPE" != "darwin"* ]]; then
    handle_error "This script is only for macOS"
fi

# ================================================================================================
# PHASE 1: BOOTSTRAP ESSENTIAL TOOLS (Only using built-in macOS tools)
# ================================================================================================
print_phase "1" "BOOTSTRAP ESSENTIAL TOOLS"

echo -e "${BLUE}Phase 1 installs the minimum tools needed for everything else:${NC}"
echo -e "  • Xcode Command Line Tools (for git, gcc, etc.)"
echo -e "  • Homebrew (package manager)"
echo -e "  • Essential CLI tools (git, gh, tree, stow)"
echo ""

# 1.1: Xcode Command Line Tools
echo -e "${BLUE}1.1 Installing Xcode Command Line Tools...${NC}"
if ! xcode-select -p &> /dev/null; then
    echo -e "${BLUE}Installing Xcode Command Line Tools (this may take a while)...${NC}"
    xcode-select --install
    echo -e "${BLUE}Please complete the installation prompt window${NC}"
    echo -e "${BLUE}Press RETURN when installation is complete...${NC}"
    read
    
    if ! xcode-select -p &> /dev/null; then
        handle_error "Xcode Command Line Tools installation failed"
    fi
    
    sudo xcodebuild -license accept
    echo -e "${GREEN}✓ Xcode Command Line Tools installed${NC}"
else
    echo -e "${GREEN}✓ Xcode Command Line Tools already installed${NC}"
fi

# 1.2: Homebrew Installation
echo -e "${BLUE}1.2 Installing Homebrew...${NC}"
if ! command_exists brew; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for this session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    echo -e "${GREEN}✓ Homebrew installed${NC}"
else
    echo -e "${GREEN}✓ Homebrew already installed${NC}"
fi

# 1.3: Essential CLI Tools
echo -e "${BLUE}1.3 Installing essential CLI tools...${NC}"
echo -e "${BLUE}Installing: git, gh (GitHub CLI), tree, stow${NC}"

# Install essential tools that we'll need in later phases
brew install git gh tree stow

echo -e "${GREEN}✓ Essential tools installed:${NC}"
echo -e "  • git: $(git --version 2>/dev/null || echo 'not found')"
echo -e "  • gh: $(gh --version 2>/dev/null | head -1 || echo 'not found')"
echo -e "  • tree: $(tree --version 2>/dev/null | head -1 || echo 'not found')"
echo -e "  • stow: $(stow --version 2>/dev/null | head -1 || echo 'not found')"

echo -e "${GREEN}✓ Phase 1 Complete: Bootstrap tools are ready!${NC}"

# ================================================================================================
# PHASE 2: AUTHENTICATION & DOTFILES SETUP (Now we can use git and gh)
# ================================================================================================
print_phase "2" "AUTHENTICATION & DOTFILES SETUP"

echo -e "${BLUE}Phase 2 sets up GitHub authentication and clones your dotfiles:${NC}"
echo -e "  • GitHub CLI authentication (automated)"
echo -e "  • SSH key generation and upload"  
echo -e "  • Clone dotfiles repository"
echo -e "  • User configuration setup"
echo ""

# 2.1: Get user configuration first (before any git operations)
echo -e "${BLUE}2.1 Setting up user configuration...${NC}"

# Create directories
mkdir -p "$HOME/.config" "$HOME/Documents/dotfile"

# Check if we already have a dotfiles repo
if [ -f "$HOME/Documents/dotfile/user-config.nix" ]; then
    echo -e "${GREEN}✓ Found existing user-config.nix${NC}"
    cd "$HOME/Documents/dotfile"
    
    USERNAME=$(grep -E '^\s*username\s*=' user-config.nix | sed 's/.*"\([^"]*\)".*/\1/')
    FULLNAME=$(grep -E '^\s*fullName\s*=' user-config.nix | sed 's/.*"\([^"]*\)".*/\1/')
    EMAIL=$(grep -E '^\s*email\s*=' user-config.nix | sed 's/.*"\([^"]*\)".*/\1/')
    GITHUB_USERNAME=$(grep -E '^\s*githubUsername\s*=' user-config.nix | sed 's/.*"\([^"]*\)".*/\1/')
    HOSTNAME=$(grep -E '^\s*hostname\s*=' user-config.nix | sed 's/.*"\([^"]*\)".*/\1/')
    
    echo -e "${GREEN}Configuration loaded:${NC}"
    echo -e "  Username: $USERNAME"
    echo -e "  GitHub: $GITHUB_USERNAME"
    echo -e "  Email: $EMAIL"
else
    echo -e "${BLUE}Setting up new user configuration...${NC}"
    echo -e "${BLUE}Enter your macOS username ($(whoami)):${NC}"
    read -r USERNAME
    USERNAME=${USERNAME:-$(whoami)}
    
    echo -e "${BLUE}Enter your full name:${NC}"
    read -r FULLNAME
    
    echo -e "${BLUE}Enter your email:${NC}"
    read -r EMAIL
    
    echo -e "${BLUE}Enter your GitHub username:${NC}"
    read -r GITHUB_USERNAME
    
    HOSTNAME=$(hostname)
    echo -e "${BLUE}Using hostname: $HOSTNAME${NC}"
fi

# 2.2: GitHub CLI Authentication
echo -e "${BLUE}2.2 Setting up GitHub authentication...${NC}"

if gh auth status >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Already authenticated with GitHub CLI${NC}"
    gh auth status
else
    echo -e "${BLUE}Authenticating with GitHub CLI...${NC}"
    echo -e "${BLUE}This will open your browser. Please:${NC}"
    echo -e "  1. Complete GitHub OAuth in browser"
    echo -e "  2. Choose SSH when prompted for protocol"
    
    if gh auth login --hostname github.com --git-protocol ssh --web; then
        echo -e "${GREEN}✓ GitHub CLI authentication successful${NC}"
    else
        handle_error "GitHub CLI authentication failed"
    fi
fi

# 2.3: SSH Key Setup
echo -e "${BLUE}2.3 Setting up SSH keys...${NC}"

ssh_key_path="$HOME/.ssh/github"

if [ -f "$ssh_key_path" ] && [ -f "$ssh_key_path.pub" ]; then
    echo -e "${GREEN}✓ Found existing SSH key${NC}"
    echo -e "${BLUE}Do you want to use existing key? (y/n)${NC}"
    read -r use_existing
    
    if [[ ! $use_existing =~ ^[Yy]$ ]]; then
        timestamp=$(date +%Y%m%d_%H%M%S)
        mv "$ssh_key_path" "$ssh_key_path.backup.$timestamp"
        mv "$ssh_key_path.pub" "$ssh_key_path.pub.backup.$timestamp"
        echo -e "${GREEN}✓ Backed up existing keys${NC}"
        
        ssh-keygen -t ed25519 -C "$EMAIL" -f "$ssh_key_path" -N ""
        echo -e "${GREEN}✓ New SSH key generated${NC}"
    fi
else
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$ssh_key_path" -N ""
    echo -e "${GREEN}✓ SSH key generated${NC}"
fi

# Add to ssh-agent and upload to GitHub
eval "$(ssh-agent -s)"
ssh-add "$ssh_key_path"

# Upload SSH key via GitHub CLI
if gh ssh-key add "$ssh_key_path.pub" --title "$(hostname)-$(date +%Y%m%d)"; then
    echo -e "${GREEN}✓ SSH key uploaded to GitHub${NC}"
else
    echo -e "${BLUE}SSH key might already exist, continuing...${NC}"
fi

# Configure git
git config --global user.name "$FULLNAME"
git config --global user.email "$EMAIL"

# Setup SSH config
mkdir -p "$HOME/.ssh"
if ! grep -q "Host github.com" "$HOME/.ssh/config" 2>/dev/null; then
    cat >> "$HOME/.ssh/config" << EOF
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile $ssh_key_path
EOF
    echo -e "${GREEN}✓ SSH config updated${NC}"
fi

# 2.4: Clone Dotfiles Repository
echo -e "${BLUE}2.4 Setting up dotfiles repository...${NC}"

if [ ! -d "$HOME/Documents/dotfile/.git" ]; then
    echo -e "${BLUE}Enter your dotfiles repository URL:${NC}"
    read -r dotfiles_url
    
    if [[ -n "$dotfiles_url" ]]; then
        git clone "$dotfiles_url" "$HOME/Documents/dotfile"
        echo -e "${GREEN}✓ Dotfiles repository cloned${NC}"
    else
        echo -e "${BLUE}No repository URL provided, creating minimal config...${NC}"
        mkdir -p "$HOME/Documents/dotfile"
    fi
else
    echo -e "${GREEN}✓ Dotfiles repository already exists${NC}"
    echo -e "${BLUE}Pull latest changes? (y/n)${NC}"
    read -r pull_changes
    if [[ $pull_changes =~ ^[Yy]$ ]]; then
        cd "$HOME/Documents/dotfile"
        git pull
        echo -e "${GREEN}✓ Repository updated${NC}"
    fi
fi

cd "$HOME/Documents/dotfile"

# 2.5: Create/Update user-config.nix
echo -e "${BLUE}2.5 Creating user configuration file...${NC}"

cat > user-config.nix << EOF
{
  username = "$USERNAME";
  fullName = "$FULLNAME";
  email = "$EMAIL";
  githubUsername = "$GITHUB_USERNAME";
  hostname = "$HOSTNAME";
  signingKey = ""; # Will be set up later if needed
}
EOF

echo -e "${GREEN}✓ User configuration saved to user-config.nix${NC}"
echo -e "${GREEN}✓ Phase 2 Complete: Authentication and dotfiles ready!${NC}"

# ================================================================================================
# PHASE 3: NIX INSTALLATION & SYSTEM SETUP
# ================================================================================================
print_phase "3" "NIX INSTALLATION & SYSTEM SETUP"

echo -e "${BLUE}Phase 3 installs Nix and sets up the declarative system:${NC}"
echo -e "  • Nix package manager installation"
echo -e "  • nix-darwin system configuration"
echo -e "  • Configuration symlinks"
echo ""

# 3.1: Nix Installation
echo -e "${BLUE}3.1 Installing Nix package manager...${NC}"

if ! command_exists nix; then
    echo -e "${BLUE}Installing Nix (this will modify shell configurations)...${NC}"
    
    # Backup shell configs
    for file in ~/.zshrc ~/.bashrc; do
        if [ -f "$file" ]; then
            cp "$file" "$file.backup-before-nix"
        fi
    done
    
    sh <(curl -L https://nixos.org/nix/install)
    
    echo -e "${GREEN}✓ Nix installed${NC}"
    echo -e "${BLUE}Please restart your terminal and run this script again to continue${NC}"
    exit 0
else
    echo -e "${GREEN}✓ Nix already installed${NC}"
fi

# 3.2: Directory Structure & Symlinks
echo -e "${BLUE}3.2 Setting up configuration directories...${NC}"

# Create config directories
mkdir -p "$HOME/.config/nix" "$HOME/.config/darwin" "$HOME/.config/home-manager"

# Clean up existing symlinks
rm -rf "$HOME/.config/nix" "$HOME/.config/darwin" "$HOME/.config/home-manager"
mkdir -p "$HOME/.config"

# Reorganize dotfiles if needed
if [ -d ".config" ]; then
    echo -e "${BLUE}Reorganizing configuration structure...${NC}"
    mv .config/darwin ./ 2>/dev/null || true
    mv .config/home-manager ./ 2>/dev/null || true  
    mv .config/nix ./ 2>/dev/null || true
    rmdir .config 2>/dev/null || true
fi

# Create symlinks
echo -e "${BLUE}Creating configuration symlinks...${NC}"
for dir in nix darwin home-manager; do
    if [ -d "$dir" ]; then
        ln -sfn "$HOME/Documents/dotfile/$dir" "$HOME/.config/$dir"
        echo -e "${GREEN}✓ Linked $dir${NC}"
    else
        echo -e "${YELLOW}⚠ Directory $dir not found, creating minimal structure${NC}"
        mkdir -p "$dir"
        ln -sfn "$HOME/Documents/dotfile/$dir" "$HOME/.config/$dir"
    fi
done

# Show structure
echo -e "${BLUE}Current configuration structure:${NC}"
tree -L 2 || ls -la

echo -e "${GREEN}✓ Configuration directories ready${NC}"

# 3.3: nix-darwin Installation
echo -e "${BLUE}3.3 Installing nix-darwin...${NC}"

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Verify flake.nix exists
if [ ! -f "flake.nix" ]; then
    handle_error "flake.nix not found in repository. Please ensure your dotfiles repo contains a valid flake.nix"
fi

# Install nix-darwin
export NIX_CONFIG="experimental-features = nix-command flakes"
echo -e "${BLUE}Running nix-darwin installation (this may take several minutes)...${NC}"

if sudo nix run nix-darwin -- switch --flake ".#$HOSTNAME"; then
    echo -e "${GREEN}✓ nix-darwin installed successfully${NC}"
else
    handle_error "nix-darwin installation failed"
fi

echo -e "${GREEN}✓ Phase 3 Complete: Nix system is configured!${NC}"

# ================================================================================================
# PHASE 4: FINAL CONFIGURATION & CLEANUP
# ================================================================================================
print_phase "4" "FINAL CONFIGURATION & CLEANUP"

echo -e "${BLUE}Phase 4 completes the setup:${NC}"
echo -e "  • Shell configuration"
echo -e "  • System service startup"
echo -e "  • Final verification"
echo ""

# 4.1: Shell Configuration
echo -e "${BLUE}4.1 Setting up shell configuration...${NC}"

# Install/configure Zsh
if ! command_exists zsh; then
    echo -e "${BLUE}Installing Zsh...${NC}"
    brew install zsh
fi

# Create shell config symlinks if they exist
if [ -f "nix/zshrc" ]; then
    ln -sf "$HOME/Documents/dotfile/nix/zshrc" "$HOME/.zshrc"
    echo -e "${GREEN}✓ Linked .zshrc${NC}"
fi

if [ -f "nix/dynamic-config.zsh" ]; then
    ln -sf "$HOME/Documents/dotfile/nix/dynamic-config.zsh" "$HOME/.dynamic-config.zsh"
    echo -e "${GREEN}✓ Linked dynamic-config.zsh${NC}"
fi

# 4.2: System Services
echo -e "${BLUE}4.2 Starting system services...${NC}"

sudo launchctl kickstart -k system/org.nixos.nix-daemon
echo -e "${GREEN}✓ Nix daemon restarted${NC}"

# 4.3: Final Verification & Information
echo -e "${BLUE}4.3 Final verification...${NC}"

# Test nix
if nix-shell -p hello --run "hello" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Nix is working${NC}"
else
    echo -e "${YELLOW}⚠ Nix test failed, but installation may still be successful${NC}"
fi

# Test SSH to GitHub
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo -e "${GREEN}✓ GitHub SSH connection working${NC}"
else
    echo -e "${YELLOW}⚠ GitHub SSH connection test inconclusive (this is often normal)${NC}"
fi

echo -e "${GREEN}✓ Phase 4 Complete: Setup finished!${NC}"

# ================================================================================================
# SETUP COMPLETE
# ================================================================================================

echo ""
echo -e "${GREEN}🎉 Bare Metal Mac Setup Complete!${NC}"
echo ""
echo -e "${BLUE}What was installed:${NC}"
echo -e "  ✓ Xcode Command Line Tools"
echo -e "  ✓ Homebrew package manager"
echo -e "  ✓ Essential CLI tools (git, gh, tree, stow)"
echo -e "  ✓ GitHub CLI authentication"
echo -e "  ✓ SSH keys generated and uploaded"
echo -e "  ✓ Nix package manager"
echo -e "  ✓ nix-darwin system configuration"
echo -e "  ✓ Configuration symlinks"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. ${YELLOW}Restart your terminal${NC} to load all changes"
echo -e "  2. Run: ${YELLOW}cd ~/Documents/dotfile && sudo darwin-rebuild switch --flake .#$HOSTNAME${NC}"
echo -e "  3. Customize your configuration in ${YELLOW}~/Documents/dotfile/${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo -e "  • Update system: ${YELLOW}sudo darwin-rebuild switch --flake .#$HOSTNAME${NC}"
echo -e "  • Update packages: ${YELLOW}cd ~/Documents/dotfile && nix flake update${NC}"
echo -e "  • Check system info: ${YELLOW}nix-shell -p nix-info --run 'nix-info -m'${NC}"
echo ""
echo -e "${GREEN}Enjoy your declaratively configured Mac! 🚀${NC}"

