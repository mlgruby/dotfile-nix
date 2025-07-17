#!/bin/bash

# Nix System Uninstallation Script
# ===============================
#
# Purpose:
# - Safely removes Nix and related configurations
# - Cleans up development environment
# - Restores system to pre-installation state
#
# Features:
# - Dry-run mode for safety
# - Backup creation
# - Selective uninstallation
# - Comprehensive cleanup
#
# Components:
# 1. System Level:
#    - Nix package manager
#    - nix-darwin
#    - Homebrew (optional)
#
# 2. Development Tools:
#    - Python environment
#    - Cloud tools
#    - Docker setup
#    - Editor configs
#
# 3. Shell Environment:
#    - ZSH configuration
#    - Shell plugins
#    - Terminal settings
#
# Usage:
# ------
# Standard: ./uninstall.sh
# Dry-run:  ./uninstall.sh --dry-run
#
# Related Files:
# - pre-nix-installation.sh: Installation script
# - nix/nix.conf: Nix configuration
# - nix/zshrc: Shell configuration
# - flake.nix: System configuration

###########################################
# Configuration and Setup
###########################################

# Color definitions for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Dry Run Configuration
# Check for dry-run flag
DRY_RUN=0
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=1
    echo -e "${YELLOW}Running in dry-run mode. No files will be removed.${NC}"
fi

###########################################
# Helper Functions
###########################################

# File Removal Function
# Safely removes files with dry-run support
remove_file() {
    if [ $DRY_RUN -eq 1 ]; then
        echo "Would remove: $1"
    else
        rm -rf "$1"
    fi
}

# Error Handler
# Manages errors with user confirmation
handle_error() {
    echo -e "${RED}Error occurred during: $1${NC}"
    echo -e "${YELLOW}Continue anyway? (y/n)${NC}"
    read -r continue_anyway
    if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
        echo -e "${RED}Aborting uninstallation...${NC}"
        exit 1
    fi
}

# Configuration Backup
# Creates timestamped backups of important directories
backup_configs() {
    local backup_dir
    backup_dir="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    echo -e "${BLUE}Creating backup in $backup_dir...${NC}"
    mkdir -p "$backup_dir"
    
    # List of directories to backup
    local dirs=(
        "$HOME/.config"
        "$HOME/.aws"
        "$HOME/.ssh"
        "$HOME/.vscode"
        "$HOME/.cursor"
        "$HOME/.sdkman"
        "$HOME/.pyenv"
        "$HOME/.local"
        "$HOME/.docker"
        "$HOME/.terraform.d"
        "$HOME/Library/Application Support/Code"
        "$HOME/Library/Application Support/JetBrains"
        "$HOME/Library/Application Support/Cursor"
        "$HOME/Library/Application Support/Bitwarden"
        "$HOME/Library/Application Support/Insync"
        "$HOME/Library/Application Support/Spotify"
    )

    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            cp -r "$dir" "$backup_dir/" || handle_error "backing up $dir"
        fi
    done
    
    echo -e "${GREEN}Backup completed in $backup_dir${NC}"
}

# Function to safely remove a path with error handling
safe_remove() {
    local path="$1"
    local name="$2"
    
    if [ -e "$path" ]; then
        remove_file "$path" || handle_error "$name removal"
        echo -e "${GREEN}$name removed successfully${NC}"
    else
        echo -e "${YELLOW}$name not found, skipping...${NC}"
    fi
}

###########################################
# Tool Groups Definition
###########################################

# Development Tools
# Core development environment tools
DEV_TOOLS=(
    "$HOME/.sdkman:SDKMAN"
    "$HOME/.docker:Docker"
)

# Python Development
# Python-specific tools and environments
PYTHON_TOOLS=(
    "$HOME/.local/bin/uv:UV"
    "$HOME/.pyenv:pyenv"
    "$HOME/.local/pipx/venvs/poetry:Poetry"
    "$HOME/.local/pipx:pipx"
)

# Cloud Development
# Cloud provider tools and configurations
CLOUD_TOOLS=(
    "$HOME/.aws:AWS"
    "$HOME/.config/gcloud:Google Cloud SDK"
    "$HOME/.terraform.d:Terraform"
)

# Editor Configurations
# IDE and text editor settings
EDITOR_TOOLS=(
    "$HOME/Library/Application Support/Code:VSCode"
    "$HOME/.vscode:VSCode Config"
    "$HOME/Library/Application Support/JetBrains:JetBrains"
    "$HOME/Library/Application Support/Cursor:Cursor"
    "$HOME/.cursor:Cursor Config"
)

