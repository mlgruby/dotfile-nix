# darwin/homebrew.nix
#
# Homebrew package management for macOS
#
# Purpose:
# - Manages packages that are better installed via Homebrew
# - Handles GUI applications (casks) that aren't available via Nix
# - Maintains consistent font installation across systems
#
# Package Categories:
# 1. CLI Tools:
#    - Core System Utilities:
#      - File and disk management
#      - Directory navigation
#      - Mac App Store integration
#      - System monitoring
#    - Development Tools:
#      - Version control systems
#      - Build tools and compilers
#      - Development utilities
#    - Text Processing:
#      - Modern CLI alternatives
#      - Search and filtering
#      - Data format processors
#    - Terminal Utilities:
#      - System monitoring
#      - Shell enhancements
#      - Documentation tools
#    - Cloud Tools:
#      - Cloud provider CLIs
#      - Infrastructure management
#      - Version managers
#
# 2. GUI Applications (Casks):
#    - Development:
#      - Code editors and IDEs
#      - API testing tools
#      - Containerization
#    - Terminal:
#      - GPU-accelerated emulators
#    - System Tools:
#      - Keyboard customization
#      - Window management
#      - File utilities
#    - Browsers & Communication:
#      - Web browsers
#      - Messaging platforms
#      - Cloud storage clients
#    - Cloud Tools:
#      - Cloud platform SDKs
#
# 3. Fonts:
#    - Programming fonts with ligatures
#    - Terminal-optimized fonts
#    - Nerd Font variants for icons
#
# Configuration:
# - Auto-updates enabled
# - Brewfile generation
# - Mac App Store integration
#
# Note:
# - Some packages are installed via Homebrew instead of Nix because:
#   1. They require frequent updates (e.g., browsers)
#   2. They integrate better with macOS when installed via Homebrew
#   3. The Homebrew version is more up-to-date
#   4. They need system-level integration
#   5. They handle auto-updates better
#
# Usage:
# - New packages can be added to appropriate sections (brews/casks)
# - Use cleanup = "zap" for aggressive cleanup of old versions
# - Brewfile is auto-generated for backup/replication
# - Packages are organized by category for better maintenance
# - Comments explain package purposes and dependencies

{ config, pkgs, lib, userConfig, ... }: {
  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;

    # Set Homebrew owner
    user = userConfig.username;

    # Handle existing Homebrew installations
    autoMigrate = false;

    # Ensure taps are managed only by Nix
    mutableTaps = true;
  };

  # Homebrew packages configuration
  homebrew = {
    enable = true;
    
    # Configure taps
    taps = [
      "warrensbox/tap"      # For tfswitch
    ];
    
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # Remove old versions
      cleanup = "zap";      # More aggressive cleanup
    };

    # CLI Tools
    brews = [
      # Core System Utilities
      # These are installed via Homebrew for macOS-specific optimizations
      "coreutils"                   # GNU core utilities
      "duf"                         # Disk usage/free utility
      "dust"                        # More intuitive du
      "eza"                         # Modern ls replacement
      "fd"                          # Simple find alternative
      "mas"                         # Mac App Store CLI
      "zoxide"                      # Smarter cd command
      
      # Python Development Environment
      # Managed via Homebrew for better macOS integration
      "uv"                          # Python package manager

      # Development Tools
      # These versions are preferred over Nix for various reasons
      "cmake"                       # Build system
      "neovim"                      # Modern vim implementation
      "pkg-config"                  # Development tool
      "git"                         # Version control
      "gh"                          # GitHub CLI
      "git-lfs"                     # Git large file storage
      "lazygit"                     # Terminal UI for git
      "node"                        # Node.js (includes npm and npx)
      
      # Text Processing and Search
      "bat"                         # Modern cat with syntax highlighting
      "fzf"                         # Fuzzy finder
      "jq"                          # JSON processor
      "ripgrep"                     # Fast grep alternative
      "yq"                          # YAML processor
      
      # Terminal Utilities
      "bottom"                      # System/Process monitor
      "btop"                        # Modern resource monitor (replaces htop)
      "glow"                        # Markdown viewer
      "neofetch"                    # System information tool
      "starship"                    # Cross-shell prompt
      "tldr"                        # Simplified man pages
      "tmux"                        # Terminal multiplexer
      
      # Security
      "gnupg"                       # OpenPGP implementation
      
      # Cloud and Infrastructure Tools
      "awscli"                      # AWS CLI
      "terraform-docs"              # Terraform documentation
      "tflint"                      # Terraform linter
      "warrensbox/tap/tfswitch"     # Terraform version manager
    ];

    # GUI Applications (Casks)
    casks = [
      # Development Tools - JDKs
      "temurin@8"                   # Eclipse Temurin JDK 8 LTS
      "temurin@11"                  # Eclipse Temurin JDK 11 LTS
      "temurin@17"                  # Eclipse Temurin JDK 17 LTS
      
      # Cloud Storage
      "google-drive"                # Google Drive client
      
      # Communication
      "discord"             # Move from configuration.nix
      
      # Development Tools (Other)
      "cursor"
      "docker"
      "google-cloud-sdk"    # Google Cloud SDK
      "jetbrains-toolbox"   # JetBrains IDE manager
      "postman"             # API testing tool
      "visual-studio-code"  # Code editor
      
      # Terminal and System Tools
      "alacritty"           # GPU-accelerated terminal
      "karabiner-elements"  # Keyboard customization
      "rectangle"           # Window management
      "the-unarchiver"      # Archive extraction
      
      # Productivity and Communication
      "bitwarden"           # Password manager
      "brave-browser"       # Privacy-focused browser
      "claude"              # Claude AI desktop app
      "insync"              # Google Drive client
      "obsidian"            # Knowledge base and note-taking
      "spotify"             # Music streaming
      "whatsapp"            # Messaging
      
      # Media
      "vlc"                 # Media player
      
      # Fonts
      "font-fira-code-nerd-font"      # Alternative with ligatures
      "font-hack-nerd-font"           # Clean monospace
      "font-jetbrains-mono-nerd-font" # Primary coding font
      "font-meslo-lg-nerd-font"       # Terminal font
    ];

    # Global options
    global = {
      autoUpdate = true;
      brewfile = true;
      lockfiles = true;
    };

    # Mac App Store apps
    masApps = {};
  };
}
