# flake.nix
#
# Nix Flake configuration for macOS system
#
# Purpose:
# - Defines system configuration
# - Manages package dependencies
# - Configures development environment
#
# Features:
# - Darwin system configuration
# - Home Manager integration
# - Homebrew management
# - User environment setup
#
# Components:
# 1. Core Dependencies:
#    - nixpkgs: Main package repository
#    - home-manager: User environment
#    - nix-darwin: macOS integration
#
# 2. Homebrew Integration:
#    - nix-homebrew: Brew management
#    - homebrew-core: Core packages
#    - homebrew-cask: GUI applications
#    - homebrew-bundle: Bundle support
#
# Integration:
# - Works with pre-nix-installation.sh
# - Configures complete macOS environment
# - Manages both Nix and Homebrew packages
#
# Note:
# - Requires Nix with flakes enabled
# - System-specific configuration
# - Supports M1/M2 Macs (aarch64-darwin)

{
  description = "Satya's nix-darwin system configuration";

  inputs = {
    # Package Sources
    # Core nixpkgs repository
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    # Home Manager for user environment management
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # nix-darwin for macOS system configuration
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Homebrew management
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
  };

  outputs = { self, darwin, nixpkgs, home-manager, nix-homebrew, ... }:
  let
    system = "aarch64-darwin";
    username = "satyasheel";
    nixpkgsConfig = {
      config = {
        allowUnfree = true;
      };
    };
  in
  {
    # Darwin System Configuration
    # Main system definition for MacBook Pro
    darwinConfigurations."ss-mbp" = darwin.lib.darwinSystem {
      inherit system;
      modules = [
        # Core System Modules
        # Base darwin configuration
        ./darwin/configuration.nix
        
        # User Environment
        # Home manager configuration
        home-manager.darwinModules.home-manager
        {
          nixpkgs = nixpkgsConfig;
          home-manager = {
            # Global Settings
            useGlobalPkgs = true;          # Use global package set
            useUserPackages = true;        # Enable user packages
            backupFileExtension = "bak";   # Backup extension
            # User-specific Arguments
            extraSpecialArgs = {
              inherit username;
            };
            # User Configuration
            users.${username} = { pkgs, lib, ... }: {
              imports = [ ./home-manager/default.nix ];
              home = {
                username = lib.mkForce username;
                homeDirectory = lib.mkForce "/Users/${username}";
                stateVersion = "23.11";
              };
              programs.home-manager.enable = true;
            };
          };
        }
        
        # Package Management
        # Homebrew configuration
        nix-homebrew.darwinModules.nix-homebrew
        ./darwin/homebrew.nix

        # System Configuration
        # Core system settings and defaults
        ({ config, pkgs, ... }: {
          # Nix Settings
          # Package manager configuration
          nix.settings = {
            trusted-users = [ "root" username ];    # Trust specific users
            keep-derivations = true;               # Keep build dependencies
            keep-outputs = true;                   # Keep build outputs
            experimental-features = [ "nix-command" "flakes" ];  # Enable modern features
          };

          # Homebrew Setup
          # Pre-activation script for Homebrew
          system.activationScripts.preUserActivation.text = ''
            export INSTALLING_HOMEBREW=1
          '';

          # macOS System Defaults
          # Finder and UI preferences
          system.defaults = {
            finder = {
              FXPreferredViewStyle = "clmv";        # Column view
              AppleShowAllFiles = true;             # Show hidden files
              ShowPathbar = true;                   # Show path bar
              ShowStatusBar = true;                 # Show status bar
              _FXShowPosixPathInTitle = true;       # Show full path
              CreateDesktop = true;                 # Show desktop icons
            };
            
            # Login Window Settings
            loginwindow = {
              GuestEnabled = false;                 # Disable guest login
            };
            
            # Global System Settings
            NSGlobalDomain = {
              AppleICUForce24HourTime = true;      # Use 24-hour time
              AppleInterfaceStyle = "Dark";        # Dark mode
              KeyRepeat = 2;                       # Fast key repeat
            };
          };

          # System Version Management
          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.stateVersion = 5;
          nixpkgs = nixpkgsConfig // {
            hostPlatform = "aarch64-darwin";
          };
          # Security Settings
          security.pam.enableSudoTouchIdAuth = true;  # Enable Touch ID for sudo

          # Shell Configuration
          # ZSH setup and environment
          programs.zsh = {
            enable = true;
            enableCompletion = true;
            promptInit = "";
            interactiveShellInit = ''
              export PATH="$HOME/Library/Application Support/pypoetry/venv/bin:$PATH"
              export PATH="$HOME/.local/bin:$PATH"
            '';
          };

          # User Account Setup
          users.users.${username} = {
            home = "/Users/${username}";
            shell = "${pkgs.zsh}/bin/zsh";
          };
        })
      ];
    };

    # Package Exports
    darwinPackages = self.darwinConfigurations."ss-mbp".pkgs;
  };
}
  