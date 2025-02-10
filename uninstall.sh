#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting uninstallation...${NC}"

# Remove symlinks created by stow
echo -e "${BLUE}Removing symlinks...${NC}"
rm -f "$HOME/.config/nix/flake.nix"
rm -f "$HOME/.config/darwin/configuration.nix"
rm -f "$HOME/.config/darwin/homebrew.nix"
rm -f "$HOME/.config/home-manager/default.nix"
rm -rf "$HOME/.config/home-manager/modules"

# Remove nix-darwin
echo -e "${BLUE}Removing nix-darwin...${NC}"
if command_exists darwin-rebuild; then
    # Try to uninstall nix-darwin properly first
    sudo rm -rf /run/current-system
    sudo rm -rf /etc/nix-darwin
    sudo rm -rf /etc/shells.backup-before-nix-darwin
fi

# Remove Nix
echo -e "${BLUE}Removing Nix...${NC}"

# Stop nix-daemon if it's running
if pgrep -x "nix-daemon" > /dev/null; then
    echo -e "${BLUE}Stopping nix-daemon...${NC}"
    sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null
    sudo launchctl unload ~/Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null
    
    # Also remove the kickstart reference if it exists
    sudo launchctl remove system/org.nixos.nix-daemon 2>/dev/null
fi

# Kill any remaining Nix-related processes
echo -e "${BLUE}Killing any remaining Nix processes...${NC}"
for process in $(ps aux | grep -i nix | grep -v grep | awk '{print $2}'); do
    sudo kill -9 "$process" 2>/dev/null
done

# Unmount /nix if it's mounted
if mount | grep -q "on /nix"; then
    echo -e "${BLUE}Unmounting /nix...${NC}"
    sudo diskutil unmount force /nix 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${BLUE}First unmount attempt failed, trying with additional steps...${NC}"
        # Try to remount as read-write first
        sudo mount -uw /
        sudo mount -uw /nix
        sudo diskutil unmount force /nix 2>/dev/null
    fi
fi

# Now try to remove /nix with additional system checks
echo -e "${BLUE}Removing /nix directory...${NC}"
if ! sudo rm -rf /nix 2>/dev/null; then
    echo -e "${BLUE}Standard removal failed, trying alternative methods...${NC}"
    # Try to remove with system protections temporarily disabled
    if csrutil status | grep -q 'disabled'; then
        sudo mount -uw /
        sudo rm -rf /nix
    else
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

# Restore shell configuration files
echo -e "${BLUE}Restoring shell configuration files...${NC}"
for file in /etc/bashrc /etc/zshrc /etc/bash.bashrc ~/.zshrc ~/.bashrc ~/.zprofile; do
    if [ -f "${file}.backup-before-nix" ]; then
        echo -e "${BLUE}Restoring ${file}...${NC}"
        sudo mv "${file}.backup-before-nix" "$file"
    else
        echo -e "${BLUE}No backup found for ${file}, checking for timestamped backups...${NC}"
        # Find the most recent timestamped backup
        latest_backup=$(ls -t "${file}."[0-9]* 2>/dev/null | head -n1)
        if [ -n "$latest_backup" ]; then
            echo -e "${BLUE}Restoring from timestamped backup: ${latest_backup}${NC}"
            sudo mv "$latest_backup" "$file"
        fi
    fi
    # Clean up any remaining timestamped backups
    sudo rm -f "${file}."[0-9]*
    sudo rm -f "${file}.backup-before-nix."*
done

sudo rm -rf /nix
sudo rm -rf ~/.nix-profile
sudo rm -rf ~/.nix-defexpr
sudo rm -rf ~/.nix-channels

# Remove any remaining Nix-related directories
sudo rm -rf /etc/nix
sudo rm -rf ~/.local/state/nix
sudo rm -rf ~/.local/state/home-manager

# Remove Homebrew (only if it was installed by our script)
echo -e "${BLUE}Do you want to remove Homebrew? (y/n)${NC}"
read -r remove_homebrew
if [[ $remove_homebrew =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Removing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
    
    # Remove Homebrew from PATH in zprofile
    if [ -f ~/.zprofile ]; then
        sed -i '.bak' '/eval "$(\/opt\/homebrew\/bin\/brew shellenv)"/d' ~/.zprofile
    fi
fi

# Remove configuration directories
echo -e "${BLUE}Removing configuration directories...${NC}"
rm -rf "$HOME/.config/nix"
rm -rf "$HOME/.config/darwin"
rm -rf "$HOME/.config/home-manager"

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

echo -e "${GREEN}Uninstallation completed!${NC}"
echo -e "${BLUE}Note: You may need to restart your computer to complete the cleanup.${NC}" 
