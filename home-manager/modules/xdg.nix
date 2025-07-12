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
    
    # Configure XDG directories (basic support)
    # Note: userDirs, desktopEntries, and mimeApps are Linux-only
    # macOS handles these through Finder preferences and Launch Services
    
    # Environment variables for XDG compliance (works on macOS)
    configHome = "/Users/${config.home.username}/.config";
    dataHome = "/Users/${config.home.username}/.local/share";  
    stateHome = "/Users/${config.home.username}/.local/state";
    cacheHome = "/Users/${config.home.username}/.cache";
  };

  # Environment variables for XDG compliance
  home.sessionVariables = {
    # XDG Base Directory
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    XDG_CACHE_HOME = "$HOME/.cache";
    
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
    
    # AWS
    AWS_SHARED_CREDENTIALS_FILE = "$XDG_CONFIG_HOME/aws/credentials";
    AWS_CONFIG_FILE = "$XDG_CONFIG_HOME/aws/config";
  };
}
