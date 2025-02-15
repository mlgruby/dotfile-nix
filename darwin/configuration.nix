# darwin/configuration.nix
#
# Main nix-darwin configuration file that manages system-level settings for macOS.
#
# Key components:
# - Nix package manager settings and trusted users
# - System-wide package installation via Nix
#   - Core system utilities (curl, wget, gnutls)
#   - Python base (python3, pipx)
#   - Build dependencies (openssl, readline, sqlite, zlib)
#   - Cloud platform CLIs (AWS, GCP, Terraform)
#
# Post-activation scripts:
# - SDKMAN and Java version management
#   - Installs Java 8, 11, 17 (Amazon Corretto)
#   - Sets Java 11 as default
# - Python environment setup
#   - Poetry installation and management
#   - pyenv Python version management
# - AWS credential management
#
# System preferences:
# - Dark mode
# - 24-hour time
# - TouchID for sudo
# - Application aliases in /Applications/Nix Apps

{ pkgs, config, lib, ... }: {
  # Nix package manager settings
  nix.settings = {
    trusted-users = [ "root" "satyasheel" ];
    keep-derivations = true;
    keep-outputs = true;
    experimental-features = [ "nix-command" "flakes" ];
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
  nixpkgs.config.allowUnfree = true;

  # System-wide packages installed via Nix
  environment.systemPackages = [
    # System frameworks and core tools
    pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
    pkgs.darwin.apple_sdk.frameworks.CoreServices
    pkgs.darwin.apple_sdk.frameworks.Security
    pkgs.darwin.cctools
    pkgs.xcodebuild

    # Basic system utilities
    pkgs.curl
    pkgs.wget
    pkgs.gnutls
    pkgs.python3
    pkgs.pipx

    # Shell Tools
    pkgs._1password-cli       # Password manager CLI
    pkgs.pkg-config           # Development tool
    pkgs.tree                 # Directory viewer

    # Internet/Network Tools
    pkgs.discord              # Communication

    # Cloud Tools
    pkgs.awscli2              # AWS CLI version 2
    pkgs.google-cloud-sdk     # Google Cloud Platform SDK
    pkgs.terraform            # Infrastructure as Code
    pkgs.kubectl              # Kubernetes CLI

    # Build tools and SDK
    pkgs.xcodebuild  # Added for xcrun

    # Your other package groups...
    pkgs.python3Packages.pip

    # Python build dependencies
    pkgs.openssl
    pkgs.readline
    pkgs.sqlite
    pkgs.zlib
    pkgs.git  # For pyenv installation
  ];

  # Enable and configure zsh
  programs.zsh.enable = true;

  # Application aliases setup
  system.activationScripts.applications.text = let
    env = pkgs.buildEnv {
      name = "system-applications";
      paths = config.environment.systemPackages;
      pathsToLink = "/Applications";
    };
  in
    pkgs.lib.mkForce ''
      echo "setting up /Applications..." >&2
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps
      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
      while read -r src; do
          app_name=$(basename "$src")
          echo "copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
      done
    '';

  # macOS system preferences
  system.defaults = {
    finder.FXPreferredViewStyle = "clmv";
    loginwindow.GuestEnabled = false;
    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
    };
    dock = {
      # ... your existing settings ...
    };
  };

  # Platform architecture
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Security settings
  security.pam.enableSudoTouchIdAuth = true;

  # System state version
  system.stateVersion = lib.mkForce 4;

  # AWS credential management setup
  system.activationScripts.aws-cred-setup.text = ''
    # Create AWS credential management directory
    mkdir -p /opt/aws_cred_copy
    mkdir -p $HOME/.aws
    
    # Create the unset script
    cat > /opt/aws_cred_copy/copy_and_unset << 'EOF'
    #!/bin/bash
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    unset AWS_SECURITY_TOKEN
    unset AWS_PROFILE
    unset AWS_DEFAULT_PROFILE
    EOF
    
    chmod +x /opt/aws_cred_copy/copy_and_unset
    
    # Create AWS config file with default region
    cat > $HOME/.aws/config << 'EOF'
    [default]
    region = us-west-2
    output = json
    
    [profile prod]
    region = us-west-2
    output = json
    EOF
    
    # Create the Python script for credential management
    cat > /opt/aws_cred_copy/copy_credentials_from_env << 'EOF'
    #!/usr/bin/env python3
    import sys
    import os
    import configparser
    
    profile = "default"
    if len(sys.argv)> 1:
        profile = sys.argv[1]
    
    if not os.environ.get('AWS_ACCESS_KEY_ID'):
        print("No keys found on env. exit")
        exit(1)
    
    HOME = os.environ['HOME']
    config = configparser.ConfigParser()
    config.read(f'{HOME}/.aws/credentials')
    config[profile] = {'aws_access_key_id': os.environ['AWS_ACCESS_KEY_ID'],
                      'aws_secret_access_key': os.environ['AWS_SECRET_ACCESS_KEY'],
                      'aws_session_token': os.environ['AWS_SESSION_TOKEN']}
    
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
    useGlobalPkgs = true;
    useUserPackages = true;
    users.satyasheel = import ../home-manager;
    backupFileExtension = lib.mkForce "backup";
  };

  system.activationScripts.postUserActivation.text = ''
    echo "Setting up development tools..."
    
    # Install SDKMAN and Java versions
    if [ ! -d "$HOME/.sdkman" ]; then
      echo "Installing SDKMAN..."
      TMPFILE=$(mktemp)
      ${pkgs.curl}/bin/curl -s "https://get.sdkman.io" > "$TMPFILE"
      export SDKMAN_DIR="$HOME/.sdkman"
      export sdkman_auto_answer=true
      export sdkman_selfupdate_feature=false
      export SDKMAN_BASH_COMPLETION=false
      PATH="${pkgs.unzip}/bin:${pkgs.zip}/bin:${pkgs.gnutar}/bin:${pkgs.curl}/bin:${pkgs.gnused}/bin:$PATH" bash "$TMPFILE" || true
      rm "$TMPFILE"
    fi
    
    # Install Java versions if SDKMAN is installed
    if [ -d "$HOME/.sdkman" ]; then
      echo "Installing Java versions..."
      export SDKMAN_DIR="$HOME/.sdkman"
      export SDKMAN_BASH_COMPLETION=false
      
      # Disable shellcheck warning about not following the source
      # shellcheck disable=SC1090,SC1091
      source "$HOME/.sdkman/bin/sdkman-init.sh" 2>/dev/null || true
      
      install_java_version() {
        if [ ! -d "$HOME/.sdkman/candidates/java/$1" ]; then
          echo "Installing Java $1"
          sdk install java "$1" || echo "Failed to install Java $1"
        else
          echo "Java $1 is already installed"
        fi
      }

      install_java_version "8.0.392-amzn"
      install_java_version "11.0.21-amzn"
      install_java_version "17.0.9-amzn"
      
      if sdk current java 2>/dev/null | grep -q "11.0.21-amzn"; then
        echo "Java 11 is already default"
      else
        echo "Setting Java 11 as default"
        sdk default java "11.0.21-amzn"
      fi
    fi

    # Python environment setup
    echo "Setting up Python environment..."
    
    # Check for poetry installation
    POETRY_PATH="$HOME/.local/bin/poetry"
    if [ ! -f "$POETRY_PATH" ] || ! "$POETRY_PATH" --version | grep -q "1.5.1"; then
      echo "Installing Poetry 1.5.1..."
      pipx install poetry==1.5.1
      # Ensure pipx binaries are in PATH
      pipx ensurepath
    else
      echo "Poetry $(poetry --version) is already installed at $POETRY_PATH"
    fi

    # Setup pyenv and install Python versions
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="${pkgs.pyenv}/bin:$PATH"
    
    if command -v pyenv &> /dev/null; then
      echo "Setting up Python versions..."
      mkdir -p "$PYENV_ROOT"
      eval "$(pyenv init -)"

      # Function to install Python version if not already installed
      install_python_version() {
        if ! pyenv versions | grep -q "$1"; then
          echo "Installing Python $1"
          pyenv install "$1"
        else
          echo "Python $1 is already installed"
        fi
      }

      # Install Python versions
      install_python_version "3.10"

      # Set Python 3.10 as global default
      pyenv global 3.10
    else
      echo "pyenv not found. Please ensure it's installed via Nix"
    fi
  '';
}
