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
#
{ config, lib, ... }:
let
  cfg = config.programs.ssh.custom;
  bitwardenAgent = cfg.bitwardenAgent;

  # Helper function to create homelab SSH host config
  mkHomelabHost = name: ip: {
    inherit name;
    value = {
      HostName = ip;
      User = cfg.homelabUser;
    }
    // lib.optionalAttrs (!bitwardenAgent.enable) {
      IdentityFile = cfg.homelabIdentityFile;
    };
  };

  # Generate all homelab hosts from defaults
  homelabSettings = builtins.listToAttrs (lib.mapAttrsToList mkHomelabHost cfg.homelabHosts);
in
{
  options.programs.ssh.custom = {
    bitwardenAgent = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Bitwarden SSH agent integration";
      };
      socketPath = lib.mkOption {
        type = lib.types.str;
        default = "~/.bitwarden-ssh-agent.sock";
        description = "Path to Bitwarden agent socket";
      };
    };
    homelabUser = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "Default SSH user for homelab hosts";
    };
    homelabIdentityFile = lib.mkOption {
      type = lib.types.str;
      default = "~/.ssh/id_ed25519";
      description = "SSH private key identity file for homelab";
    };
    homelabHosts = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        pve1 = "192.168.1.10";
        pve2 = "192.168.1.11";
        pve3 = "192.168.1.12";
      };
      description = "Homelab hosts mapping hostnames to IP addresses";
    };
  };

  config = {
    programs.ssh = {
      enable = true;

      # Disable default config to use explicit settings
      enableDefaultConfig = false;

      # Host-specific configurations
      settings = {
        # Global defaults for all hosts
        "*" = {
          Compression = true;
          ControlMaster = "auto";
          ControlPersist = "10m";
          ForwardAgent = false;
          ServerAliveInterval = 60;
          ServerAliveCountMax = 3;
        }
        // lib.optionalAttrs bitwardenAgent.enable {
          AddKeysToAgent = "no";
          IdentityFile = "none";
          IdentityAgent = bitwardenAgent.socketPath;
          UseKeychain = "no";
        }
        // lib.optionalAttrs (!bitwardenAgent.enable) {
          AddKeysToAgent = "yes";
          UseKeychain = "yes";
        };

        # GitHub configuration for development
        "github.com" = {
          HostName = "github.com";
          User = "git";
        }
        // lib.optionalAttrs (!bitwardenAgent.enable) {
          IdentityFile = "~/.ssh/github";
          IdentitiesOnly = true;
          # Avoid Apple ssh-agent/keychain edge cases after reboot
          # ("agent refused operation") by forcing direct key usage.
          IdentityAgent = "none";
        };

        # Internal/private network hosts
        "*.internal" = {
          User = "admin";
          Compression = true;
          ServerAliveInterval = 60;
        };
      }
      // homelabSettings; # Merge in all homelab hosts
    };
  };
}
