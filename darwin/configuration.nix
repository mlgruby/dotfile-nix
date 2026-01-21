# darwin/configuration.nix
#
# Main nix-darwin configuration file that manages system-level settings for macOS.
#
# Purpose:
# - Provides system-wide configuration for macOS
# - Manages development environment setup
# - Handles system activation and initialization
#
# Key components:
# 1. System Configuration:
# - Nix package manager settings and trusted users
# - Performance tuning (jobs and cores)
# - Architecture settings (aarch64-darwin)
# - Security settings (TouchID, sudo)
#
# 2. Package Management:
# - System-wide package installation via Nix
#   - Core system utilities (curl, wget, gnutls)
#   - Python base (python3, pipx)
#   - Build dependencies (openssl, readline, sqlite, zlib)
#   - Cloud platform CLIs (AWS, GCP, Terraform)
#
# 3. macOS Integration:
# System preferences:
# - Dark mode by default
# - 24-hour time format
# - TouchID for sudo
# - Fast key repeat rate
# - Column view in Finder
# - Show hidden files
# - Show path bar and status bar
#
# 4. Development Environment:
# Post-activation scripts:
# - SDKMAN and Java version management
#   - Installs Java 8, 11, 17 (Amazon Corretto)
#   - Sets Java 11 as default
# - Python environment setup
#   - System-wide Python 3.12 via Homebrew
#   - uv for project Python version management
# - AWS credential management
#
# 5. Security:
# - TouchID/password authentication for sudo
# - Secure system defaults
# - Guest login disabled
# - Trusted users configuration
#
# Integration:
# - Works with home-manager for user config
# - Supports Homebrew via homebrew.nix
# - Manages Nix and system packages
#
# Note:
# - Requires Xcode Command Line Tools
# - Some features need manual intervention
# - Check activation script output for status
# - System configuration is validated during build
# - Hostname must be valid (letters, numbers, hyphens only)
{
  config,
  pkgs,
  lib,
  userConfig,
  ...
}: {
  # Nix package manager settings

  # Enable Nix daemon
  nix = {
    enable = true;
    
    # Nix daemon settings following best practices
    settings = {
      # Enable flakes and nix command
      experimental-features = ["nix-command" "flakes"];
      
      # Trusted users for additional rights
      trusted-users = ["${userConfig.username}" "root"];
      
      # Note: auto-optimise-store is disabled as it can corrupt the Nix Store on nix-darwin
      # Using nix.optimise.automatic instead (configured below)
      
      # Build settings for optimal performance
      max-jobs = "auto"; # Use all available logical cores
      cores = 0; # Use all available cores for each job
      
      # Improve build performance with more substituters
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      
      # Trust public keys for binary caches
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    
    # Store optimization (nix-darwin safe alternative to auto-optimise-store)
    optimise.automatic = true;
  };

  # Set correct GID for nixbld group
  ids.gids.nixbld = 350;

  # Allow installation of non-free packages
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  # System-wide packages installed via Nix
  environment.systemPackages = [
    # macOS Integration - REMOVED deprecated Apple SDK frameworks
    # These stubs do nothing and will be removed in Nixpkgs 25.11
    # pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
    # pkgs.darwin.apple_sdk.frameworks.CoreServices
    # pkgs.darwin.apple_sdk.frameworks.Security
    pkgs.darwin.cctools

    # Core Utilities
    # Essential command-line tools
    pkgs.curl # URL data transfer
    pkgs.wget # File retrieval
    pkgs.gnutls # TLS/SSL support
    pkgs.tree # Directory visualization

    # Build Environment
    # Required for compiling Python and other software
    pkgs.openssl # Cryptography
    pkgs.readline # Line editing
    pkgs.sqlite # Database
    pkgs.zlib # Compression
  ];

  # Networking Configuration
  networking = {
    hostName = userConfig.hostname;
    computerName = userConfig.hostname;
    localHostName = userConfig.hostname;
  };

  # Application Management & System Configuration
  # Creates aliases in /Applications/Nix Apps for GUI applications
  # This makes apps appear in Spotlight and Finder
  system = {
    activationScripts = {
      applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = [ "/Applications" ];
        };
      in
        pkgs.lib.mkForce ''
          # Clean up and recreate Nix Apps directory
          echo "setting up /Applications..." >&2
          rm -rf /Applications/Nix\ Apps
          mkdir -p /Applications/Nix\ Apps
          # Create aliases for all Nix-installed applications
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
          while read -r src; do
              app_name=$(basename "$src")
              echo "copying $src" >&2
              ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';

      xcodeCheck.text = ''
        echo "Setting up development tools (Xcode Check)..."

        # Xcode Command Line Tools Check
        # Required for many development tools
        if ! xcode-select -p &> /dev/null; then
          echo "⚠️  Xcode Command Line Tools not found"
          echo "Please install them using: xcode-select --install"
          # Consider if exiting with 1 is appropriate here, or just a warning.
          # For now, let's keep it as an error that halts activation.
          exit 1
        else
          echo "✓ Xcode Command Line Tools installed"
        fi
      '';

      cleanupOldBackups.text = ''
        echo "🧹 Cleaning up old .bak files to prevent conflicts..."
        find /Users/${userConfig.username}/.config -name "*.bak" -type f -delete 2>/dev/null || true
        echo "✓ Old backup files cleaned up"
      '';

      nixDaemonSetup.text = ''
        echo "🔧 Ensuring Nix daemon is properly configured..."
        
        # Check if daemon plist exists
        if [ -f "/Library/LaunchDaemons/org.nixos.nix-daemon.plist" ]; then
          echo "✓ Nix daemon plist found"
          
          # Load the daemon if not already loaded
          if ! sudo launchctl list | grep -q "org.nixos.nix-daemon"; then
            echo "Loading Nix daemon..."
            sudo launchctl load /Library/LaunchDaemons/org.nixos.nix-daemon.plist
          fi
          
          # Enable daemon for automatic startup
          sudo launchctl enable system/org.nixos.nix-daemon 2>/dev/null || true
          
          # Verify daemon is running
          if sudo launchctl list | grep -q "org.nixos.nix-daemon"; then
            echo "✅ Nix daemon is running and configured for auto-start"
          else
            echo "⚠️  Warning: Nix daemon may not be properly configured"
          fi
        else
          echo "⚠️  Warning: Nix daemon plist not found"
        fi
      '';

      setDefaultBrowser.text = ''
        echo "🌐 Setting Google Chrome as default browser..."
        
        # Check if Chrome is installed
        if [ -d "/Applications/Google Chrome.app" ]; then
          # Set Chrome as default browser using defaultbrowser
          # Install defaultbrowser if not present
          if ! command -v defaultbrowser >/dev/null 2>&1; then
            echo "Installing defaultbrowser utility..."
            ${pkgs.curl}/bin/curl -L "https://github.com/kerma/defaultbrowser/releases/latest/download/defaultbrowser" -o /tmp/defaultbrowser
            chmod +x /tmp/defaultbrowser
            sudo mv /tmp/defaultbrowser /usr/local/bin/defaultbrowser
          fi
          
          # Set Chrome as default
          /usr/local/bin/defaultbrowser chrome
          echo "✓ Google Chrome set as default browser"
        else
          echo "⚠️  Google Chrome not found, skipping default browser setup"
          echo "   Chrome will be installed via Homebrew on next rebuild"
        fi
      '';
    };

    # macOS System Preferences
    # Configure system-wide settings and defaults
    defaults = {
      # Finder preferences
      finder.FXPreferredViewStyle = "clmv"; # Column view by default
      # Login window settings
      loginwindow.GuestEnabled = false; # Disable guest account
      # Global system settings
      NSGlobalDomain = {
        AppleICUForce24HourTime = true; # Use 24-hour time
        AppleInterfaceStyle = "Dark"; # Enable dark mode
        KeyRepeat = 2; # Faster key repeat
      };
      dock = {
        # ... your existing settings ...
      };
    };

    # System state version
    stateVersion = lib.mkForce 4;

    # Set the primary user for nix-darwin
    primaryUser = userConfig.username;
  };

  # Platform architecture
  # nixpkgs.hostPlatform = "aarch64-darwin";

  # Security Configuration
  # Enable TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;

  # System Configuration Validation
  # Ensure critical components are properly set up
  assertions = [
    # Verify architecture setting
    {
      assertion = pkgs.system == "aarch64-darwin";
      message = "This configuration is only for Apple Silicon Macs";
    }
    # Verify Nix daemon is enabled
    {
      assertion = config.nix.enable;
      message = "Nix daemon must be enabled for this configuration";
    }
  ];

  # Warning Messages
  # Display important notes during rebuild
  warnings = [
    # Remind about manual steps
    "Remember to run 'xcode-select --install' if building fails"
    # Note about credential management
    "AWS credentials should be managed via the provided scripts"
          # Python environment note
      "Use 'uv' for project dependencies and Python version management"
  ];

  home-manager = {
    useGlobalPkgs = true; # Use system-level packages
    useUserPackages = true; # Enable user-specific packages
    users.${userConfig.username} = import ../home-manager;
    backupFileExtension = lib.mkForce "hm-backup";
  };

  # Stylix System-wide Theming
  # Replaces manual theme configurations across applications
  stylix = {
    enable = true;
    
    # Gruvbox Dark theme (matches your current manual configs)
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
    
    # Generate a simple dark wallpaper from theme colors
    image = config.lib.stylix.pixel "base00";
    
    # Font configuration (Homebrew fonts with minimal Nix packages for Stylix)
    fonts = {
      monospace = {
        # Use minimal Nix package for Stylix compatibility, but rely on Homebrew for actual fonts
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.source-serif;
        name = "Source Serif 4";
      };
    };
  };
}
