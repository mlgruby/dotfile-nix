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

    # SOPS-Nix for secrets management (disabled for now)
    # sops-nix = {
    #   url = "github:Mic92/sops-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = {
    self,
    darwin,
    nixpkgs,
    home-manager,
    nix-homebrew,
    stylix,
    # sops-nix,
    ...
  }: let
    system = "aarch64-darwin";

    # User configuration validation with enhanced directory support
    userConfig =
      if builtins.pathExists ./user-config.nix
      then import ./user-config.nix
      else import ./user-config.default.nix;

    # Required basic attributes for user configuration
    requiredAttrs = [
      "username"
      "hostname"
      "email"
      "fullName"
      "githubUsername"
    ];
    missingAttrs = builtins.filter (attr: !(builtins.hasAttr attr userConfig)) requiredAttrs;

    # Enhanced user configuration with directory defaults
    enhancedUserConfig = userConfig // {
      directories = (userConfig.directories or {}) // {
        # Provide sensible defaults for directories if not specified
        dotfiles = userConfig.directories.dotfiles or "Documents/dotfile";
        workspace = userConfig.directories.workspace or "Development";
        downloads = userConfig.directories.downloads or "Downloads";
        documents = userConfig.directories.documents or "Documents";
      };
    };

    validateConfig = config: let
      hostname = config.hostname or "";
      validFormat = builtins.match "[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*" hostname != null;
      
      # Validate directory paths don't contain dangerous characters
      validatePath = path: 
        if builtins.match ".*[;&|$`\"'\\\\].*" path != null
        then throw "Invalid characters in directory path: ${path}"
        else true;
      
      # Validate all directory paths
      dirValidation = builtins.all validatePath [
        config.directories.dotfiles
        config.directories.workspace
        config.directories.downloads
        config.directories.documents
      ];
    in
      if builtins.length missingAttrs > 0
      then throw "Missing required attributes in user-config.nix: ${builtins.toString missingAttrs}"
      else if hostname == "" || !validFormat
      then throw "Invalid hostname format: ${hostname}. Use only letters, numbers, and hyphens."
      else if !dirValidation
      then throw "Directory path validation failed"
      else config;

    validatedConfig = validateConfig enhancedUserConfig;
    nixpkgsConfig.config.allowUnfree = true;
  in {
    # Darwin System Configuration
    # Main system definition for MacBook Pro
    darwinConfigurations."${validatedConfig.hostname}" = darwin.lib.darwinSystem {
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
              inherit
                (validatedConfig)
                username
                fullName
                email
                githubUsername
                hostname
                signingKey
                ;
            };
            # User Configuration
            users.${validatedConfig.username} = {lib, ...}: {
              imports = [./home-manager/default.nix];
              home = {
                username = lib.mkForce validatedConfig.username;
                homeDirectory = lib.mkForce "/Users/${validatedConfig.username}";
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

        # Theming
        # Stylix for system-wide theming
        stylix.darwinModules.stylix

        # Secrets Management (disabled for now)
        # sops-nix.darwinModules.sops
        # ./darwin/secrets.nix
      ];
    };

    # Formatters
    # Nix code formatter using nixfmt-rfc-style
    formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;

    # Package Exports
    darwinPackages = self.darwinConfigurations.${validatedConfig.hostname}.pkgs;
  };
}
