# darwin/secrets.nix
#
# SOPS Secrets Management Configuration
#
# Purpose:
# - Manages encrypted secrets using SOPS
# - Provides secure storage for sensitive configuration
# - Integrates with GPG for encryption/decryption
#
# Features:
# - GPG-based encryption (uses your existing GPG key)
# - Automatic decryption during system builds
# - Safe to commit encrypted files to Git
# - Centralized secrets management
#
{ config, lib, pkgs, userConfig, ... }:

{
  # SOPS Configuration
  sops = {
    # Default SOPS file (can be overridden per secret)
    defaultSopsFile = ../secrets.yaml;
    
    # Validate SOPS file during build
    validateSopsFiles = false; # Disabled during initial setup
    
    # Age key settings (optional - we're using GPG)
    age = {
      # Not needed when using GPG
      keyFile = null;
      generateKey = false;
    };
    
    # GPG settings
    gnupg = {
      # Use GPG home directory
      home = "${config.users.users.${userConfig.username}.home}/.gnupg";
    };
    
    # No secrets defined yet - will be added later
    secrets = {
      # Secrets will be defined here once we test the basic setup
    };
  };

  # Helper to ensure GPG is available during builds
  environment.systemPackages = with pkgs; [
    gnupg
    sops
  ];
}
