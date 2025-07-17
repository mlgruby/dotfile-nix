#!/bin/bash

# SSH Configuration Validator
# This script helps validate and troubleshoot SSH setup for GitHub

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 SSH Configuration Validator${NC}"
echo -e "${BLUE}==============================${NC}"
echo ""

# Check if SSH key exists
echo -e "${BLUE}1. Checking SSH key...${NC}"
if [ -f "$HOME/.ssh/github" ] && [ -f "$HOME/.ssh/github.pub" ]; then
    echo -e "${GREEN}✓ SSH key found at ~/.ssh/github${NC}"
    
    # Check key type
    key_type=$(ssh-keygen -l -f "$HOME/.ssh/github.pub" | awk '{print $4}')
    echo -e "${BLUE}  Key type: $key_type${NC}"
    
    # Check if key is in SSH agent
    if ssh-add -l | grep -q "$(ssh-keygen -l -f "$HOME/.ssh/github.pub" | awk '{print $2}')"; then
        echo -e "${GREEN}✓ SSH key is loaded in SSH agent${NC}"
    else
        echo -e "${YELLOW}⚠ SSH key is not loaded in SSH agent${NC}"
        echo -e "${BLUE}  Run: ssh-add ~/.ssh/github${NC}"
    fi
else
    echo -e "${RED}❌ SSH key not found at ~/.ssh/github${NC}"
    echo -e "${BLUE}  Available SSH keys:${NC}"
    ls -la ~/.ssh/*.pub 2>/dev/null || echo -e "${YELLOW}  No SSH keys found${NC}"
    echo ""
    echo -e "${BLUE}  To fix this, run the scripts/install/pre-nix-installation.sh script${NC}"
    echo -e "${BLUE}  Or create a symlink to an existing key:${NC}"
    echo -e "${BLUE}    ln -sf ~/.ssh/your-key ~/.ssh/github${NC}"
    echo -e "${BLUE}    ln -sf ~/.ssh/your-key.pub ~/.ssh/github.pub${NC}"
fi

echo ""

# Check SSH config
echo -e "${BLUE}2. Checking SSH config...${NC}"
if [ -f "$HOME/.ssh/config" ]; then
    if grep -q "Host github.com" "$HOME/.ssh/config"; then
        echo -e "${GREEN}✓ SSH config contains GitHub configuration${NC}"
        
        # Show the configuration
        echo -e "${BLUE}  GitHub SSH configuration:${NC}"
        awk '/^Host github.com/,/^Host / { if (/^Host / && !/github.com/) exit; print "    " $0 }' "$HOME/.ssh/config"
    else
        echo -e "${YELLOW}⚠ SSH config exists but no GitHub configuration found${NC}"
        echo -e "${BLUE}  Add this to ~/.ssh/config:${NC}"
        echo -e "${BLUE}    Host github.com${NC}"
        echo -e "${BLUE}      AddKeysToAgent yes${NC}"
        echo -e "${BLUE}      UseKeychain yes${NC}"
        echo -e "${BLUE}      IdentityFile ~/.ssh/github${NC}"
    fi
else
    echo -e "${YELLOW}⚠ SSH config file not found${NC}"
    echo -e "${BLUE}  Create ~/.ssh/config with GitHub configuration${NC}"
fi

echo ""

# Test SSH connection to GitHub
echo -e "${BLUE}3. Testing SSH connection to GitHub...${NC}"
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo -e "${GREEN}✓ SSH connection to GitHub successful${NC}"
    # Extract username from the response
    username=$(ssh -T git@github.com 2>&1 | grep "Hi" | cut -d' ' -f2 | tr -d '!')
    echo -e "${BLUE}  Authenticated as: $username${NC}"
else
    echo -e "${RED}❌ SSH connection to GitHub failed${NC}"
    echo -e "${BLUE}  Testing with verbose output...${NC}"
    ssh -vT git@github.com 2>&1 | head -20
    echo ""
    echo -e "${BLUE}  Troubleshooting steps:${NC}"
    echo -e "${BLUE}    1. Check if SSH key is uploaded to GitHub${NC}"
    echo -e "${BLUE}    2. Verify SSH key is loaded: ssh-add -l${NC}"
    echo -e "${BLUE}    3. Test with specific key: ssh -i ~/.ssh/github -T git@github.com${NC}"
fi

echo ""

# Check home-manager SSH configuration
echo -e "${BLUE}4. Checking home-manager SSH configuration...${NC}"
if [ -f "$HOME/.config/home-manager/modules/programs.nix" ]; then
    if grep -q "identityFile.*github" "$HOME/.config/home-manager/modules/programs.nix"; then
        echo -e "${GREEN}✓ home-manager SSH configuration points to ~/.ssh/github${NC}"
    else
        echo -e "${YELLOW}⚠ home-manager SSH configuration may not be configured correctly${NC}"
    fi
else
    echo -e "${YELLOW}⚠ home-manager programs.nix not found${NC}"
fi

# Find dotfiles directory
DOTFILES_DIR=""
for possible_dir in "dotfile" "dotfiles" "nix-config" "nix-darwin" ".dotfiles"; do
    if [ -d "$HOME/Documents/$possible_dir" ]; then
        DOTFILES_DIR="$HOME/Documents/$possible_dir"
        break
    fi
done

echo ""

# Summary and recommendations
echo -e "${BLUE}Summary and Recommendations:${NC}"
echo -e "${BLUE}===========================${NC}"

# Check if everything is working
if [ -f "$HOME/.ssh/github" ] && ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo -e "${GREEN}🎉 SSH setup is working correctly!${NC}"
else
    echo -e "${YELLOW}🔧 SSH setup needs attention:${NC}"
    echo ""
    echo -e "${BLUE}Quick fixes:${NC}"
    
    if [ ! -f "$HOME/.ssh/github" ]; then
        echo -e "${BLUE}  • Create or symlink SSH key to ~/.ssh/github${NC}"
    fi
    
    if ! ssh-add -l | grep -q "$(ssh-keygen -l -f "$HOME/.ssh/github.pub" 2>/dev/null | awk '{print $2}')" 2>/dev/null; then
        echo -e "${BLUE}  • Add key to SSH agent: ssh-add ~/.ssh/github${NC}"
    fi
    
    echo -e "${BLUE}  • Upload public key to GitHub: gh ssh-key add ~/.ssh/github.pub${NC}"
    if [ -n "$DOTFILES_DIR" ]; then
        echo -e "${BLUE}  • Rebuild system: cd $DOTFILES_DIR && sudo darwin-rebuild switch --flake .#\$(hostname -s)${NC}"
    else
        echo -e "${BLUE}  • Rebuild system: cd ~/Documents/[your-dotfiles-dir] && sudo darwin-rebuild switch --flake .#\$(hostname -s)${NC}"
    fi
fi

echo ""
echo -e "${BLUE}For more help, check the documentation or run the scripts/install/pre-nix-installation.sh script${NC}" 
