# home-manager/modules/ripgrep.nix
#
# ripgrep Configuration with Home Manager Integration
#
# Purpose:
# - Uses Home Manager's programs.ripgrep module for declarative configuration
# - Migrated from manual config in tool-configs.nix
# - Fast regex search tool with enhanced features
#
# Features:
# - Search hidden files and follow symlinks
# - Smart case sensitivity (auto-detect from pattern)
# - Exclude common build/dependency directories
# - Custom color scheme for enhanced readability
# - Optimized for development workflows
#
# Integration:
# - Package managed by Home Manager
# - Configuration fully declarative via arguments list
# - No manual config file needed
#
# Note:
# - Replaces manual configuration from tool-configs.nix
# - All ripgrep settings now managed through Home Manager
# - Arguments match previous manual configuration

{ config, lib, pkgs, ... }:

{
  programs.ripgrep = {
    enable = true;
    
    arguments = [
      # Search behavior
      "--hidden"                    # Search hidden files and directories
      "--follow"                    # Follow symbolic links
      "--smart-case"               # Smart case: case-insensitive if all lowercase, case-sensitive otherwise
      
      # Exclude common directories and files
      "--glob=!.git/*"             # Exclude git directories
      "--glob=!node_modules/*"     # Exclude Node.js dependencies
      "--glob=!.direnv/*"          # Exclude direnv cache
      "--glob=!target/*"           # Exclude Rust/Cargo build artifacts
      "--glob=!dist/*"             # Exclude distribution directories
      "--glob=!build/*"            # Exclude build directories
      "--glob=!*.lock"             # Exclude lock files
      
      # Color configuration for enhanced readability
      "--colors=line:none"         # No special line number styling
      "--colors=line:style:bold"   # Bold line numbers
      "--colors=path:fg:green"     # Green file paths
      "--colors=path:style:bold"   # Bold file paths
      "--colors=match:fg:black"    # Black text for matches
      "--colors=match:bg:yellow"   # Yellow background for matches
      "--colors=match:style:nobold" # No bold styling for matches
    ];
  };
}
