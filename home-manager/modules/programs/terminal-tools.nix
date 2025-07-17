# home-manager/modules/terminal-tools.nix
#
# Terminal Tools Configuration
#
# Purpose:
# - Configures essential terminal utilities and enhancers
# - Provides better command-line experience and documentation access
# - Manages terminal interaction improvements
#
# Tools Configured:
# - readline: Enhanced line editing with key bindings
# - tealdeer: Modern tldr implementation for quick help
# - info: GNU info documentation system
# - man: Manual page system with caching
# - lesspipe: Enhanced less pager with file type support
# - command-not-found: Suggests packages for missing commands
#
# Features:
# - Emacs-style key bindings for readline
# - Case-insensitive completion
# - Automatic tealdeer cache updates
# - Optimized info and man page access
# - Enhanced pager functionality
#
# Integration:
# - Works with shell configuration (zsh.nix)
# - Compatible with XDG directory structure
# - Supports development workflow

{ config, lib, ... }:

{
  programs = {
    # Enhanced readline configuration for better command-line editing
    readline = {
      enable = true;
      
      # Key bindings for improved navigation
      bindings = {
        # History navigation
        "\\e[A" = "history-search-backward";   # Up arrow
        "\\e[B" = "history-search-forward";    # Down arrow
        "\\e[5~" = "beginning-of-history";     # Page Up
        "\\e[6~" = "end-of-history";           # Page Down
        
        # Text manipulation
        "\\e[3~" = "delete-char";              # Delete key
        "\\e[2~" = "quoted-insert";            # Insert key
        
        # Word navigation
        "\\e[5C" = "forward-word";             # Ctrl+Right
        "\\e[5D" = "backward-word";            # Ctrl+Left
        
        # Alternative history navigation
        "\\C-p" = "history-search-backward";   # Ctrl+P
        "\\C-n" = "history-search-forward";    # Ctrl+N
      };
      
      # Readline behavior settings
      variables = {
        editing-mode = "emacs";                # Emacs-style key bindings
        bell-style = "none";                   # Disable bell
        completion-ignore-case = true;         # Case-insensitive completion
        completion-map-case = true;            # Map case during completion
        show-all-if-ambiguous = true;          # Show all completions immediately
        show-all-if-unmodified = true;         # Show all if input unchanged
        visible-stats = true;                  # Show file type indicators
        mark-symlinked-directories = true;     # Mark symlinked directories
        colored-stats = true;                  # Colorize file type indicators
        colored-completion-prefix = true;      # Colorize completion prefixes
        menu-complete-display-prefix = true;   # Show prefix during menu completion
      };
    };

    # Tealdeer (modern tldr) configuration
    tealdeer = {
      enable = true;
      
      settings = {
        # Display preferences
        display = {
          compact = false;        # Use full format for better readability
          use_pager = true;       # Use pager for long pages
        };
        
        # Directory configuration (XDG compliant)
        directories = {
          cache_dir = "${config.xdg.cacheHome}/tealdeer";
          config_dir = "${config.xdg.configHome}/tealdeer";
        };
        
        # Update settings
        updates = {
          auto_update = true;                   # Automatically update cache
          auto_update_interval_hours = 168;    # Weekly updates
        };
      };
    };

    # Enhanced Info configuration for GNU documentation
    info = {
      enable = true;
    };

    # Enhanced Man configuration with caching
    man = {
      enable = true;
      generateCaches = true;    # Generate man page caches for faster access
    };

    # Lesspipe configuration for enhanced less pager
    lesspipe = {
      enable = true;           # Enable automatic file type detection and formatting
    };

    # Command-not-found configuration
    command-not-found = {
      enable = true;           # Suggest packages when commands are not found
    };
  };
}
