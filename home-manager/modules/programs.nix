# home-manager/modules/programs.nix
#
# Extended Programs Configuration
#
# Purpose:
# - Configures additional CLI tools and utilities
# - Provides proper Home Manager integration for tools used in aliases
# - Ensures consistent configuration across the system
#
# Programs:
# - bat: Syntax highlighting cat replacement
# - eza: Modern ls replacement
# - btop: Resource monitor
# - ripgrep: Fast text search
# - jq/yq: JSON/YAML processors
# - tree: Directory listing
# - neofetch: System information
# - tldr: Simplified man pages
# - glow: Markdown viewer
# - fd: Find replacement
# - duf: Disk usage utility
{pkgs, config, ...}: {
  programs = {
    # SSH configuration
    ssh = {
      enable = true;
      addKeysToAgent = "yes";
      compression = true;
      controlMaster = "auto";
      controlPersist = "10m";
      forwardAgent = false;
      serverAliveInterval = 60;
      serverAliveCountMax = 3;
      
      matchBlocks = {
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/id_rsa";
          identitiesOnly = true;
        };
        
        "gitlab.com" = {
          hostname = "gitlab.com";
          user = "git";
          identityFile = "~/.ssh/id_rsa";
          identitiesOnly = true;
        };
        
        # Add more hosts as needed
        "*.internal" = {
          user = "admin";
          compression = true;
          serverAliveInterval = 60;
        };
      };
    };

    # Enhanced readline configuration
    readline = {
      enable = true;
      bindings = {
        "\\e[A" = "history-search-backward";
        "\\e[B" = "history-search-forward";
        "\\e[5~" = "beginning-of-history";
        "\\e[6~" = "end-of-history";
        "\\e[3~" = "delete-char";
        "\\e[2~" = "quoted-insert";
        "\\e[5C" = "forward-word";
        "\\e[5D" = "backward-word";
        "\\C-p" = "history-search-backward";
        "\\C-n" = "history-search-forward";
      };
      variables = {
        editing-mode = "emacs";
        bell-style = "none";
        completion-ignore-case = true;
        completion-map-case = true;
        show-all-if-ambiguous = true;
        show-all-if-unmodified = true;
        visible-stats = true;
        mark-symlinked-directories = true;
        colored-stats = true;
        colored-completion-prefix = true;
        menu-complete-display-prefix = true;
      };
    };

    # GPG configuration managed via tool-configs.nix for Homebrew GPG

    # Tealdeer (tldr) configuration
    tealdeer = {
      enable = true;
      settings = {
        display = {
          compact = false;
          use_pager = true;
        };
        directories = {
          cache_dir = "${config.xdg.cacheHome}/tealdeer";
          config_dir = "${config.xdg.configHome}/tealdeer";
        };
        updates = {
          auto_update = true;
          auto_update_interval_hours = 168; # Weekly
        };
      };
    };

    # Dircolors configuration
    dircolors = {
      enable = true;
      enableZshIntegration = true;
      extraConfig = ''
        # Gruvbox color scheme for ls
        TERM Eterm
        TERM ansi
        TERM color-xterm
        TERM con132x25
        TERM con132x30
        TERM con132x43
        TERM con132x60
        TERM con80x25
        TERM con80x28
        TERM con80x30
        TERM con80x43
        TERM con80x50
        TERM con80x60
        TERM cons25
        TERM console
        TERM cygwin
        TERM dtterm
        TERM dvtm
        TERM dvtm-256color
        TERM Eterm-color
        TERM eterm-color
        TERM fbterm
        TERM gnome
        TERM gnome-256color
        TERM jfbterm
        TERM konsole
        TERM kterm
        TERM linux
        TERM linux-c
        TERM mach-color
        TERM mlterm
        TERM putty
        TERM putty-256color
        TERM rxvt
        TERM rxvt-256color
        TERM rxvt-cygwin
        TERM rxvt-cygwin-native
        TERM rxvt-unicode
        TERM rxvt-unicode256
        TERM rxvt-unicode-256color
        TERM screen
        TERM screen-256color
        TERM screen-256color-bce
        TERM screen-256color-s
        TERM screen-256color-bce-s
        TERM screen-bce
        TERM screen-w
        TERM screen.linux
        TERM screen.xterm-256color
        TERM st
        TERM st-256color
        TERM st-meta
        TERM st-meta-256color
        TERM tmux
        TERM tmux-256color
        TERM vt100
        TERM vt220
        TERM vt52
        TERM xterm
        TERM xterm-16color
        TERM xterm-256color
        TERM xterm-88color
        TERM xterm-color
        TERM xterm-debian
        TERM xterm-termite
        
        # Gruvbox colors
        NORMAL 00;38;5;244
        FILE 00
        RESET 0
        DIR 01;38;5;109
        LINK 01;38;5;108
        MULTIHARDLINK 00
        FIFO 48;5;230;38;5;136;01
        SOCK 48;5;230;38;5;136;01
        DOOR 48;5;230;38;5;136;01
        BLK 48;5;230;38;5;244;01
        CHR 48;5;230;38;5;244;01
        ORPHAN 48;5;235;38;5;167
        SETUID 48;5;160;38;5;230
        SETGID 48;5;136;38;5;230
        CAPABILITY 30;41
        STICKY_OTHER_WRITABLE 48;5;64;38;5;230
        OTHER_WRITABLE 48;5;235;38;5;109
        STICKY 48;5;33;38;5;230
        EXEC 01;38;5;142
      '';
    };

    # Enhanced Info configuration
    info = {
      enable = true;
    };

    # Enhanced Man configuration
    man = {
      enable = true;
      generateCaches = true;
    };

    # Lesspipe configuration
    lesspipe = {
      enable = true;
    };

    # Command-not-found configuration
    command-not-found = {
      enable = true;
    };

    # Broot configuration (tree alternative)
    broot = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        modal = false;
        show_selection_mark = true;
        cols_order = [
          "mark"
          "name"
          "date"
          "size"
          "count"
          "branch"
          "git"
        ];
        true_colors = true;
        icon_theme = "vscode";
        
        # Gruvbox theme
        skin = {
          default = "rgb(235, 219, 178) none";
          tree = "rgb(146, 131, 116) none";
          parent = "rgb(235, 219, 178) none";
          file = "rgb(251, 241, 199) none";
          directory = "rgb(131, 165, 152) none bold";
          exe = "rgb(184, 187, 38) none";
          link = "rgb(104, 157, 106) none";
          pruning = "rgb(124, 111, 100) none italic";
          perm__ = "rgb(124, 111, 100) none";
          perm_r = "rgb(215, 153, 33) none";
          perm_w = "rgb(204, 36, 29) none";
          perm_x = "rgb(152, 151, 26) none";
          owner = "rgb(215, 153, 33) none";
          group = "rgb(215, 153, 33) none";
          count = "rgb(69, 133, 136) none";
          dates = "rgb(168, 153, 132) none";
          sparse = "rgb(250, 189, 47) none";
          content_extract = "rgb(250, 189, 47) none";
          content_match = "rgb(250, 189, 47) none";
          git_branch = "rgb(251, 241, 199) none";
          git_insertions = "rgb(152, 151, 26) none";
          git_deletions = "rgb(190, 15, 23) none";
          git_status_current = "rgb(60, 56, 54) none";
          git_status_modified = "rgb(152, 151, 26) none";
          git_status_new = "rgb(104, 187, 38) none";
          git_status_ignored = "rgb(124, 111, 100) none";
          git_status_conflicted = "rgb(204, 36, 29) none";
          git_status_other = "rgb(204, 36, 29) none";
          selected_line = "none rgb(60, 56, 54)";
          char_match = "rgb(250, 189, 47) none";
          file_error = "rgb(251, 73, 52) none";
          flag_label = "rgb(189, 174, 147) none";
          flag_value = "rgb(211, 134, 155) none";
          input = "rgb(251, 241, 199) none";
          status_error = "rgb(213, 196, 161) rgb(204, 36, 29)";
          status_job = "rgb(250, 189, 47) rgb(60, 56, 54)";
          status_normal = "rgb(235, 219, 178) rgb(40, 40, 40)";
          status_italic = "rgb(211, 134, 155) rgb(40, 40, 40)";
          status_bold = "rgb(211, 134, 155) rgb(40, 40, 40)";
          status_code = "rgb(251, 241, 199) rgb(40, 40, 40)";
          status_ellipsis = "rgb(251, 241, 199) rgb(40, 40, 40)";
          purpose_normal = "rgb(235, 219, 178) none";
          purpose_italic = "rgb(178, 153, 132) none";
          purpose_bold = "rgb(211, 134, 155) none";
          purpose_ellipsis = "rgb(124, 111, 100) none";
          scrollbar_track = "rgb(80, 73, 69) none";
          scrollbar_thumb = "rgb(213, 196, 161) none";
          help_paragraph = "rgb(235, 219, 178) none";
          help_bold = "rgb(211, 134, 155) none";
          help_italic = "rgb(211, 134, 155) none";
          help_code = "rgb(251, 241, 199) rgb(40, 40, 40)";
          help_headers = "rgb(250, 189, 47) none";
          help_table_border = "rgb(124, 111, 100) none";
          preview = "rgb(235, 219, 178) rgb(40, 40, 40)";
          preview_title = "rgb(235, 219, 178) rgb(40, 40, 40)";
          preview_separator = "rgb(168, 153, 132) none";
          preview_match = "None rgb(178, 153, 132)";
          hex_null = "rgb(189, 174, 147) none";
          hex_ascii_graphic = "rgb(213, 196, 161) none";
          hex_ascii_whitespace = "rgb(152, 151, 26) none";
          hex_ascii_other = "rgb(254, 128, 25) none";
          hex_non_ascii = "rgb(214, 93, 14) none";
        };
      };
    };
  };

  home.packages = with pkgs; [
    # Only packages that aren't already installed via Homebrew
    # (Removed duplicates like: neofetch, tree, tldr, glow, fd, duf, etc.)
    
    # Development tools (not in Homebrew)
    httpie      # HTTP client
    
    # Text processing
    pandoc      # Document converter
    
    # Network tools
    nmap        # Network scanner
    netcat      # Network utility
    
    # Archive tools
    unzip       # ZIP extraction
    p7zip       # 7zip support
    
    # JSON/YAML tools
    fx          # JSON viewer
    yj          # YAML to JSON
    
    # Git tools (git-extras might be available via Homebrew)
    git-extras  # Additional git commands
    
    # Modern replacements (not in Homebrew)
    procs       # Process viewer
    
    # Misc utilities
    watch       # Command monitoring
    parallel    # Parallel execution
    rsync       # File synchronization
    
    # Additional development tools
    tokei       # Code statistics
    hyperfine   # Benchmarking
    choose      # Human-friendly cut/awk alternative
    sd          # Modern sed alternative
    grex        # Regex generator
    
    # System tools
    lsof        # List open files
    # pstree      # Process tree (Linux-only)
    
    # Network utilities
    # bandwhich   # Network utilization by process (Linux-only)
    # dog         # Modern dig alternative (might have Linux dependencies)
    
    # File utilities
    file        # File type detection
    tree        # Directory structure (fallback)
    
    # Text utilities
    ripgrep-all # Ripgrep with more file types
    
    # Productivity tools
    # remind      # Calendar/reminder system (might have compatibility issues)
    # taskwarrior # Task management (replaced by taskwarrior3, requires migration)
    
    # Terminal utilities
    tmux        # Terminal multiplexer (fallback)
    screen      # Terminal multiplexer (fallback)
  ];
}
