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
# System Configuration:
# - Nix package manager settings and trusted users
# - Performance tuning (jobs and cores)
# - Architecture settings (aarch64-darwin)
# - Security settings (TouchID, sudo)
#
# Package Management:
# - System-wide package installation via Nix
#   - Core system utilities (curl, wget, gnutls)
#   - Python base (python3, pipx)
#   - Build dependencies (openssl, readline, sqlite, zlib)
#   - Cloud platform CLIs (AWS, GCP, Terraform)
#
# Development Environment:
# Post-activation scripts:
# - SDKMAN and Java version management
#   - Installs Java 8, 11, 17 (Amazon Corretto)
#   - Sets Java 11 as default
# - Python environment setup
#   - Poetry installation and management
#   - pyenv Python version management
# - AWS credential management
#
# macOS Integration:
# System preferences:
# - Dark mode
# - 24-hour time
# - TouchID for sudo
# - Application aliases in /Applications/Nix Apps
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

{ config, pkgs, lib, ... }: {
  # Nix package manager settings
  nix = {
    settings = {
      # Performance tuning
      max-jobs = 6;             # Number of parallel jobs (adjust based on CPU)
      cores = 2;                # Cores per job (total = max-jobs * cores)
      # Enable flakes and new CLI
      experimental-features = [ "nix-command" "flakes" ];
      # System administrators and trusted users
      trusted-users = [ "@admin" "satyasheel" ];
    };
  };

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

  # Enable and configure zsh
  programs.zsh.enable = true;

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
  security.pam.enableSudoTouchIdAuth = true;

  # System state version
  system.stateVersion = lib.mkForce 4;

  # AWS Credential Management
  # Sets up scripts and configuration for AWS authentication
  system.activationScripts.aws-cred-setup.text = ''
    # Set up directory structure
    # Create AWS credential management directory
    mkdir -p /opt/aws_cred_copy
    mkdir -p $HOME/.aws
    
    # Environment Cleanup Script
    # Create the unset script
    cat > /opt/aws_cred_copy/copy_and_unset << 'EOF'
    #!/bin/bash
    # Clear all AWS-related environment variables
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    unset AWS_SECURITY_TOKEN
    unset AWS_PROFILE
    unset AWS_DEFAULT_PROFILE
    EOF
    
    chmod +x /opt/aws_cred_copy/copy_and_unset
    
    # AWS Region Configuration
    # Create AWS config file with default region
    cat > $HOME/.aws/config << 'EOF'
    [default]
    region = us-west-2
    output = json
    
    [profile prod]
    region = us-west-2
    output = json
    EOF
    
    # Credential Management Script
    # Create the Python script for credential management
    cat > /opt/aws_cred_copy/copy_credentials_from_env << 'EOF'
    #!/usr/bin/env python3
    import sys
    import os
    import configparser
    
    # Default to 'default' profile if none specified
    profile = "default"
    if len(sys.argv)> 1:
        profile = sys.argv[1]
    
    # Verify required environment variables exist
    if not os.environ.get('AWS_ACCESS_KEY_ID'):
        print("No keys found on env. exit")
        exit(1)
    
    # Update credentials file with current environment
    HOME = os.environ['HOME']
    config = configparser.ConfigParser()
    config.read(f'{HOME}/.aws/credentials')
    config[profile] = {'aws_access_key_id': os.environ['AWS_ACCESS_KEY_ID'],
                      'aws_secret_access_key': os.environ['AWS_SECRET_ACCESS_KEY'],
                      'aws_session_token': os.environ['AWS_SESSION_TOKEN']}
    
    # Write updated credentials and clean environment
    with open(f'{HOME}/.aws/credentials', 'w') as configfile:
        config.write(configfile)
    
    del os.environ['AWS_ACCESS_KEY_ID']
    del os.environ['AWS_SECRET_ACCESS_KEY']
    del os.environ['AWS_SESSION_TOKEN']
    print(f"Updated profile {profile} on ~/.aws/credentials")
    EOF
    
    chmod +x /opt/aws_cred_copy/copy_credentials_from_env
  '';

  home-manager = {
    useGlobalPkgs = true;      # Use system-level packages
    useUserPackages = true;     # Enable user-specific packages
    users.satyasheel = import ../home-manager;
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
    
    # Java Development Environment Setup
    # Install and configure SDKMAN for Java version management
    if [ ! -d "$HOME/.sdkman" ]; then
      # Initial SDKMAN installation
      echo "Installing SDKMAN..."
      TMPFILE=$(mktemp)
      ${pkgs.curl}/bin/curl -s "https://get.sdkman.io" > "$TMPFILE"
      # Configure SDKMAN environment
      export SDKMAN_DIR="$HOME/.sdkman"
      export sdkman_auto_answer=true           # Skip interactive prompts
      export sdkman_selfupdate_feature=false   # Disable auto-updates
      export SDKMAN_BASH_COMPLETION=false      # Skip completion setup
      # Ensure required tools are in PATH for installation
      PATH="${pkgs.unzip}/bin:${pkgs.zip}/bin:${pkgs.gnutar}/bin:${pkgs.curl}/bin:${pkgs.gnused}/bin:$PATH" bash "$TMPFILE" || true
      rm "$TMPFILE"
    fi
    
    # Java Version Management
    # Install and configure multiple Java versions via SDKMAN
    if [ -d "$HOME/.sdkman" ]; then
      echo "Installing Java versions..."
      # Set up SDKMAN environment
      export SDKMAN_DIR="$HOME/.sdkman"
      export SDKMAN_BASH_COMPLETION=false
      
      # Disable shellcheck warning about not following the source
      # shellcheck disable=SC1090,SC1091
      source "$HOME/.sdkman/bin/sdkman-init.sh" 2>/dev/null || true
      
      # Helper function for Java installation
      # Checks if version exists before installing
      install_java_version() {
        if [ ! -d "$HOME/.sdkman/candidates/java/$1" ]; then
          echo "Installing Java $1"
          sdk install java "$1" || echo "Failed to install Java $1"
        else
          echo "Java $1 is already installed"
        fi
      }

      # Install required Java versions
      # Amazon Corretto distributions for AWS compatibility
      install_java_version "8.0.392-amzn"     # Java 8 LTS
      install_java_version "11.0.21-amzn"     # Java 11 LTS (Default)
      install_java_version "17.0.9-amzn"      # Java 17 LTS
      
      # Set Java 11 as the default version
      # Required for most current applications
      if sdk current java 2>/dev/null | grep -q "11.0.21-amzn"; then
        echo "Java 11 is already default"
      else
        echo "Setting Java 11 as default"
        sdk default java "11.0.21-amzn"
      fi
    fi

    # Python Development Environment
    # Configure Poetry and pyenv for Python version management
    echo "Setting up Python environment..."
    
    # Poetry Package Manager Setup
    # Install specific version for compatibility
    POETRY_PATH="$HOME/.local/bin/poetry"
    if [ ! -f "$POETRY_PATH" ] || ! "$POETRY_PATH" --version | grep -q "1.5.1"; then
      echo "Installing Poetry 1.5.1..."
      export PATH="$HOME/.local/bin:$PATH"
      # Install via pipx for isolation
      pipx install poetry==1.5.1
      # Ensure pipx binaries are available
      pipx ensurepath
    else
      echo "Poetry $(poetry --version) is already installed at $POETRY_PATH"
    fi

    # Setup pyenv and install Python versions
    # Python Version Management with pyenv
    # Configure Python versions and global defaults
    export PYENV_ROOT=~/.pyenv
    export PATH="${pkgs.pyenv}/bin:$PATH"
    
    if command -v pyenv &> /dev/null; then
      echo "Setting up Python versions..."
      # Initialize pyenv directory
      mkdir -p "$PYENV_ROOT"
      eval "$(pyenv init -)"

      # Python Version Installation Helper
      # Function to install Python version if not already installed
      install_python_version() {
        if ! pyenv versions | grep -q "$1"; then
          echo "Installing Python $1"
          pyenv install "$1"
        else
          echo "Python $1 is already installed"
        fi
      }

      # Python Version Management
      # Install and configure specific Python versions
      install_python_version "3.10"      # Primary development version
      # Add more versions as needed:
      # install_python_version "3.9"     # Legacy support
      # install_python_version "3.11"    # Latest features
      # Set Global Python Version
      # Python 3.10 for broad compatibility
      pyenv global 3.10
    else
      # Installation Error Handling
      echo "pyenv not found. Please ensure it's installed via Nix"
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
    # Verify ZSH is enabled
    {
      assertion = config.programs.zsh.enable;
      message = "ZSH must be enabled for proper shell integration";
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
