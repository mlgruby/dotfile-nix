# flake.nix - Optimized Nix Flake Configuration
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
  description = "Nix-darwin system configuration";

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

    # Stylix for system-wide theming
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      darwin,
      nixpkgs,
      home-manager,
      nix-homebrew,
      stylix,
      ...
    }:
    let
      system = "aarch64-darwin";
      hostConfig = import ./lib/hosts.nix { hostsPath = ./hosts.nix; };
      inherit (hostConfig) validatedConfigsChecked;

      mkDarwinConfiguration =
        validatedConfig:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            userConfig = validatedConfig;
            inherit nixpkgsConfig self;
          };
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
                useGlobalPkgs = true; # Use global package set
                useUserPackages = true; # Enable user packages
                backupFileExtension = "hm-backup"; # Home Manager backup extension
                # User-specific Arguments
                extraSpecialArgs = {
                  userConfig = validatedConfig;
                  inherit (validatedConfig)
                    username
                    fullName
                    email
                    githubUsername
                    hostname
                    signingKey
                    ;
                };
                # User Configuration
                users.${validatedConfig.username} =
                  { lib, ... }:
                  {
                    imports = [ ./home-manager/default.nix ];
                    home = {
                      username = lib.mkForce validatedConfig.username;
                      homeDirectory = lib.mkForce "/Users/${validatedConfig.username}";
                      stateVersion = "24.05";
                    };
                    programs.home-manager.enable = true;
                  };
              };
            }

            # Package Management
            # Homebrew configuration
            nix-homebrew.darwinModules.nix-homebrew
            ./darwin/homebrew.nix

            # System Configuration Modules (Refactored from inline)
            ./darwin/nix-settings.nix
            ./darwin/macos-defaults.nix
            ./darwin/misc-system.nix
            ./darwin/system-monitoring.nix

            # Theming
            # Stylix for system-wide theming
            stylix.darwinModules.stylix
          ];
        };

      nixpkgsConfig.config.allowUnfree = true;
    in
    {
      # Darwin system configurations generated from hosts.nix entries.
      darwinConfigurations = builtins.listToAttrs (
        builtins.map (validatedConfig: {
          name = validatedConfig.hostname;
          value = mkDarwinConfiguration validatedConfig;
        }) validatedConfigsChecked
      );

      # Formatters
      # Use nixfmt directly (nixfmt-rfc-style is an alias).
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;
    };
}
