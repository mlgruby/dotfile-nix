# home-manager/aliases/default.nix
#
# Shell Aliases - Main Entry Point
#
# Purpose:
# - Imports and combines all alias modules (~220 total aliases)
# - Provides centralized alias configuration
#
# Structure:
# - helpers.nix: Helper functions for alias generation
# - core.nix: Essential shell aliases (~40 aliases)
# - git.nix: Git workflow aliases (~80 aliases)
# - dev-tools.nix: Docker, Terraform, k8s, modern CLI tools (~70 aliases)
# - platform.nix: macOS/Linux specific aliases (~30 aliases)
#
# Quick Reference:
# - See README.md in this directory for full documentation
# - Type `alias | grep <keyword>` to search for specific aliases
# - Most interactive aliases use FZF for fuzzy selection
#
# Usage:
# Import this file and it returns the combined alias set
{
  pkgs,
  config,
  userConfig,
  ...
}: let
  # Import helper functions
  helpers = import ./helpers.nix {inherit pkgs;};

  # Common args passed to all alias modules
  commonArgs = {
    inherit config userConfig helpers;
  };

  # Import alias modules
  coreAliases = import ./core.nix commonArgs;
  gitAliases = import ./git.nix {};
  devToolsAliases = import ./dev-tools.nix {inherit helpers;};
  platformAliases = import ./platform.nix commonArgs;
in
  # Combine all aliases
  # Order matters - later modules can override earlier ones
  coreAliases
  // gitAliases
  // devToolsAliases
  // platformAliases