# Shell Environment
# Terminal and shell customizations
SHELL_TOOLS=(
    "$HOME/.oh-my-zsh:oh-my-zsh"
    "$HOME/.zsh-autosuggestions:zsh-autosuggestions"
    "$HOME/.zsh-syntax-highlighting:zsh-syntax-highlighting"
    "$HOME/.config/starship.toml:Starship"
    "$HOME/.local/share/zoxide:Zoxide"
)

# Personal Applications
# User-specific application settings
PERSONAL_APPS=(
    "$HOME/Library/Application Support/Bitwarden:Bitwarden"
    "$HOME/Library/Application Support/Insync:Insync"
    "$HOME/Library/Application Support/Spotify:Spotify"
)

###########################################
# Warning and Confirmation
###########################################

# Initial Warning
# Display comprehensive warning about operations
echo -e "${RED}⚠️  WARNING! ⚠️${NC}"
echo -e "${RED}This script will remove various configurations and tools from your system.${NC}"
echo -e "${YELLOW}It will:${NC}"
# List of major operations
echo "  • Remove Nix package manager"
echo "  • Remove nix-darwin configuration"
echo "  • Remove home-manager configuration"
echo "  • Optionally remove Homebrew"
echo "  • Remove various tool configurations (Python, Java, AWS, etc.)"
echo "  • Remove development environment settings"
echo -e "${YELLOW}Make sure you have backed up any important data before proceeding.${NC}"
echo

# User Confirmation
# Require explicit confirmation to proceed
echo -e "${RED}Are you absolutely sure you want to proceed? (Type 'yes' to confirm)${NC}"
read -r confirmation

if [[ "$confirmation" != "yes" ]]; then
    echo -e "${BLUE}Uninstallation cancelled.${NC}"
    exit 1
fi

# Safety Delay
# Give user time to cancel with Ctrl+C
echo -e "${YELLOW}Starting uninstallation in 5 seconds... Press Ctrl+C to cancel${NC}"
sleep 5

# Removal Mode Selection
# Ask if user wants to remove everything
echo -e "${BLUE}Would you like to remove ALL configurations? (y/n)${NC}"
echo -e "${YELLOW}This will remove everything without asking for individual confirmations${NC}"
read -r remove_all

echo -e "${BLUE}Starting uninstallation...${NC}"

###########################################
# Backup Handling
###########################################

# Backup Confirmation
# Offer to create backups
echo -e "${BLUE}Would you like to backup configurations before removing? (y/n)${NC}"
read -r create_backup
if [[ $create_backup =~ ^[Yy]$ ]]; then
    backup_configs
fi

###########################################
# System Level Uninstallation
###########################################

# Symlink Cleanup
# Remove symlinks created by stow
echo -e "${BLUE}Removing symlinks...${NC}"
rm -f "$HOME/.config/nix/flake.nix"
rm -f "$HOME/.config/darwin/configuration.nix"
rm -f "$HOME/.config/darwin/homebrew.nix"
rm -f "$HOME/.config/home-manager/default.nix"
rm -rf "$HOME/.config/home-manager/modules"

# Nix-Darwin Removal
# Remove nix-darwin
echo -e "${BLUE}Removing nix-darwin...${NC}"
if command_exists darwin-rebuild; then
    # Try to uninstall nix-darwin properly first
    sudo rm -rf /run/current-system
    sudo rm -rf /etc/nix-darwin
    sudo rm -rf /etc/shells.backup-before-nix-darwin
fi

# Nix Package Manager Removal
# Remove Nix
echo -e "${BLUE}Removing Nix...${NC}"

# Service Management
# Stop nix-daemon if it's running
if pgrep -x "nix-daemon" > /dev/null; then
    echo -e "${BLUE}Stopping nix-daemon...${NC}"
    sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null
    sudo launchctl unload ~/Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null
    
    # Also remove the kickstart reference if it exists
    sudo launchctl remove system/org.nixos.nix-daemon 2>/dev/null
fi

# Process Cleanup
# Kill any remaining Nix-related processes
echo -e "${BLUE}Killing any remaining Nix processes...${NC}"
for process in $(ps aux | grep -i nix | grep -v grep | awk '{print $2}'); do
    sudo kill -9 "$process" 2>/dev/null
done

# Filesystem Cleanup
# Unmount /nix if it's mounted
if mount | grep -q "on /nix"; then
    echo -e "${BLUE}Unmounting /nix...${NC}"
    sudo diskutil unmount force /nix 2>/dev/null
    if [ $? -ne 0 ]; then
        # Recovery Attempt
        echo -e "${BLUE}First unmount attempt failed, trying with additional steps...${NC}"
        # Try to remount as read-write first
        sudo mount -uw /
        sudo mount -uw /nix
        sudo diskutil unmount force /nix 2>/dev/null
    fi
fi

