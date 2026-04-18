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
# - Architecture settings (aarch64-darwin)
# - Hostname and user wiring
# - Security settings (TouchID, sudo)
#
# 2. Package Management:
# - System-wide package installation via Nix
#   - Core system utilities (curl, wget, gnutls)
#   - Build dependencies (openssl, readline, sqlite, zlib)
#
# 3. macOS Integration:
# - TouchID for sudo
# - Nix application aliases in /Applications/Nix Apps
#
# 4. Development Environment:
# Post-activation scripts:
# - Xcode Command Line Tools validation
# - Default browser setup
#
# 5. Security:
# - TouchID/password authentication for sudo
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
}:
{
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
      applications.text =
        let
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

      setDefaultBrowser.text = ''
        echo "🌐 Setting Google Chrome as default browser..."

        if ! [ -d "/Applications/Google Chrome.app" ]; then
          echo "⚠️  Google Chrome not found, skipping default browser setup"
          echo "   Chrome will be installed via Homebrew on next rebuild"
        elif command -v defaultbrowser >/dev/null 2>&1; then
          defaultbrowser chrome
          echo "✓ Google Chrome set as default browser"
        else
          echo "⚠️  defaultbrowser utility not found, skipping default browser setup"
          echo "   Install it separately if you want rebuilds to set the default browser"
        fi
      '';
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
