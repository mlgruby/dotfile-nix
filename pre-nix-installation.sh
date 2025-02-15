#!/bin/bash
#
# Pre-Nix Installation Script
# ==========================
#
# This script automates the setup of a new macOS system with Nix, nix-darwin, and dotfiles.
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

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Error handling function
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

echo -e "${BLUE}Starting pre-installation setup...${NC}"

# Verify macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}This script is only for macOS${NC}"
    exit 1
fi

# Install Xcode Command Line Tools if on macOS
echo -e "${BLUE}Checking for Xcode Command Line Tools...${NC}"
if ! command_exists xcode-select; then
    echo -e "${BLUE}Installing Xcode Command Line Tools...${NC}"
    xcode-select --install
else
    echo -e "${GREEN}Xcode Command Line Tools already installed${NC}"
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

# Stage 2: Nix Installation
if ! command_exists nix; then
    echo -e "${BLUE}Installing Nix...${NC}"
    
    # Backup shell configuration files
    echo -e "${BLUE}Backing up shell configuration files...${NC}"
    # Handle existing backup files
    for file in /etc/bashrc /etc/zshrc /etc/bash.bashrc ~/.zshrc ~/.bashrc; do
        if [ -f "${file}.backup-before-nix" ]; then
            echo -e "${BLUE}Found existing backup for ${file}${NC}"
            echo -e "${BLUE}Checking if backup contains Nix configurations...${NC}"
            if grep -q "nix" "${file}.backup-before-nix"; then
                echo -e "${RED}Warning: Backup file contains Nix configurations${NC}"
                echo -e "${BLUE}Creating timestamped backup of both files...${NC}"
                timestamp=$(date +%Y%m%d_%H%M%S)
                sudo cp "$file" "${file}.${timestamp}"
                sudo cp "${file}.backup-before-nix" "${file}.backup-before-nix.${timestamp}"
            else
                echo -e "${BLUE}Restoring original backup...${NC}"
                sudo mv "${file}.backup-before-nix" "$file"
            fi
        fi
        # Create new backup
        if [ -f "$file" ]; then
            sudo cp "$file" "${file}.backup-before-nix"
        fi
    done
    
    # Install Nix using the recommended multi-user installation
    sh <(curl -L https://nixos.org/nix/install)
    
    # Wait for Nix installation to complete and source profile
    echo -e "${BLUE}Waiting for Nix installation to complete...${NC}"
    sleep 5
    
    # Test Nix installation
    echo -e "${BLUE}Testing Nix installation...${NC}"
    if ! nix-shell -p neofetch --run neofetch; then
        echo -e "${RED}Nix installation test failed. Please check the error messages above.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Nix installed successfully${NC}"
    echo -e "${BLUE}Please restart your shell and run this script again to continue with nix-darwin installation.${NC}"
    exit 0
fi

# Create necessary directories
echo -e "${BLUE}Creating necessary directories...${NC}"
mkdir -p "$HOME/.config/nix"
mkdir -p "$HOME/.config/darwin"
mkdir -p "$HOME/.config/home-manager"
mkdir -p "$HOME/Documents/dotfile"

# Handle dotfiles setup
echo -e "${BLUE}Do you want to proceed with dotfiles setup? (y/n)${NC}"
read -r setup_dotfiles
if [[ $setup_dotfiles =~ ^[Yy]$ ]]; then
    if [ ! -d "$HOME/Documents/dotfile/.git" ]; then
        echo -e "${BLUE}Enter your dotfiles repository URL:${NC}"
        read -r dotfiles_url
        git clone "$dotfiles_url" "$HOME/Documents/dotfile"
    else
        echo -e "${BLUE}Dotfiles repository already exists. Do you want to pull latest changes? (y/n)${NC}"
        read -r update_dotfiles
        if [[ $update_dotfiles =~ ^[Yy]$ ]]; then
            cd "$HOME/Documents/dotfile"
            git pull
        fi
    fi
    
    cd "$HOME/Documents/dotfile"
    
    # Verify flake.nix exists
    if [ ! -f "flake.nix" ]; then
        echo -e "${RED}Error: flake.nix not found in repository root${NC}"
        exit 1
    fi

    # Move files from .config to root if needed
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

    # Cleanup existing symlinks
    echo -e "${BLUE}Cleaning up existing symlinks...${NC}"
    
    # Remove existing files that might conflict
    echo -e "${BLUE}Removing existing files...${NC}"
    rm -f "$HOME/.zshrc" "$HOME/.dynamic-config.zsh" "$HOME/.zshenv" "$HOME/.zprofile"
    
    # Remove existing symlinks if they exist
    rm -f "$HOME/.config/nix" "$HOME/.config/darwin" "$HOME/.config/home-manager"

    # Create parent directory
    mkdir -p "$HOME/.config"

    # Create symlinks manually
    echo -e "${BLUE}Creating symlinks...${NC}"
    cd "$HOME/Documents/dotfile"
    for dir in nix darwin home-manager; do
        if [ -d "$dir" ]; then
            ln -sfn "$HOME/Documents/dotfile/$dir" "$HOME/.config/$dir" || handle_error "Failed to create symlink for $dir"
            echo -e "${GREEN}Created symlink for $dir${NC}"§
        else
            handle_error "Source directory $dir does not exist"
        fi
    done

    # Verify the links were created (with better checking)
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
    
    # Enable flakes
    mkdir -p ~/.config/nix
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
    
    # Install and build nix-darwin
    export NIX_CONFIG="experimental-features = nix-command flakes"
    cd "$HOME/Documents/dotfile"  # Change to the directory containing flake.nix
    nix run nix-darwin -- switch --flake .#ss-mbp || handle_error "Failed to install nix-darwin"
    
    echo -e "${GREEN}nix-darwin installed successfully!${NC}"
    echo -e "${BLUE}You can now use 'cd ~/Documents/dotfile && darwin-rebuild switch --flake .#ss-mbp' to update your system${NC}"
fi

# Install Zsh if not present
if ! command_exists zsh; then
    echo -e "${BLUE}Installing Zsh...${NC}"
    # Check if zsh is already installed by macOS
    if ! zsh --version >/dev/null 2>&1; then
        brew install zsh
    fi
    
    # Add zsh to /etc/shells if not present
    if ! grep -q "$(which zsh)" /etc/shells; then
        echo -e "${BLUE}Adding Zsh to /etc/shells...${NC}"
        sudo sh -c "echo $(which zsh) >> /etc/shells"
    fi
    echo -e "${GREEN}Zsh installed successfully${NC}"
else
    echo -e "${GREEN}Zsh already installed${NC}"
fi

# Setup Git SSH for GitHub
echo -e "${BLUE}Do you want to setup Git SSH for GitHub? (y/n)${NC}"
read -r setup_git_ssh
if [[ $setup_git_ssh =~ ^[Yy]$ ]]; then
    # Configure Git
    echo -e "${BLUE}Enter your Git name:${NC}"
    read -r git_name
    echo -e "${BLUE}Enter your Git email:${NC}"
    read -r git_email
    
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    
    # Generate SSH key
    echo -e "${BLUE}Generating SSH key...${NC}"
    ssh-keygen -t ed25519 -C "$git_email" -f "$HOME/.ssh/github"
    
    # Start ssh-agent and add key
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/github"
    
    # Create/update SSH config
    mkdir -p "$HOME/.ssh"
    echo -e "Host github.com\n  AddKeysToAgent yes\n  UseKeychain yes\n  IdentityFile ~/.ssh/github" >> "$HOME/.ssh/config"
    
    # Display public key and instructions
    echo -e "${GREEN}Your SSH public key:${NC}"
    cat "$HOME/.ssh/github.pub"
    echo -e "${BLUE}Please add this key to your GitHub account:${NC}"
    echo "1. Go to GitHub.com"
    echo "2. Click your profile picture -> Settings"
    echo "3. Click 'SSH and GPG keys' -> 'New SSH key'"
    echo "4. Paste the above key and save"
    
    # Wait for user to add key to GitHub
    echo -e "${BLUE}Press any key after adding the key to GitHub...${NC}"
    read -n 1 -s
    
    # Test SSH connection
    echo -e "${BLUE}Testing GitHub SSH connection...${NC}"
    ssh -T git@github.com
fi

# Start nix-daemon
echo -e "${BLUE}Starting nix-daemon...${NC}"
sudo launchctl kickstart -k system/org.nixos.nix-daemon

echo -e "${GREEN}Nix daemon started successfully!${NC}"
echo -e "${BLUE}Try it! Open a new terminal, and type:${NC}"
echo -e "  $ nix-shell -p nix-info --run \"nix-info -m\""

echo -e "\nThank you for using this installer. If you have any feedback or need"
echo -e "help, don't hesitate:"
echo -e "\nYou can open an issue at"
echo -e "https://github.com/NixOS/nix/issues/new?labels=installer&template=installer.md"
echo -e "\nOr get in touch with the community: https://nixos.org/community"

echo -e "\n---- Reminders -----------------------------------------------------------------"
echo -e "[ 1 ]"
echo -e "Nix won't work in active shell sessions until you restart them."

# Final message
echo -e "${GREEN}Pre-installation setup completed!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Open a new terminal window to load all changes"
echo -e "2. Run 'darwin-rebuild switch --flake .#ss-mbp' if you make any changes to your configuration"

# Create symlinks for zsh files
ln -sf "$HOME/Documents/dotfile/nix/dynamic-config.zsh" "$HOME/.dynamic-config.zsh" || handle_error "Failed to create symlink for dynamic-config.zsh"
ln -sf "$HOME/Documents/dotfile/nix/zshrc" "$HOME/.zshrc" || handle_error "Failed to create symlink for zshrc"
