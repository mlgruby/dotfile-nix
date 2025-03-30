# home/shell.nix
#
# Shell Environment and Prompt
#
# Purpose:
# - Provides consistent shell experience
# - Configures core shell tools
# - Integrates shell components
#
# Features:
# 1. Command Line:
#    - Starship prompt:
#      - Modern, minimal design
#      - Using gruvbox-rainbow theme
#      - Managed via configuration.nix
#
# 2. Search & Navigation:
#    - FZF integration:
#      - Command-line fuzzy finding
#      - ZSH shell integration
#      - Enhanced by aliases
#
# 3. Shell Configuration:
#    - ZSH as primary shell
#    - Basic shell enablement
#    - Component coordination
#
# Integration:
# - Works with configuration.nix for themes
# - Connects with zsh.nix for shell settings
# - Enhances aliases.nix functionality
#
# Note:
# - Minimal configuration here
# - Main settings in other modules
# - Focuses on core integrations
# - See related files for details

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
