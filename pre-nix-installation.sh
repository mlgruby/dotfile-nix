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

# Installation Stages:
# ------------------
# 1. Pre-Installation Checks
#    - Verify macOS environment
#    - Check/Install Xcode tools
#    - Validate system requirements
#
# 2. Package Manager Setup
#    - Install Homebrew if needed
#    - Install git and stow
#    - Configure Nix package manager
#
# 3. Configuration Setup
#    - Clone dotfiles repository
#    - Create directory structure
#    - Install configuration files:
#      * nix.conf → /etc/nix/nix.conf
#      * zshrc → ~/.zshrc
#      * dynamic-config.zsh → ~/.dynamic-config.zsh
#
# 4. System Integration
#    - Setup Git and GitHub
#    - Configure SSH keys
#    - Initialize nix-darwin
#
# 5. Nix-Darwin Installation
#    - Install nix-darwin using the flake configuration
#
# 6. Shell Configuration
#    - Install Zsh if not present
#
# 7. Git and SSH Configuration
#    - Configure Git identity
#    - Set up SSH keys for GitHub
#    - Test GitHub connectivity
#
# 8. Final Configuration
#    - Start nix-daemon
#    - Display help and support information
#    - Display important reminders
#    - Create required symlinks for shell configuration
#
# Related Files:
# -------------
# Core:
# - flake.nix: Main system configuration
# - nix/nix.conf: Nix settings
# - nix/zshrc: Shell configuration
# - nix/dynamic-config.zsh: Shell functions
#
# Support:
# - uninstall.sh: System cleanup
# - README.md: Documentation
# - .gitignore: Repository settings
# - home-manager/shell.nix: Shell environment
#
# Dependencies:
# ------------
# External:
# - Xcode Command Line Tools
# - Homebrew
# - Git
#
# Internal:
# - nix-darwin
# - home-manager
# - flake support

# Exit on any error
set -e

# Function Definitions:
# ------------------
# Utility Functions:
# - command_exists: Check if command is available
# - handle_error: Standardized error handling
#
# Installation Functions:
# 1. Xcode Tools:
#    - Check installation
#    - Install if needed
#    - Verify and repair
#
# 2. Homebrew Setup:
#    - Install Homebrew
#    - Configure PATH
#    - Install dependencies
#
# 3. Nix Installation:
#    - Backup existing configs
#    - Install Nix
#    - Configure multi-user setup
#
# 4. Configuration:
#    - Clone dotfiles
#    - Create symlinks
#    - Setup shell environment

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Utility Functions
# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Error Management
# Error handling function
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

echo -e "${BLUE}Starting pre-installation setup...${NC}"

# System Verification
# Verify macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}This script is only for macOS${NC}"
    exit 1
fi

# Install Xcode Command Line Tools if on macOS
echo -e "${BLUE}Checking for Xcode Command Line Tools...${NC}"
# Check if xcode-select is installed and has a valid path
if ! xcode-select -p &> /dev/null; then
    echo -e "${BLUE}Installing Xcode Command Line Tools...${NC}"
    # Try softwareupdate method first
    softwareupdate --install -a
    
    # If that doesn't work, try xcode-select --install
    if ! xcode-select -p &> /dev/null; then
        xcode-select --install || true
        echo -e "${BLUE}Please complete the installation prompt window${NC}"
        echo -e "${BLUE}Press RETURN when installation is complete...${NC}"
        read
    fi
    
    # Verify installation
    if ! xcode-select -p &> /dev/null; then
        handle_error "Xcode Command Line Tools installation failed. Please try installing manually."
    fi
    
    # Accept license
    echo -e "${BLUE}Accepting Xcode license...${NC}"
    sudo xcodebuild -license accept
    
    echo -e "${GREEN}Xcode Command Line Tools installed successfully!${NC}"
else
    echo -e "${GREEN}Xcode Command Line Tools already installed at: $(xcode-select -p)${NC}"
    # Verify the installation is working
    if ! gcc --version &> /dev/null; then
        echo -e "${RED}Warning: gcc not working, attempting to fix Xcode CLI tools...${NC}"
        sudo rm -rf $(xcode-select -p)
        echo -e "${BLUE}Reinstalling Xcode Command Line Tools...${NC}"
        softwareupdate --install -a
        if ! xcode-select -p &> /dev/null; then
            xcode-select --install || true
            echo -e "${BLUE}Please complete the installation prompt window${NC}"
            echo -e "${BLUE}Press RETURN when installation is complete...${NC}"
            read
        fi
    fi
fi

