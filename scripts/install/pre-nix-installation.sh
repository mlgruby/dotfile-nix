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
#    curl -o pre-nix-installation.sh <your-repo-raw-url>/scripts/install/pre-nix-installation.sh
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
#   curl -o pre-nix-installation.sh <your-repo-raw-url>/scripts/install/pre-nix-installation.sh
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

normalize_hostname() {
    local raw="$1"

    # Keep only the first label and normalize separators for flake output names.
    raw="${raw%%.*}"
    raw="${raw//_/-}"
    raw=$(echo "$raw" | tr -cd '[:alnum:]-')
    raw=$(echo "$raw" | sed -E 's/-+/-/g; s/^-+//; s/-+$//')

    echo "$raw"
}

is_valid_hostname() {
    [[ "$1" =~ ^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*$ ]]
}

safe_link_config_dir() {
    local dir_name="$1"
    local source_dir="$DOTFILES_PATH/$dir_name"
    local target_dir="$HOME/.config/$dir_name"
    local backup_dir="$HOME/.config-backups/dotfile-install-$BACKUP_TS"

    if [ ! -d "$source_dir" ]; then
        echo -e "${YELLOW}⚠ Directory $dir_name not found in dotfiles, creating minimal structure${NC}"
        mkdir -p "$source_dir"
    fi

    if [ -L "$target_dir" ]; then
        local current_link
        current_link="$(readlink "$target_dir")"
        if [ "$current_link" = "$source_dir" ]; then
            echo -e "${GREEN}✓ $dir_name already linked${NC}"
            return
        fi
    fi

    if [ -e "$target_dir" ] || [ -L "$target_dir" ]; then
        mkdir -p "$backup_dir"
        mv "$target_dir" "$backup_dir/$dir_name"
        echo -e "${YELLOW}⚠ Backed up existing ~/.config/$dir_name to $backup_dir/$dir_name${NC}"
    fi

    ln -sfn "$source_dir" "$target_dir"
    echo -e "${GREEN}✓ Linked $dir_name${NC}"
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
echo -e "${BLUE}Installing: git, tree, stow${NC}"

# Install essential tools that we'll need in later phases
brew install git tree stow

echo -e "${GREEN}✓ Essential tools installed:${NC}"
echo -e "  • git: $(git --version 2>/dev/null || echo 'not found')"
echo -e "  • tree: $(tree --version 2>/dev/null | head -1 || echo 'not found')"
echo -e "  • stow: $(stow --version 2>/dev/null | head -1 || echo 'not found')"

echo -e "${GREEN}✓ Phase 1 Complete: Bootstrap tools are ready!${NC}"

# ================================================================================================
# PHASE 2: USER CONFIGURATION & DOTFILES SETUP
# ================================================================================================
print_phase "2" "USER CONFIGURATION & DOTFILES SETUP"

echo -e "${BLUE}Phase 2 sets up user configuration and dotfiles:${NC}"
echo -e "  • User configuration setup"
echo -e "  • Git configuration"
echo -e "  • Dotfiles repository setup"
echo ""

# 2.1: Get user configuration first (before any git operations)
echo -e "${BLUE}2.1 Setting up user configuration...${NC}"

# Create directories
mkdir -p "$HOME/.config"

# Check for existing dotfiles in common locations
EXISTING_CONFIG=""
for possible_dir in "dotfile" "dotfiles" "nix-config" "nix-darwin" ".dotfiles"; do
    if [ -f "$HOME/Documents/$possible_dir/user-config.nix" ]; then
        EXISTING_CONFIG="$HOME/Documents/$possible_dir"
        break
    fi
done

# Check if we already have a dotfiles repo
if [ -n "$EXISTING_CONFIG" ]; then
    echo -e "${GREEN}✓ Found existing user-config.nix in $EXISTING_CONFIG${NC}"
    cd "$EXISTING_CONFIG"
    
    USERNAME=$(grep -E '^\s*username\s*=' user-config.nix | sed 's/.*"\([^"]*\)".*/\1/')
    FULLNAME=$(grep -E '^\s*fullName\s*=' user-config.nix | sed 's/.*"\([^"]*\)".*/\1/')
    EMAIL=$(grep -E '^\s*email\s*=' user-config.nix | sed 's/.*"\([^"]*\)".*/\1/')
    GITHUB_USERNAME=$(grep -E '^\s*githubUsername\s*=' user-config.nix | sed 's/.*"\([^"]*\)".*/\1/')
    HOSTNAME=$(grep -E '^\s*hostname\s*=' user-config.nix | sed 's/.*"\([^"]*\)".*/\1/')
    
    echo -e "${GREEN}Configuration loaded:${NC}"
    echo -e "  Username: $USERNAME"
    echo -e "  GitHub: $GITHUB_USERNAME"
    echo -e "  Email: $EMAIL"
    
    # Set the dotfiles directory for later use
    DOTFILES_PATH="$EXISTING_CONFIG"
    dotfiles_dir=$(basename "$EXISTING_CONFIG")
    
    # Skip the repository cloning section since we already have it
    SKIP_CLONE=true
else
    echo -e "${BLUE}Setting up new user configuration...${NC}"
    echo -e "${BLUE}Enter your macOS username ($(whoami)):${NC}"
    read -r USERNAME
    USERNAME=${USERNAME:-$(whoami)}
    
    echo -e "${BLUE}Enter your full name:${NC}"
    read -r FULLNAME
    
    echo -e "${BLUE}Enter your email:${NC}"
    read -r EMAIL
    
    echo -e "${BLUE}Enter your GitHub username (default: $USERNAME):${NC}"
    read -r GITHUB_USERNAME
    GITHUB_USERNAME=${GITHUB_USERNAME:-$USERNAME}

    DEFAULT_HOSTNAME=$(scutil --get LocalHostName 2>/dev/null || hostname -s)
    DEFAULT_HOSTNAME=$(normalize_hostname "$DEFAULT_HOSTNAME")
    DEFAULT_HOSTNAME=${DEFAULT_HOSTNAME:-"macbook"}

    echo -e "${BLUE}Enter hostname for this machine (default: $DEFAULT_HOSTNAME):${NC}"
    read -r HOSTNAME
    HOSTNAME=${HOSTNAME:-$DEFAULT_HOSTNAME}
    HOSTNAME=$(normalize_hostname "$HOSTNAME")

    while ! is_valid_hostname "$HOSTNAME"; do
        echo -e "${YELLOW}⚠ Invalid hostname format: $HOSTNAME${NC}"
        echo -e "${BLUE}Use only letters, numbers, and hyphens (e.g., macbook-pro).${NC}"
        echo -e "${BLUE}Enter hostname:${NC}"
        read -r HOSTNAME
        HOSTNAME=$(normalize_hostname "$HOSTNAME")
    done

    echo -e "${BLUE}Using hostname: $HOSTNAME${NC}"
    
    SKIP_CLONE=false
fi

# 2.2: Git Configuration
echo -e "${BLUE}2.2 Setting up Git configuration...${NC}"

# Configure git
git config --global user.name "$FULLNAME"
git config --global user.email "$EMAIL"

echo -e "${GREEN}✓ Git configured${NC}"

# 2.3: Setup Dotfiles Repository
echo -e "${BLUE}2.3 Setting up dotfiles repository...${NC}"

if [ "$SKIP_CLONE" = true ]; then
    echo -e "${GREEN}✓ Using existing dotfiles repository at $DOTFILES_PATH${NC}"
else
    # Ask for directory name
    echo -e "${BLUE}What directory name do you want for your dotfiles? (default: dotfile)${NC}"
    read -r dotfiles_dir
    dotfiles_dir=${dotfiles_dir:-dotfile}

    # Validate directory name (no spaces, special characters, etc.)
    while [[ ! "$dotfiles_dir" =~ ^[a-zA-Z0-9_-]+$ ]]; do
        echo -e "${YELLOW}⚠ Directory name should only contain letters, numbers, hyphens, and underscores${NC}"
        echo -e "${BLUE}Please enter a valid directory name:${NC}"
        read -r dotfiles_dir
        dotfiles_dir=${dotfiles_dir:-dotfile}
    done

    DOTFILES_PATH="$HOME/Documents/$dotfiles_dir"

    if [ ! -d "$DOTFILES_PATH/.git" ]; then
        echo -e "${BLUE}Enter your dotfiles repository URL:${NC}"
        read -r dotfiles_url
        
        if [[ -n "$dotfiles_url" ]]; then
            git clone "$dotfiles_url" "$DOTFILES_PATH"
            echo -e "${GREEN}✓ Dotfiles repository cloned to ~/Documents/$dotfiles_dir${NC}"
        else
            echo -e "${GREEN}✓ Using existing dotfiles directory${NC}"
        fi
    else
        echo -e "${GREEN}✓ Dotfiles repository already exists at ~/Documents/$dotfiles_dir${NC}"
        echo -e "${BLUE}Pull latest changes? (y/n)${NC}"
        read -r pull_changes
        if [[ $pull_changes =~ ^[Yy]$ ]]; then
            cd "$DOTFILES_PATH"
            git pull
            echo -e "${GREEN}✓ Repository updated${NC}"
        fi
    fi
fi

cd "$DOTFILES_PATH"

# 2.4: Create/Update user-config.nix
echo -e "${BLUE}2.4 Creating user configuration file...${NC}"

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
echo -e "${GREEN}✓ Phase 2 Complete: User configuration and dotfiles ready!${NC}"

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
    # Check if /nix exists - if so, try to source it
    if [ -d "/nix" ]; then
        echo -e "${YELLOW}⚠ Nix command not found, but /nix directory exists.${NC}"
        echo -e "${BLUE}Attempting to source Nix profile...${NC}"
        
        if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
            . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
        elif [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
            . "$HOME/.nix-profile/etc/profile.d/nix.sh"
        fi
    fi
fi

if ! command_exists nix; then
    if [ -d "/nix" ]; then
        echo -e "${YELLOW}⚠ /nix directory exists but could not activate nix command.${NC}"
        echo -e "${YELLOW}Assuming Nix is installed but not in PATH. Skipping installation to avoid conflicts.${NC}"
        echo -e "${GREEN}✓ Nix assumed installed (found /nix)${NC}"
    else
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
    fi
else
    echo -e "${GREEN}✓ Nix already installed${NC}"
fi

# 3.2: Directory Structure & Symlinks
echo -e "${BLUE}3.2 Setting up configuration directories...${NC}"

# Prepare backup timestamp for existing config directories.
BACKUP_TS=$(date +%Y%m%d_%H%M%S)
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
    safe_link_config_dir "$dir"
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
if ! command_exists darwin-rebuild; then
    export NIX_CONFIG="experimental-features = nix-command flakes"
    echo -e "${BLUE}Running nix-darwin installation (this may take several minutes)...${NC}"

    # Handle /etc/bashrc conflict
    if [ -f "/etc/bashrc" ]; then
        echo -e "${YELLOW}⚠ Found existing /etc/bashrc. Backing up to /etc/bashrc.before-nix-darwin...${NC}"
        sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
    fi

    # Ensure /etc/synthetic.conf exists
    if [ ! -f "/etc/synthetic.conf" ]; then
        echo -e "${BLUE}Creating empty /etc/synthetic.conf...${NC}"
        sudo touch /etc/synthetic.conf
    fi

    if sudo nix run --extra-experimental-features 'nix-command flakes' nix-darwin -- switch --flake ".#$HOSTNAME"; then
        echo -e "${GREEN}✓ nix-darwin installed successfully${NC}"
    else
        handle_error "nix-darwin installation failed"
    fi
else
    echo -e "${GREEN}✓ nix-darwin already installed${NC}"
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
    ln -sf "$DOTFILES_PATH/nix/zshrc" "$HOME/.zshrc"
    echo -e "${GREEN}✓ Linked .zshrc${NC}"
fi

if [ -f "nix/dynamic-config.zsh" ]; then
    ln -sf "$DOTFILES_PATH/nix/dynamic-config.zsh" "$HOME/.dynamic-config.zsh"
    echo -e "${GREEN}✓ Linked dynamic-config.zsh${NC}"
fi

# 4.2: System Services
echo -e "${BLUE}4.2 Starting system services...${NC}"

if sudo launchctl list | grep -q "org.nixos.nix-daemon"; then
    echo -e "${BLUE}Restarting Nix daemon...${NC}"
    sudo launchctl kickstart -k system/org.nixos.nix-daemon || true
    echo -e "${GREEN}✓ Nix daemon restarted${NC}"
else
    echo -e "${YELLOW}⚠ Nix daemon not running, attempting to load...${NC}"
    if [ -f "/Library/LaunchDaemons/org.nixos.nix-daemon.plist" ]; then
        sudo launchctl load -w /Library/LaunchDaemons/org.nixos.nix-daemon.plist || true
        echo -e "${GREEN}✓ Nix daemon loaded${NC}"
    else
        echo -e "${YELLOW}⚠ Nix daemon plist not found, skipping service start${NC}"
    fi
fi

# 4.3: Final Verification & Information
echo -e "${BLUE}4.3 Final verification...${NC}"

# Test nix
if nix-shell -p hello --run "hello" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Nix is working${NC}"
else
    echo -e "${YELLOW}⚠ Nix test failed, but installation may still be successful${NC}"
fi

# Test git configuration
if git config --global user.name >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Git configuration working${NC}"
else
    echo -e "${YELLOW}⚠ Git configuration may need adjustment${NC}"
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
echo -e "  ✓ Essential CLI tools (git, tree, stow)"
echo -e "  ✓ Git configuration"
echo -e "  ✓ Nix package manager"
echo -e "  ✓ nix-darwin system configuration"
echo -e "  ✓ Configuration symlinks"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. ${YELLOW}Restart your terminal${NC} to load all changes"
echo -e "  2. Run: ${YELLOW}cd $DOTFILES_PATH && sudo darwin-rebuild switch --flake .#$HOSTNAME${NC}"
echo -e "  3. Customize your configuration in ${YELLOW}$DOTFILES_PATH/${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo -e "  • Update system: ${YELLOW}sudo darwin-rebuild switch --flake .#$HOSTNAME${NC}"
echo -e "  • Update packages: ${YELLOW}cd $DOTFILES_PATH && nix flake update${NC}"
echo -e "  • Check system info: ${YELLOW}nix-shell -p nix-info --run 'nix-info -m'${NC}"
echo ""
echo -e "${GREEN}Enjoy your declaratively configured Mac! 🚀${NC}"
