# home-manager/modules/services.nix
#
# Background Services Configuration
#
# Purpose:
# - Manages background services via Home Manager
# - Provides system utilities and automation
#
# Services:
# - GPG Agent: Secure key management
# - SSH Agent: SSH key management
# - Redshift: Blue light filter
# - Syncthing: File synchronization
#
# Integration:
# - Works with shell environment
# - Complements system configuration
{...}: {
  # Services configuration
  # Note: Many Home Manager services are Linux-only
  # macOS services are typically managed via system preferences or launchd
  
  # Most services like SSH Agent, Redshift, etc. are handled by macOS natively:
  # - SSH Agent: Managed by macOS Keychain automatically
  # - Blue light filtering: Use macOS Night Shift in System Preferences
  # - File sync: Managed via iCloud, Dropbox, etc.
  # - GPG Agent: Configured via tool-configs.nix for Homebrew GPG installation
  
  # Home Manager services on macOS are limited, so we rely on:
  # 1. System Preferences for system-level settings
  # 2. Homebrew for service management where needed
  # 3. LaunchAgents for custom background tasks
  
  services = {
    # Most services disabled on macOS - use system alternatives
  };
}
