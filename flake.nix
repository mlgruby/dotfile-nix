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
  };

  outputs = { self, darwin, nixpkgs, home-manager, nix-homebrew, ... }@inputs:
  let
    system = "aarch64-darwin";
    # Validate hostname format
    validateHostname = hostname: 
      let
        # Nix allows only letters, numbers, and hyphens as valid characters for hostnames
        validFormat = builtins.match "[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*" hostname != null;
      in
      if hostname == null || hostname == "" 
      then throw "Hostname must be defined in user-config.nix"
      else if !validFormat 
      then throw "Invalid hostname format: ${hostname}. Use only letters, numbers, and hyphens." 
      else hostname;

    # Import user configuration
    userConfig = if builtins.pathExists ./user-config.nix
      then import ./user-config.nix
      else import ./user-config.default.nix;
    # Ensure required attributes exist
    requiredAttrs = ["username" "hostname" "email" "fullName" "githubUsername"];
    missingAttrs = builtins.filter (attr: !(builtins.hasAttr attr userConfig)) requiredAttrs;
    _ = if builtins.length missingAttrs > 0
        then throw "Missing required attributes in user-config.nix: ${builtins.toString missingAttrs}"
        else null;
    # Validate the hostname
    validatedHostname = validateHostname userConfig.hostname;
    nixpkgsConfig = {
      config = {
        allowUnfree = true;
      };
    };
  in
  {
    # Darwin System Configuration
    # Main system definition for MacBook Pro
    darwinConfigurations."${validatedHostname}" = darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit userConfig nixpkgsConfig self; };
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
              inherit userConfig;
              inherit (userConfig) username fullName email githubUsername hostname;
            };
            # User Configuration
            users.${userConfig.username} = { pkgs, lib, ... }: {
              imports = [ ./home-manager/default.nix ];
              home = {
                username = lib.mkForce userConfig.username;
                homeDirectory = lib.mkForce "/Users/${userConfig.username}";
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

        # System Configuration Modules (Refactored from inline)
        ./darwin/nix-settings.nix
        ./darwin/macos-defaults.nix
        ./darwin/misc-system.nix
      ];
    };

    # Package Exports
    darwinPackages = self.darwinConfigurations.${validatedHostname}.pkgs;
  };
}
  