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
{pkgs, ...}: {
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

    # Readline configuration
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
        "\\e\\e[C" = "forward-word";
        "\\e\\e[D" = "backward-word";
        "\\C-n" = "menu-complete";
        "\\C-p" = "menu-complete-backward";
      };
      variables = {
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
        page-completions = false;
        skip-completed-text = true;
        enable-bracketed-paste = true;
      };
    };
  };

  # Additional packages NOT already in Homebrew
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
    
    # Performance monitoring
    iotop       # I/O monitoring
    nethogs     # Network monitoring
    
    # Modern replacements (not in Homebrew)
    procs       # Process viewer
    
    # Misc utilities
    watch       # Command monitoring
    parallel    # Parallel execution
    rsync       # File synchronization
  ];
}
