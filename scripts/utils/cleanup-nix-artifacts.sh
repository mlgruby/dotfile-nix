#!/bin/bash
# Clean up artifacts from previous Nix installations

set -e

echo "🧹 Cleaning up previous Nix installation artifacts..."

# Backup current files first (safety measure)
BACKUP_DIR="$HOME/nix-cleanup-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "📁 Creating safety backup in: $BACKUP_DIR"

# Backup any existing shell configs
for file in /etc/bashrc /etc/zshrc /etc/zprofile; do
    if [ -f "$file" ] || [ -L "$file" ]; then
        echo "Backing up $file..."
        sudo cp "$file" "$BACKUP_DIR/$(basename "$file")" 2>/dev/null || true
    fi
done

# Backup existing backup files
for file in /etc/*.backup-before-nix* /etc/profile.d/*.backup-before-nix*; do
    if [ -f "$file" ]; then
        echo "Backing up $file..."
        sudo cp "$file" "$BACKUP_DIR/$(basename "$file")" 2>/dev/null || true
    fi
done

# Backup Nix-related files in profile.d
for file in /etc/profile.d/*nix*; do
    if [ -f "$file" ]; then
        echo "Backing up $file..."
        sudo cp "$file" "$BACKUP_DIR/$(basename "$file")" 2>/dev/null || true
    fi
done

echo "✅ Safety backup complete"

# Remove old backup files
echo "🗑️ Removing old Nix backup files..."
sudo rm -f /etc/*.backup-before-nix*
sudo rm -f /etc/*backup-before-nix.old
sudo rm -f /etc/profile.d/*.backup-before-nix*
sudo rm -f /etc/profile.d/*backup-before-nix.old

# Remove broken symlinks and create proper files
SHELL_CONFIGS=("bashrc" "zshrc" "zprofile")

for config in "${SHELL_CONFIGS[@]}"; do
    config_path="/etc/$config"
    
    echo "Processing /etc/$config..."
    
    # Remove if it's a broken symlink
    if [ -L "$config_path" ] && [ ! -e "$config_path" ]; then
        echo "  Removing broken symlink..."
        sudo rm "$config_path"
    fi
    
    # Create empty file if it doesn't exist
    if [ ! -f "$config_path" ]; then
        echo "  Creating empty file..."
        sudo touch "$config_path"
    fi
    
    echo "  ✅ /etc/$config ready"
done

# Clean up any remaining Nix artifacts
echo "🧼 Cleaning up other Nix artifacts..."

# Remove Nix daemon if it exists
if [ -f "/Library/LaunchDaemons/org.nixos.nix-daemon.plist" ]; then
    echo "Stopping and removing Nix daemon..."
    sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
    sudo rm -f /Library/LaunchDaemons/org.nixos.nix-daemon.plist
fi

# Remove Nix from shells (if present)
for shell_rc in ~/.bashrc ~/.zshrc ~/.bash_profile ~/.zprofile; do
    if [ -f "$shell_rc" ] && grep -q "nix" "$shell_rc" 2>/dev/null; then
        echo "Cleaning Nix references from $shell_rc..."
        sed -i.bak '/nix/d' "$shell_rc" 2>/dev/null || true
    fi
done

# Remove Nix directories if they exist
if [ -d "/nix" ]; then
    echo "Removing /nix directory..."
    sudo rm -rf /nix
fi

# Remove user Nix files
rm -rf ~/.nix-profile ~/.nix-defexpr ~/.nix-channels 2>/dev/null || true

# Remove Nix files from profile.d
echo "Removing Nix files from /etc/profile.d/..."
sudo rm -f /etc/profile.d/*nix*

echo ""
echo "✅ Cleanup complete!"
echo "📁 Safety backup saved to: $BACKUP_DIR"
echo ""
echo "Now you can run a fresh Nix installation:"
echo "  curl -L https://nixos.org/nix/install | sh"
echo ""
echo "Or use the Determinate installer:"
echo "  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
