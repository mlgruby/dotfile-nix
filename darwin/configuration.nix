# darwin/configuration.nix
{ pkgs, config, lib, ... }: {
  # Nix package manager settings
  nix.settings = {
    trusted-users = [ "root" "satyasheel" ];
    keep-derivations = true;
    keep-outputs = true;
    experimental-features = [ "nix-command" "flakes" ];
  };

  # Required for proper Homebrew installation
  system.activationScripts.preUserActivation.text = ''
    export INSTALLING_HOMEBREW=1
  '';

  # Allow installation of non-free packages
  nixpkgs.config.allowUnfree = true;

  # System-wide packages installed via Nix
  environment.systemPackages = [
    # Shell Tools
    pkgs._1password-cli       # Password manager CLI
    pkgs.eza                  # Modern ls replacement
    pkgs.pkg-config           # Development tool
    pkgs.starship             # Shell prompt
    pkgs.tree                 # Directory viewer

    # Internet/Network Tools
    pkgs.discord              # Communication
    pkgs.gnutls               # SSL/TLS toolkit
    pkgs.wget                 # File downloader

    # Cloud Tools
    pkgs.awscli2              # AWS CLI version 2
    pkgs.google-cloud-sdk     # Google Cloud Platform SDK
    pkgs.terraform            # Infrastructure as Code
    pkgs.kubectl              # Kubernetes CLI

    # Basic utilities
    pkgs.curl
    pkgs.python3
    
    # Build tools and SDK
    pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
    pkgs.darwin.apple_sdk.frameworks.CoreServices
    pkgs.darwin.apple_sdk.frameworks.Security
    pkgs.darwin.cctools
    pkgs.xcodebuild  # Added for xcrun

    # Your other package groups...
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

  # Enable the Nix daemon service
  services.nix-daemon.enable = true;

  # System state version
  system.stateVersion = lib.mkForce 4;

  # Platform architecture
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Security settings
  security.pam.enableSudoTouchIdAuth = true;

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
}
