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
  services = {
    # SSH Agent for key management
    ssh-agent = {
      enable = true;
    };

    # Redshift for blue light filtering
    redshift = {
      enable = true;
      latitude = 37.7749; # San Francisco coordinates (adjust for your location)
      longitude = -122.4194;
      temperature = {
        day = 6500;
        night = 3500;
      };
      brightness = {
        day = "1.0";
        night = "0.8";
      };
    };

    # Syncthing for file synchronization (optional)
    syncthing = {
      enable = false; # Enable if you want file sync
      tray = {
        enable = false; # Set to true if you want system tray
      };
    };

    # Note: GPG Agent is managed via Homebrew installation
    # Configuration is handled in tool-configs.nix
  };
}
