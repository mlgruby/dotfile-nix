# home-manager/modules/ssh.nix
#
# SSH Configuration
#
# Purpose:
# - Manages SSH client configuration and connection settings
# - Provides secure defaults and connection optimization
# - Configures host-specific settings for different environments
#
# Features:
# - Connection multiplexing for faster subsequent connections
# - Key agent integration for seamless authentication
# - Host-specific configurations for GitHub and internal servers
# - Compression and keep-alive settings for better performance
#
# Integration:
# - Works with GPG module for key management
# - Compatible with Git SSH authentication
# - Supports development workflow automation
#
# Security:
# - Forward agent disabled by default for security
# - Host-specific identity files
# - Connection persistence with reasonable timeouts

{ config, lib, ... }:

let
  defaults = import ../config.nix;

  # Helper function to create homelab SSH host config
  mkHomelabHost = name: ip: {
    inherit name;
    value = {
      hostname = ip;
      user = defaults.ssh.homelabUser;
      identityFile = defaults.ssh.homelabIdentityFile;
    };
  };

  # Generate all homelab hosts from defaults
  homelabMatchBlocks = builtins.listToAttrs (
    lib.mapAttrsToList mkHomelabHost defaults.homelabHosts
  );
in
{
  programs.ssh = {
    enable = true;

    # Disable default config to use explicit settings
    enableDefaultConfig = false;

    # Host-specific configurations
    matchBlocks = {
      # Global defaults for all hosts
      "*" = {
        addKeysToAgent = "yes";
        compression = true;
        controlMaster = "auto";
        controlPersist = "10m";
        forwardAgent = false;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
      };

      # GitHub configuration for development
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/github";
        identitiesOnly = true;
      };

      # Internal/private network hosts
      "*.internal" = {
        user = "admin";
        compression = true;
        serverAliveInterval = 60;
      };
    } // homelabMatchBlocks;  # Merge in all homelab hosts
  };
}
