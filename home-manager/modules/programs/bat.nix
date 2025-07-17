# home-manager/modules/bat.nix
#
# bat Configuration with Home Manager Integration
#
# Purpose:
# - Uses Home Manager's programs.bat module for declarative configuration
# - Migrated from manual config in tool-configs.nix
# - Enhanced cat replacement with syntax highlighting
#
# Features:
# - Line numbers, Git changes, and file headers display
# - Custom syntax mappings for various file types
# - Less pager integration with optimal options
# - Automatic theme integration with Stylix
#
# Integration:
# - Package managed by Home Manager
# - Configuration fully declarative
# - Theming handled by Stylix (theme setting omitted)
#
# Note:
# - Replaces manual configuration from tool-configs.nix
# - All bat configuration now centralized in this module
# - Custom syntax mappings preserved from original config

{ config, lib, pkgs, ... }:

{
  programs.bat = {
    enable = true;
    
    config = {
      # Display style: show line numbers, Git modifications, and file header
      style = "numbers,changes,header";
      
      # Use less as pager with optimal options
      # -F: quit if entire file fits on first screen
      # -R: output "raw" control characters (for colors)
      pager = "less -FR";
      
      # Custom syntax mappings for enhanced file type detection
      map-syntax = [
        "*.jenkinsfile:Groovy"
        "*.props:Java Properties"
        "*.conf:INI"
        "*.toml:TOML"
        "*.lock:JSON"
      ];
      
      # Note: Theme will be automatically managed by Stylix
      # Original theme setting removed to use system-wide theming
    };
  };
}
