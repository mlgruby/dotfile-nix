# home-manager/modules/eza.nix
#
# eza Configuration with Home Manager Integration
#
# Purpose:
# - Uses Home Manager's programs.eza module for declarative configuration
# - Migrated from manual config in tool-configs.nix
# - Modern ls replacement with enhanced features
#
# Features:
# - Long format display with headers
# - Git status integration
# - Icons and file type classification
# - Directory grouping and ISO timestamp formatting
# - Shell integration for common ls aliases
#
# Integration:
# - Package managed by Home Manager
# - Configuration fully declarative
# - Shell aliases automatically generated
#
# Note:
# - Replaces manual configuration from tool-configs.nix
# - Enables shell integration for bash, fish, and zsh
# - Settings match previous manual configuration
{...}: {
  programs.eza = {
    enable = true;
    
    # Core display options
    icons = "auto";
    git = true;
    colors = "auto";
    
    # Additional command-line options that don't have dedicated settings
    extraOptions = [
      "--long"
      "--group-directories-first"
      "--header"
      "--time-style=long-iso"
      "--classify"
    ];
    
    # Enable shell integration for consistent ls replacement
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };
}
