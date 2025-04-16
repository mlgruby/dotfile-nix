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
#   - Poetry installation and management
#   - pyenv Python version management
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

{ config, pkgs, lib, userConfig, ... }: {
  # Nix package manager settings

  # Enable Nix daemon
  nix.enable = true;

  # Set correct GID for nixbld group
  ids.gids.nixbld = 350;

  # Required for proper Homebrew installation
  system.activationScripts.preUserActivation.text = ''
    export INSTALLING_HOMEBREW=1
  '';

  # Allow installation of non-free packages
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  # System-wide packages installed via Nix
  environment.systemPackages = [
    # macOS Integration
    # Required for proper system integration
    pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
    pkgs.darwin.apple_sdk.frameworks.CoreServices
    pkgs.darwin.apple_sdk.frameworks.Security
    pkgs.darwin.cctools

    # Core Utilities
    # Essential command-line tools
    pkgs.curl                  # URL data transfer
    pkgs.wget                  # File retrieval
    pkgs.gnutls                # TLS/SSL support
    pkgs.tree                  # Directory visualization

    # Build Environment
    # Required for compiling Python and other software
    pkgs.openssl              # Cryptography
    pkgs.readline             # Line editing
    pkgs.sqlite               # Database
    pkgs.zlib                 # Compression
  ];

  # Application Management
  # Creates aliases in /Applications/Nix Apps for GUI applications
  # This makes apps appear in Spotlight and Finder
  system.activationScripts.applications.text = let
    env = pkgs.buildEnv {
      name = "system-applications";
      paths = config.environment.systemPackages;
      pathsToLink = "/Applications";
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

  # macOS System Preferences
  # Configure system-wide settings and defaults
  system.defaults = {
    # Finder preferences
    finder.FXPreferredViewStyle = "clmv";    # Column view by default
    # Login window settings
    loginwindow.GuestEnabled = false;        # Disable guest account
    # Global system settings
    NSGlobalDomain = {
      AppleICUForce24HourTime = true;        # Use 24-hour time
      AppleInterfaceStyle = "Dark";          # Enable dark mode
      KeyRepeat = 2;                         # Faster key repeat
    };
    dock = {
      # ... your existing settings ...
    };
  };

  # Platform architecture
  # nixpkgs.hostPlatform = "aarch64-darwin";

  # Security Configuration
  # Enable TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;

  # System state version
  system.stateVersion = lib.mkForce 4;

  # AWS Credential Management
  # Sets up scripts and configuration for AWS authentication
  system.activationScripts.aws-cred-setup.text = ''
    # Set up directory structure
    # Create AWS credential management directory
    mkdir -p /opt/aws_cred_copy
    mkdir -p $HOME/.aws
  '';

  home-manager = {
    useGlobalPkgs = true;      # Use system-level packages
    useUserPackages = true;     # Enable user-specific packages
    users.${userConfig.username} = import ../home-manager;
    backupFileExtension = lib.mkForce "bak";
  };

  system.activationScripts.postUserActivation.text = ''
    echo "Setting up development tools..."
    
    # Xcode Command Line Tools Check
    # Required for many development tools
    if ! xcode-select -p &> /dev/null; then
      echo "⚠️  Xcode Command Line Tools not found"
      echo "Please install them using: xcode-select --install"
      exit 1
    else
      echo "✓ Xcode Command Line Tools installed"
    fi
  '';

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
    "Use 'poetry' for project dependencies and 'pyenv' for Python versions"
  ];
}
