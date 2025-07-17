# home-manager/modules/jq.nix
#
# jq Configuration with Home Manager Integration
#
# Purpose:
# - Uses Home Manager's programs.jq module for declarative configuration
# - Migrated from manual config in tool-configs.nix
# - Command-line JSON processor with custom color scheme
#
# Features:
# - Custom color scheme for JSON output elements
# - Consistent gray tones for most elements
# - Green highlighting for strings
# - Bold formatting for arrays and objects
#
# Integration:
# - Package managed by Home Manager
# - Colors configured declaratively via programs.jq.colors
# - No manual .jq file needed
#
# Note:
# - Replaces manual configuration from tool-configs.nix
# - Color values match previous manual configuration
# - Uses Home Manager's structured color configuration

{ config, lib, pkgs, ... }:

{
  programs.jq = {
    enable = true;
    
    colors = {
      # Basic values - neutral gray tones
      null = "0;37";        # Light gray for null values
      false = "0;37";       # Light gray for false
      true = "0;37";        # Light gray for true
      numbers = "0;37";     # Light gray for numbers
      
      # String values - green for visibility
      strings = "0;32";     # Green for string values
      
      # Collections - bold white for structure
      arrays = "1;37";      # Bold white for arrays
      objects = "1;37";     # Bold white for objects
      
      # Object keys - use Home Manager's default color
      objectKeys = "1;34";  # Bold blue for object keys (Home Manager default)
    };
  };
}