# Stage 1: Homebrew Installation
if ! command_exists brew; then
    echo -e "${BLUE}Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH immediately
    echo -e "${BLUE}Adding Homebrew to PATH...${NC}"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
    
    echo -e "${GREEN}Homebrew installed successfully${NC}"
    echo -e "${BLUE}Please restart your shell and run this script again to continue with Nix installation.${NC}"
    exit 0
fi

# Install initial required packages via Homebrew
echo -e "${BLUE}Installing initial required packages...${NC}"
brew install git stow
echo -e "${GREEN}Initial packages installed successfully${NC}"

# Stage 2: Nix Installation and Configuration
# -----------------------------------------
# Stage 2: Nix Installation
if ! command_exists nix; then
    echo -e "${BLUE}Installing Nix...${NC}"
    
    # Backup Management
    # Create backups of existing shell configurations
    echo -e "${BLUE}Backing up shell configuration files...${NC}"
    # Handle existing backup files
    for file in /etc/bashrc /etc/zshrc /etc/bash.bashrc ~/.zshrc ~/.bashrc; do
        if [ -f "${file}.backup-before-nix" ]; then
            echo -e "${BLUE}Found existing backup for ${file}${NC}"
            # Verify backup integrity
            echo -e "${BLUE}Checking if backup contains Nix configurations...${NC}"
            if grep -q "nix" "${file}.backup-before-nix"; then
                echo -e "${RED}Warning: Backup file contains Nix configurations${NC}"
                # Create timestamped backups
                echo -e "${BLUE}Creating timestamped backup of both files...${NC}"
                timestamp=$(date +%Y%m%d_%H%M%S)
                sudo cp "$file" "${file}.${timestamp}"
                sudo cp "${file}.backup-before-nix" "${file}.backup-before-nix.${timestamp}"
            else
                echo -e "${BLUE}Restoring original backup...${NC}"
                sudo mv "${file}.backup-before-nix" "$file"
            fi
        fi
        # Create new backups of current files
        if [ -f "$file" ]; then
            sudo cp "$file" "${file}.backup-before-nix"
        fi
    done
    
    # Nix Installation Process
    # Install using multi-user configuration
    sh <(curl -L https://nixos.org/nix/install)
    
    # Post-Installation Verification
    echo -e "${BLUE}Waiting for Nix installation to complete...${NC}"
    sleep 5
    
    # Test Installation
    echo -e "${BLUE}Testing Nix installation...${NC}"
    if ! nix-shell -p neofetch --run neofetch; then
        echo -e "${RED}Nix installation test failed. Please check the error messages above.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Nix installed successfully${NC}"
    echo -e "${BLUE}Please restart your shell and run this script again to continue with nix-darwin installation.${NC}"
    exit 0
fi

# Stage 3: Directory and Dotfiles Setup
# -----------------------------------
# Create necessary directories
echo -e "${BLUE}Creating necessary directories...${NC}"
mkdir -p "$HOME/.config/nix"
mkdir -p "$HOME/.config/darwin"
mkdir -p "$HOME/.config/home-manager"
mkdir -p "$HOME/Documents/dotfile"

# Dotfiles Repository Setup
# Handle repository cloning and configuration
echo -e "${BLUE}Do you want to proceed with dotfiles setup? (y/n)${NC}"
read -r setup_dotfiles
if [[ $setup_dotfiles =~ ^[Yy]$ ]]; then
    # Repository Management
    # Clone or update existing repository
    if [ ! -d "$HOME/Documents/dotfile/.git" ]; then
        echo -e "${BLUE}Enter your dotfiles repository URL:${NC}"
        read -r dotfiles_url
        git clone "$dotfiles_url" "$HOME/Documents/dotfile"
    else
        # Update existing repository
        echo -e "${BLUE}Dotfiles repository already exists. Do you want to pull latest changes? (y/n)${NC}"
        read -r update_dotfiles
        if [[ $update_dotfiles =~ ^[Yy]$ ]]; then
            cd "$HOME/Documents/dotfile"
            git pull
        fi
    fi
    
    cd "$HOME/Documents/dotfile"
    
    # Configuration Verification
    # Verify flake.nix exists
    if [ ! -f "flake.nix" ]; then
        echo -e "${RED}Error: flake.nix not found in repository root${NC}"
        exit 1
    fi

    # Directory Structure Management
    # Move configuration files to correct locations
    if [ -d ".config" ]; then
        echo -e "${BLUE}Moving configuration files to root...${NC}"
        mv .config/darwin ./
        mv .config/home-manager ./
        mv .config/nix ./
        rm -rf .config
    fi

    # Show current structure
    echo -e "${BLUE}Current directory structure:${NC}"
    tree -L 2

    # Symlink Management
    # Cleanup existing symlinks
    echo -e "${BLUE}Cleaning up existing symlinks...${NC}"
    
    # File Cleanup
    # Remove potential conflicting files
    echo -e "${BLUE}Removing existing files...${NC}"
    rm -f "$HOME/.zshrc" "$HOME/.dynamic-config.zsh" "$HOME/.zshenv" "$HOME/.zprofile"
    
    # Symlink Cleanup
    # Remove existing symlinks if they exist
    rm -f "$HOME/.config/nix" "$HOME/.config/darwin" "$HOME/.config/home-manager"
    
    # Directory Preparation
    # Create parent directory
    mkdir -p "$HOME/.config"
    
    # Symlink Creation
    # Create symlinks manually
    echo -e "${BLUE}Creating symlinks...${NC}"
    cd "$HOME/Documents/dotfile"
    for dir in nix darwin home-manager; do
        if [ -d "$dir" ]; then
            ln -sfn "$HOME/Documents/dotfile/$dir" "$HOME/.config/$dir" || handle_error "Failed to create symlink for $dir"
            echo -e "${GREEN}Created symlink for $dir${NC}"
        else
            handle_error "Source directory $dir does not exist"
        fi
    done
    
    # Symlink Verification
    # Verify the links were created correctly
    echo -e "${BLUE}Verifying symlinks...${NC}"
    for dir in nix darwin home-manager; do
        echo -e "${BLUE}Checking $dir...${NC}"
        if [ -L "$HOME/.config/$dir" ]; then
            actual=$(readlink "$HOME/.config/$dir")
            expected="$HOME/Documents/dotfile/$dir"
            if [ "$actual" = "$expected" ]; then
                echo -e "${GREEN}Symlink for $dir created successfully${NC}"
                ls -la "$HOME/.config/$dir"
            else
                echo -e "${RED}Warning: Symlink for $dir points to wrong location${NC}"
                echo -e "${BLUE}Expected: $expected${NC}"
                echo -e "${BLUE}Actual: $actual${NC}"
            fi
        else
            echo -e "${RED}Warning: Symlink for $dir not created${NC}"
            echo -e "${BLUE}Current state of $HOME/.config/$dir:${NC}"
            ls -la "$HOME/.config/$dir" 2>/dev/null || echo "Does not exist"
        fi
    done
    
    # Now install nix-darwin using the flake configuration
    echo -e "${BLUE}Installing nix-darwin...${NC}"
    
    # Flakes Configuration
    # Enable flakes support
    mkdir -p ~/.config/nix
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
    
    # Build System
    # Install and build nix-darwin
    export NIX_CONFIG="experimental-features = nix-command flakes"
    cd "$HOME/Documents/dotfile"  # Change to the directory containing flake.nix
    nix run nix-darwin -- switch --flake .#"$HOSTNAME" || handle_error "Failed to install nix-darwin"
    
    echo -e "${GREEN}nix-darwin installed successfully!${NC}"
    echo -e "${BLUE}You can now use 'cd ~/Documents/dotfile && darwin-rebuild switch --flake .#$HOSTNAME' to update your system${NC}"
fi

# Stage 6: Shell Configuration
# -------------------------
# Install Zsh if not present
if ! command_exists zsh; then
    echo -e "${BLUE}Installing Zsh...${NC}"
    # Check System Zsh
    # Check if zsh is already installed by macOS
    if ! zsh --version >/dev/null 2>&1; then
        brew install zsh
    fi
    
    # Shell Registration
    # Add zsh to /etc/shells if not present
    if ! grep -q "$(which zsh)" /etc/shells; then
        echo -e "${BLUE}Adding Zsh to /etc/shells...${NC}"
        sudo sh -c "echo $(which zsh) >> /etc/shells"
    fi
    echo -e "${GREEN}Zsh installed successfully${NC}"
else
    echo -e "${GREEN}Zsh already installed${NC}"
fi

# Stage 7: Git and SSH Configuration
# -------------------------------
# Setup Git SSH for GitHub
echo -e "${BLUE}Do you want to setup Git SSH for GitHub? (y/n)${NC}"
read -r setup_git_ssh
if [[ $setup_git_ssh =~ ^[Yy]$ ]]; then
    # Get user information
    echo -e "${BLUE}Enter your macOS username (the one you use to log in):${NC}"
    read -r USERNAME
    # Verify username matches the current user
    if [ "$USERNAME" != "$USER" ]; then
        echo -e "${RED}Warning: The username you entered ($USERNAME) doesn't match your current macOS username ($USER)${NC}"
        echo -e "${BLUE}Do you want to continue anyway? (y/n)${NC}"
        read -r continue_anyway
        if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
            echo -e "${RED}Aborting. Please run the script again with your correct macOS username.${NC}"
            exit 1
        fi
    fi
    echo -e "${BLUE}Enter your full name:${NC}"
    read -r FULLNAME
    echo -e "${BLUE}Enter your email:${NC}"
    read -r EMAIL
    echo -e "${BLUE}Enter your GitHub username:${NC}"
    read -r GITHUB_USERNAME
    echo -e "${BLUE}Enter your desired hostname (e.g., macbook-pro):${NC}"
    read -r HOSTNAME

    # Git Configuration
    echo -e "${BLUE}Enter your Git name:${NC}"
    read -r git_name
    echo -e "${BLUE}Enter your Git email:${NC}"
    read -r git_email

    # Configure Git globally
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    
    # Create/Update user-config.nix
    echo -e "${BLUE}Creating user configuration...${NC}"
    cat > user-config.nix << EOF
    {
      username = "$USERNAME";
      fullName = "$FULLNAME";
      email = "$EMAIL";
      githubUsername = "$GITHUB_USERNAME";
      hostname = "$HOSTNAME";
    }
    EOF

    # SSH Key Generation
    # Generate SSH key
    echo -e "${BLUE}Generating SSH key...${NC}"
    ssh-keygen -t ed25519 -C "$git_email" -f "$HOME/.ssh/github"
    
    # SSH Agent Configuration
    # Start ssh-agent and add key
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/github"
    
    # SSH Config Setup
    # Create/update SSH config
    mkdir -p "$HOME/.ssh"
    echo -e "Host github.com\n  AddKeysToAgent yes\n  UseKeychain yes\n  IdentityFile ~/.ssh/github" >> "$HOME/.ssh/config"
    
    # GitHub Integration
    # Display public key and instructions
    echo -e "${GREEN}Your SSH public key:${NC}"
    cat "$HOME/.ssh/github.pub"
    echo -e "${BLUE}Please add this key to your GitHub account:${NC}"
    echo "1. Go to GitHub.com"
    echo "2. Click your profile picture -> Settings"
    echo "3. Click 'SSH and GPG keys' -> 'New SSH key'"
    echo "4. Paste the above key and save"
    
    # User Verification
    # Wait for user to add key to GitHub
    echo -e "${BLUE}Press any key after adding the key to GitHub...${NC}"
    read -n 1 -s
    
    # Connection Test
    # Test SSH connection
    echo -e "${BLUE}Testing GitHub SSH connection...${NC}"
    ssh -T git@github.com
fi

# Stage 8: Final Configuration
# -------------------------
# Start nix-daemon
echo -e "${BLUE}Starting nix-daemon...${NC}"
sudo launchctl kickstart -k system/org.nixos.nix-daemon

echo -e "${GREEN}Nix daemon started successfully!${NC}"
echo -e "${BLUE}Try it! Open a new terminal, and type:${NC}"
echo -e "  $ nix-shell -p nix-info --run \"nix-info -m\""

# Help and Support Information
echo -e "\nThank you for using this installer. If you have any feedback or need"
echo -e "help, don't hesitate:"
echo -e "\nYou can open an issue at"
echo -e "https://github.com/NixOS/nix/issues/new?labels=installer&template=installer.md"
echo -e "\nOr get in touch with the community: https://nixos.org/community"

# Important Reminders
echo -e "\n---- Reminders -----------------------------------------------------------------"
echo -e "[ 1 ]"
echo -e "Nix won't work in active shell sessions until you restart them."

# Final Shell Configuration
# Create required symlinks for shell configuration
# Create symlinks for zsh files
ln -sf "$HOME/Documents/dotfile/nix/dynamic-config.zsh" "$HOME/.dynamic-config.zsh" || handle_error "Failed to create symlink for dynamic-config.zsh"
ln -sf "$HOME/Documents/dotfile/nix/zshrc" "$HOME/.zshrc" || handle_error "Failed to create symlink for zshrc"

# Completion Message
# Final message
echo -e "${GREEN}Pre-installation setup completed!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Open a new terminal window to load all changes"
echo -e "2. Run 'darwin-rebuild switch --flake .#$HOSTNAME' if you make any changes to your configuration"
