# home-manager/modules/xdg.nix
#
# XDG Base Directory Configuration
#
# Purpose:
# - Configures XDG directories for better organization
# - Sets up desktop integration and file associations
# - Provides consistent directory structure
#
# Features:
# - Standard XDG directories
# - Desktop entries for applications
# - File associations and MIME types
# - User directories configuration
{pkgs, config, ...}: {
  # XDG configuration for macOS
  # Note: Many XDG features are Linux-specific
  # macOS uses different conventions and file associations
  
  xdg = {
    enable = true;
    # Use Home Manager's built-in XDG configuration
    # No need to override the defaults as they're already correct
  };

  # Environment variables for XDG compliance (only application-specific ones)
  home.sessionVariables = {
    # Note: Base XDG variables managed by Home Manager's built-in xdg module
    
    # Application-specific XDG compliance
    LESSHISTFILE = "$XDG_CACHE_HOME/less/history";
    HISTFILE = "$XDG_STATE_HOME/zsh/history";
    INPUTRC = "$XDG_CONFIG_HOME/readline/inputrc";
    # GNUPGHOME managed by tool-configs.nix for Homebrew GPG
    
    # Development tools
    CARGO_HOME = "$XDG_DATA_HOME/cargo";
    RUSTUP_HOME = "$XDG_DATA_HOME/rustup";
    GOPATH = "$XDG_DATA_HOME/go";
    GOMODCACHE = "$XDG_CACHE_HOME/go/mod";
    
    # Node.js
    NODE_REPL_HISTORY = "$XDG_DATA_HOME/node_repl_history";
    NPM_CONFIG_USERCONFIG = "$XDG_CONFIG_HOME/npm/npmrc";
    
    # Python
    PYTHONSTARTUP = "$XDG_CONFIG_HOME/python/pythonrc";
    JUPYTER_CONFIG_DIR = "$XDG_CONFIG_HOME/jupyter";
    
    # Docker
    DOCKER_CONFIG = "$XDG_CONFIG_HOME/docker";
  };
}
