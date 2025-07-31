#!/bin/bash
# Check Nix daemon status and start if needed
# Usage: ./scripts/utils/check-nix-daemon.sh

echo "🔍 Checking Nix daemon status..."

# Check if daemon is running
if sudo launchctl list | grep -q "org.nixos.nix-daemon"; then
    daemon_status=$(sudo launchctl list | grep "org.nixos.nix-daemon")
    echo "✅ Nix daemon is loaded: $daemon_status"
    
    # Test if Nix actually works
    if nix --version > /dev/null 2>&1; then
        echo "✅ Nix is working: $(nix --version)"
    else
        echo "❌ Nix daemon is loaded but not responding"
        echo "🔄 Attempting to restart..."
        sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist
        sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist
    fi
else
    echo "❌ Nix daemon is not running"
    echo "🔄 Starting Nix daemon..."
    sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist
    sudo launchctl enable system/org.nixos.nix-daemon
fi

echo ""
echo "📋 Current Nix services status:"
sudo launchctl list | grep nix

echo ""
echo "🔧 If daemon doesn't start automatically after reboot, run:"
echo "   sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist"
echo "   sudo launchctl enable system/org.nixos.nix-daemon"