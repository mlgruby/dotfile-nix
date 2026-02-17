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

  outputs = {
    self,
    darwin,
    nixpkgs,
    home-manager,
    nix-homebrew,
    stylix,
    ...
  }: let
    system = "aarch64-darwin";

    # User configuration source:
    # - hosts.nix with shape { common = { ... }; hosts = { work = { ... }; personal = { ... }; }; }
    hostsConfigPresent = builtins.pathExists ./hosts.nix;
    hostsConfig =
      if hostsConfigPresent
      then import ./hosts.nix
      else {};
    hostsCommonConfig = hostsConfig.common or {};
    hostsEntries = hostsConfig.hosts or {};
    hostsEntryNames = builtins.attrNames hostsEntries;

    # Required basic attributes for user configuration
    requiredAttrs = [
      "username"
      "hostname"
      "fullName"
      "githubUsername"
    ];

    mkEnhancedConfig = commonConfig: rawConfig: let
      mergedConfig = commonConfig // rawConfig;
      mergedDirectories = (commonConfig.directories or {}) // (rawConfig.directories or {});
    in
      mergedConfig
      // {
        email = mergedConfig.email or "";
        profile = mergedConfig.profile or "personal";
        signingKey = mergedConfig.signingKey or "";
        directories = mergedDirectories // {
          # Provide sensible defaults for directories if not specified
          dotfiles = mergedDirectories.dotfiles or "Documents/dotfile";
          workspace = mergedDirectories.workspace or "Development";
          downloads = mergedDirectories.downloads or "Downloads";
          documents = mergedDirectories.documents or "Documents";
        };
      };

    validateConfig = sourceName: config: let
      missingAttrs = builtins.filter (attr: !(builtins.hasAttr attr config)) requiredAttrs;
      hostname = config.hostname or "";
      email = config.email or "";
      validEmail = email == "" || builtins.match "[^[:space:]@]+@[^[:space:]@]+\\.[^[:space:]@]+" email != null;
      validFormat = builtins.match "[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*" hostname != null;
      validProfiles = [ "personal" "work" ];
      profile = config.profile or "personal";

      # Validate directory paths do not contain dangerous characters.
      validatePath = path:
        if builtins.match ".*[;&|$`\"'\\\\].*" path != null
        then throw "Invalid characters in directory path (${sourceName}): ${path}"
        else true;

      # Validate all directory paths.
      dirValidation = builtins.all validatePath [
        config.directories.dotfiles
        config.directories.workspace
        config.directories.downloads
        config.directories.documents
      ];
    in
      if builtins.length missingAttrs > 0
      then throw "Missing required attributes in ${sourceName}: ${builtins.toString missingAttrs}"
      else if !validEmail
      then throw "Invalid email in ${sourceName}: '${email}'. Use a valid email like name@example.com."
      else if hostname == "" || !validFormat
      then throw "Invalid hostname format in ${sourceName}: ${hostname}. Use only letters, numbers, and hyphens."
      else if !(builtins.elem profile validProfiles)
      then throw "Invalid profile '${profile}' in ${sourceName}. Allowed values: ${builtins.toString validProfiles}"
      else if !dirValidation
      then throw "Directory path validation failed in ${sourceName}"
      else config;

    sourceConfigs =
      if !hostsConfigPresent
      then throw ''
        hosts.nix not found.
        Create it from hosts.example.nix:
          cp hosts.example.nix hosts.nix
      ''
      else if builtins.length hostsEntryNames == 0
      then throw "hosts.nix is missing entries under `hosts`."
      else
        builtins.map (name: {
          sourceName = "hosts.nix:${name}";
          rawConfig = hostsEntries.${name};
          commonConfig = hostsCommonConfig;
        })
        hostsEntryNames;

    validatedConfigs = builtins.map (source: validateConfig source.sourceName (mkEnhancedConfig source.commonConfig source.rawConfig)) sourceConfigs;
    hostnames = builtins.map (cfg: cfg.hostname) validatedConfigs;
    uniqueHostnames =
      builtins.attrNames
      (builtins.listToAttrs (builtins.map (hostname: {
          name = hostname;
          value = true;
        })
        hostnames));
    validatedConfigsChecked =
      if builtins.length hostnames == builtins.length uniqueHostnames
      then validatedConfigs
      else throw "Duplicate hostnames found in host config entries: ${builtins.toString hostnames}";

    mkDarwinConfiguration = validatedConfig:
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
  in {
    # Darwin system configurations generated from hosts.nix entries.
    darwinConfigurations = builtins.listToAttrs (builtins.map (validatedConfig: {
        name = validatedConfig.hostname;
        value = mkDarwinConfiguration validatedConfig;
      })
      validatedConfigsChecked);

    # Formatters
    # Use nixfmt directly (nixfmt-rfc-style is an alias).
    formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;
  };
}
