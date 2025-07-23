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

{
  programs.ssh = {
    enable = true;
    
    # Connection optimization and security
    addKeysToAgent = "yes";      # Automatically add keys to agent
    compression = true;          # Enable compression for faster transfers
    controlMaster = "auto";      # Enable connection multiplexing
    controlPersist = "10m";      # Keep connections alive for 10 minutes
    forwardAgent = false;        # Disable agent forwarding for security
    serverAliveInterval = 60;    # Send keep-alive packets every 60 seconds
    serverAliveCountMax = 3;     # Disconnect after 3 failed keep-alives
    
    # Host-specific configurations
    matchBlocks = {
      # GitHub configuration for development
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/github";
        identitiesOnly = true;    # Only use specified identity file
      };
      
      # Internal/private network hosts
      "*.internal" = {
        user = "admin";
        compression = true;
        serverAliveInterval = 60;
      };
      
      # NUC homelab servers
      "pve1" = {
        hostname = "192.168.10.12";
        user = "root";
        identityFile = "~/.ssh/nuc_homelab_id_ed25519";
      };
      
      "pve2" = {
        hostname = "192.168.10.13";
        user = "root";
        identityFile = "~/.ssh/nuc_homelab_id_ed25519";
      };
      
      "pve3" = {
        hostname = "192.168.10.14";
        user = "root";
        identityFile = "~/.ssh/nuc_homelab_id_ed25519";
      };
      
      "pi1" = {
        hostname = "192.168.10.5";
        user = "root";
        identityFile = "~/.ssh/nuc_homelab_id_ed25519";
      };
      
      "pi2" = {
        hostname = "192.168.10.6";
        user = "root";
        identityFile = "~/.ssh/nuc_homelab_id_ed25519";
      };
      
      "pi3" = {
        hostname = "192.168.10.7";
        user = "root";
        identityFile = "~/.ssh/nuc_homelab_id_ed25519";
      };
      
      # Add more host configurations as needed
      # Example for development servers:
      # "dev.example.com" = {
      #   hostname = "development.example.com";
      #   user = "developer";
      #   port = 2222;
      #   identityFile = "~/.ssh/dev_key";
      # };
    };
  };
}