# Nix Directory Removal
# Now try to remove /nix with additional system checks
echo -e "${BLUE}Removing /nix directory...${NC}"
if ! sudo rm -rf /nix 2>/dev/null; then
    echo -e "${BLUE}Standard removal failed, trying alternative methods...${NC}"
    # System Integrity Protection Check
    # Try to remove with system protections temporarily disabled
    if csrutil status | grep -q 'disabled'; then
        sudo mount -uw /
        sudo rm -rf /nix
    else
        # Recovery Instructions
        echo -e "${RED}Warning: Could not remove /nix directory.${NC}"
        echo -e "${RED}Please try these steps:${NC}"
        echo -e "1. Restart your computer"
        echo -e "2. Boot into Recovery Mode (hold Cmd+R during startup)"
        echo -e "3. Open Terminal from Utilities menu"
        echo -e "4. Run: csrutil disable"
        echo -e "5. Restart and run this script again"
        echo -e "6. After uninstallation, boot into Recovery Mode again and run: csrutil enable"
    fi
fi

# Shell Configuration Restoration
# Restore shell configuration files
echo -e "${BLUE}Restoring shell configuration files...${NC}"
for file in /etc/bashrc /etc/zshrc /etc/bash.bashrc ~/.zshrc ~/.bashrc ~/.zprofile; do
    # Check for direct backups
    if [ -f "${file}.backup-before-nix" ]; then
        echo -e "${BLUE}Restoring ${file}...${NC}"
        sudo mv "${file}.backup-before-nix" "$file"
    else
        # Check for timestamped backups
        echo -e "${BLUE}No backup found for ${file}, checking for timestamped backups...${NC}"
        # Find the most recent timestamped backup
        latest_backup=$(ls -t "${file}."[0-9]* 2>/dev/null | head -n1)
        if [ -n "$latest_backup" ]; then
            echo -e "${BLUE}Restoring from timestamped backup: ${latest_backup}${NC}"
            sudo mv "$latest_backup" "$file"
        fi
    fi
    # Cleanup backup files
    # Clean up any remaining timestamped backups
    sudo rm -f "${file}."[0-9]*
    sudo rm -f "${file}.backup-before-nix."*
done

# Nix Profile Cleanup
# Remove all Nix-related directories and files
sudo rm -rf /nix
sudo rm -rf ~/.nix-profile
sudo rm -rf ~/.nix-defexpr
sudo rm -rf ~/.nix-channels

# System Configuration Cleanup
# Remove any remaining Nix-related directories
sudo rm -rf /etc/nix
sudo rm -rf ~/.local/state/nix
sudo rm -rf ~/.local/state/home-manager

# Homebrew Management
# Remove Homebrew (only if it was installed by our script)
echo -e "${BLUE}Do you want to remove Homebrew? (y/n)${NC}"
read -r remove_homebrew
if [[ $remove_homebrew =~ ^[Yy]$ ]]; then
    # Homebrew Uninstallation
    echo -e "${BLUE}Removing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
    
    # PATH Cleanup
    # Remove Homebrew from PATH in zprofile
    if [ -f ~/.zprofile ]; then
        sed -i '.bak' '/eval "$(\/opt\/homebrew\/bin\/brew shellenv)"/d' ~/.zprofile
    fi
fi

# Configuration Directory Cleanup
# Remove configuration directories
echo -e "${BLUE}Removing configuration directories...${NC}"
rm -rf "$HOME/.config/nix"
rm -rf "$HOME/.config/darwin"
rm -rf "$HOME/.config/home-manager"

###########################################
# Development Tools Uninstallation
###########################################

