#!/bin/bash
# Fix Nix installation issues with broken /etc shell configuration symlinks

set -e

echo "🔧 Fixing broken shell configuration symlinks..."

# List of shell config files that might have broken symlinks
SHELL_CONFIGS=("bashrc" "zshrc" "zprofile")

for config in "${SHELL_CONFIGS[@]}"; do
    config_path="/etc/$config"
    
    if [ -L "$config_path" ]; then
        # Check if symlink target exists
        if [ ! -e "$config_path" ]; then
            echo "Removing broken /etc/$config symlink..."
            sudo rm "$config_path"
            
            echo "Creating /etc/$config file..."
            sudo touch "$config_path"
        else
            echo "✅ /etc/$config symlink is working"
        fi
    elif [ ! -f "$config_path" ]; then
        echo "Creating missing /etc/$config file..."
        sudo touch "$config_path"
    else
        echo "✅ /etc/$config already exists"
    fi
done

echo "✅ All shell configuration files fixed!"
echo ""
echo "Now you can run:"
echo "  curl -L https://nixos.org/nix/install | sh"
echo ""
echo "Or use the Determinate installer:"
echo "  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
