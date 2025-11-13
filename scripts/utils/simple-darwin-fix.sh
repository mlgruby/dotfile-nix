#!/bin/bash
# Simple fix for nix-darwin without sudo requirements

set -e

echo "🔧 Enabling Nix experimental features..."

# Enable experimental features
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

# Set for current session
export NIX_CONFIG="experimental-features = nix-command flakes"

# Source Nix environment if available
if [ -f /etc/profile.d/nix.sh ]; then
    source /etc/profile.d/nix.sh
    echo "✅ Sourced Nix environment"
fi

echo "✅ Experimental features enabled!"
echo ""
echo "Testing nix command..."
if nix --version; then
    echo "✅ Nix is working!"
else
    echo "❌ Nix command failed"
    exit 1
fi

echo ""
echo "Now try installing nix-darwin:"
echo "  nix run nix-darwin --extra-experimental-features \"nix-command flakes\" -- switch --flake \".#\$(hostname)\""

