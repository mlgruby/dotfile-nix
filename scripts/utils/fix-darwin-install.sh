#!/bin/bash
# Fix nix-darwin installation issues

set -e

echo "🔧 Fixing nix-darwin installation issues..."

# Fix home directory ownership
echo "Fixing home directory ownership..."
sudo chown -R $(whoami):staff $HOME

# Enable experimental features
echo "Enabling Nix experimental features..."
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

# Set for current session
export NIX_CONFIG="experimental-features = nix-command flakes"

# Source Nix environment
if [ -f /etc/profile.d/nix.sh ]; then
    source /etc/profile.d/nix.sh
fi

echo "✅ Fixes applied!"
echo ""
echo "Now try:"
echo "  nix run nix-darwin --extra-experimental-features \"nix-command flakes\" -- switch --flake \".#\$(hostname)\""

