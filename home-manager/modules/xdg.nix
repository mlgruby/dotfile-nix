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
{pkgs, ...}: {
  xdg = {
    enable = true;
    
    # Configure XDG directories
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      publicShare = "$HOME/Public";
      templates = "$HOME/Templates";
      videos = "$HOME/Videos";
    };

    # Configure common directories
    configHome = "$HOME/.config";
    dataHome = "$HOME/.local/share";
    stateHome = "$HOME/.local/state";
    cacheHome = "$HOME/.cache";

    # Desktop entries for custom applications
    desktopEntries = {
      # Custom desktop entry for Alacritty with tmux
      alacritty-tmux = {
        name = "Terminal (Tmux)";
        comment = "Fast, cross-platform, OpenGL terminal emulator with tmux";
        exec = "alacritty -e tmux new-session -A -s main";
        icon = "alacritty";
        terminal = false;
        categories = [ "System" "TerminalEmulator" ];
        keywords = [ "terminal" "tmux" "shell" ];
      };
      
      # Custom entry for code workspace
      code-workspace = {
        name = "Code Workspace";
        comment = "Open VS Code in workspace mode";
        exec = "code ~/Documents/workspace";
        icon = "code";
        terminal = false;
        categories = [ "Development" "IDE" ];
        keywords = [ "code" "editor" "workspace" ];
      };
    };

    # MIME type associations
    mimeApps = {
      enable = true;
      
      defaultApplications = {
        # Web browser
        "text/html" = [ "safari.desktop" ];
        "application/xhtml+xml" = [ "safari.desktop" ];
        "x-scheme-handler/http" = [ "safari.desktop" ];
        "x-scheme-handler/https" = [ "safari.desktop" ];
        
        # Text files
        "text/plain" = [ "code.desktop" ];
        "text/markdown" = [ "code.desktop" ];
        "text/x-python" = [ "code.desktop" ];
        "text/x-shellscript" = [ "code.desktop" ];
        "application/json" = [ "code.desktop" ];
        "application/x-yaml" = [ "code.desktop" ];
        
        # Images
        "image/png" = [ "preview.desktop" ];
        "image/jpeg" = [ "preview.desktop" ];
        "image/gif" = [ "preview.desktop" ];
        "image/svg+xml" = [ "code.desktop" ];
        
        # Documents
        "application/pdf" = [ "preview.desktop" ];
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "pages.desktop" ];
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [ "numbers.desktop" ];
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [ "keynote.desktop" ];
        
        # Archives
        "application/zip" = [ "the-unarchiver.desktop" ];
        "application/x-tar" = [ "the-unarchiver.desktop" ];
        "application/x-gzip" = [ "the-unarchiver.desktop" ];
        "application/x-7z-compressed" = [ "the-unarchiver.desktop" ];
        
        # Video
        "video/mp4" = [ "iina.desktop" ];
        "video/x-matroska" = [ "iina.desktop" ];
        "video/webm" = [ "iina.desktop" ];
        
        # Audio
        "audio/mpeg" = [ "music.desktop" ];
        "audio/mp4" = [ "music.desktop" ];
        "audio/flac" = [ "music.desktop" ];
      };
      
      associations = {
        added = {
          # Development files
          "application/x-nix" = [ "code.desktop" ];
          "text/x-toml" = [ "code.desktop" ];
          "text/x-rust" = [ "code.desktop" ];
          "text/x-scala" = [ "intellij-idea.desktop" ];
          "text/x-java" = [ "intellij-idea.desktop" ];
          "application/x-sql" = [ "code.desktop" ];
          
          # Configuration files
          "application/x-desktop" = [ "code.desktop" ];
          "text/x-ini" = [ "code.desktop" ];
          "text/x-systemd-unit" = [ "code.desktop" ];
          
          # Log files
          "text/x-log" = [ "code.desktop" ];
          "application/x-log" = [ "code.desktop" ];
        };
      };
    };
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
    GNUPGHOME = "$XDG_DATA_HOME/gnupg";
    
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
