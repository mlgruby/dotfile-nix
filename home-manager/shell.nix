# home/shell.nix
#
# Shell Environment Configuration
#
# Purpose:
# - Configures shell prompt and utilities
# - Sets up interactive shell features
# - Manages shell integrations
#
# Components:
# 1. Starship Prompt:
#    - Modern, minimal shell prompt
#    - Customizable with starship.toml
#    - Shows git status, Python env, etc.
#
# 2. FZF (Fuzzy Finder):
#    - Fuzzy file and history search
#    - ZSH integration for enhanced features
#    - Used by various aliases in aliases.nix
#
# Integration:
# - Works with zsh.nix for shell configuration
# - Complements aliases.nix for enhanced commands
# - Supports git workflow with lazygit.nix
#
# Note:
# - Main shell configuration is in modules/zsh.nix
# - This file focuses on shell utilities and prompt

{ config, pkgs, lib, ... }@args: let
  inherit (args) hostname;
in
{
  # Starship: Cross-shell prompt
  programs.starship = {
    enable = true;
    # Configuration is managed via preset in configuration.nix
    # Using gruvbox-rainbow theme
  };

  # FZF: Command-line fuzzy finder
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    # Additional FZF settings are in zsh.nix
    # and various FZF-enhanced aliases in aliases.nix
  };

  programs.zsh = {
    enable = true;
  };
}