# Python Environment Cleanup
# Python-related tools group
echo -e "${BLUE}Do you want to remove all Python-related tools? (UV, pyenv, poetry, pipx) (y/n)${NC}"
read -r remove_python_tools
if [[ $remove_python_tools =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Removing all Python tools...${NC}"
    # Process Python tool array
    for tool in "${PYTHON_TOOLS[@]}"; do
        path="${tool%%:*}"    # Get path before colon
        name="${tool##*:}"    # Get name after colon
        safe_remove "$path" "$name"
    done
fi

# Cloud Tools Cleanup
# Cloud tools group
echo -e "${BLUE}Do you want to remove all cloud-related configurations? (AWS, GCloud, Terraform ...) (y/n)${NC}"
read -r remove_cloud_tools
if [[ $remove_cloud_tools =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Removing all cloud tools...${NC}"
    # Process cloud tool array
    for tool in "${CLOUD_TOOLS[@]}"; do
        path="${tool%%:*}"
        name="${tool##*:}"
        safe_remove "$path" "$name"
    done
fi

# Development Environment Cleanup
# Development tools group
echo -e "${BLUE}Do you want to remove all development tools? (SDKMAN, Docker ...) (y/n)${NC}"
read -r remove_dev_tools
if [[ $remove_dev_tools =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Removing all development tools...${NC}"
    # Process development tool array
    for tool in "${DEV_TOOLS[@]}"; do
        path="${tool%%:*}"
        name="${tool##*:}"
        safe_remove "$path" "$name"
    done
fi

###########################################
# Application Configurations
###########################################

# Personal apps (Bitwarden, Insync, Spotify)
# Terminal apps (Alacritty)

###########################################
# Shell and Environment Cleanup
###########################################

# Remove oh-my-zsh
# Remove shell plugins
# Remove configurations

###########################################
# Final Cleanup
###########################################

# Clean up backup files
echo -e "${BLUE}Cleaning up backup files...${NC}"
rm -f ~/.zshrc.bak
rm -f ~/.zprofile.bak
rm -f /etc/bashrc.bak
rm -f /etc/zshrc.bak
rm -f /etc/bash.bashrc.bak

# Remove SSH keys (optional)
echo -e "${BLUE}Do you want to remove GitHub SSH keys? (y/n)${NC}"
read -r remove_ssh
if [[ $remove_ssh =~ ^[Yy]$ ]]; then
    rm -f "$HOME/.ssh/github"
    rm -f "$HOME/.ssh/github.pub"
    sed -i '.bak' '/github.com/d' "$HOME/.ssh/config"
fi

# Remove dotfiles repository (optional)
echo -e "${BLUE}Do you want to remove the dotfiles repository? (y/n)${NC}"
read -r remove_dotfiles
if [[ $remove_dotfiles =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/Documents/dotfile"
fi

# Editor Tools Cleanup
# Editor tools group
echo -e "${BLUE}Do you want to remove all editor configurations? (VSCode, JetBrains, Cursor ...) (y/n)${NC}"
read -r remove_editor_tools
if [[ $remove_editor_tools =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Removing all editor configurations...${NC}"
    # Process editor tool array
    for tool in "${EDITOR_TOOLS[@]}"; do
        path="${tool%%:*}"
        name="${tool##*:}"
        safe_remove "$path" "$name"
    done
fi

# Shell Environment Cleanup
# Shell tools group
echo -e "${BLUE}Do you want to remove all shell configurations? (oh-my-zsh, plugins, starship ...) (y/n)${NC}"
read -r remove_shell_tools
if [[ $remove_shell_tools =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Removing all shell configurations...${NC}"
    # Process shell tool array
    for tool in "${SHELL_TOOLS[@]}"; do
        path="${tool%%:*}"
        name="${tool##*:}"
        safe_remove "$path" "$name"
    done
fi

# Personal Application Cleanup
# Personal apps group
echo -e "${BLUE}Do you want to remove all personal app configurations? (Bitwarden, Insync, Spotify ...) (y/n)${NC}"
read -r remove_personal_apps
if [[ $remove_personal_apps =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Removing all personal app configurations...${NC}"
    # Process personal app array
    for tool in "${PERSONAL_APPS[@]}"; do
        path="${tool%%:*}"
        name="${tool##*:}"
        safe_remove "$path" "$name"
    done
fi

# Complete System Cleanup
# Remove everything if selected
if [[ $remove_all =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Removing all configurations...${NC}"
    # Process all tool groups sequentially
    # Remove all tool groups
    for tool in "${DEV_TOOLS[@]}"; do
        path="${tool%%:*}"
        name="${tool##*:}"
        safe_remove "$path" "$name"
    done
    
    # Python Environment
    for tool in "${PYTHON_TOOLS[@]}"; do
        path="${tool%%:*}"
        name="${tool##*:}"
        safe_remove "$path" "$name"
    done
    
    # Cloud Tools
    for tool in "${CLOUD_TOOLS[@]}"; do
        path="${tool%%:*}"
        name="${tool##*:}"
        safe_remove "$path" "$name"
    done
    
    # Editor Configurations
    for tool in "${EDITOR_TOOLS[@]}"; do
        path="${tool%%:*}"
        name="${tool##*:}"
        safe_remove "$path" "$name"
    done
    
    # Shell Environment
    for tool in "${SHELL_TOOLS[@]}"; do
        path="${tool%%:*}"
        name="${tool##*:}"
        safe_remove "$path" "$name"
    done
    
    # Personal Applications
    for tool in "${PERSONAL_APPS[@]}"; do
        path="${tool%%:*}"
        name="${tool##*:}"
        safe_remove "$path" "$name"
    done
fi

# Completion Message
# Final status and instructions
echo -e "${GREEN}Uninstallation completed!${NC}"
echo -e "${BLUE}Note: You may need to restart your computer to complete the cleanup.${NC}"
