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
# - Packages are installed via Homebrew instead of Nix because:
#   1. They require frequent updates (e.g., browsers)
#   2. They integrate better with macOS when installed via Homebrew
#   3. The Homebrew version is more up-to-date
#   4. They need system-level integration
#   5. They handle auto-updates better
#
# - Tools with Home Manager programs.* modules are handled there:
#   - git, gh, lazygit (managed by programs.git, programs.gh, programs.lazygit)
#   - tmux, starship (managed by programs.tmux, programs.starship)
#   - This follows Home Manager best practices: one source per tool
#
# Usage:
# - New packages can be added to appropriate sections (brews/casks)
# - Use cleanup = "zap" for aggressive cleanup of old versions
# - Brewfile is auto-generated for backup/replication
# - Packages are organized by category for better maintenance
# - Comments explain package purposes and dependencies
{userConfig, ...}: {
  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;

    # Set Homebrew owner
    user = userConfig.username;

    # Handle existing Homebrew installations
    autoMigrate = true;

    # Ensure taps are managed only by Nix
    mutableTaps = true;
  };

  # Homebrew packages configuration
  homebrew = {
    enable = true;

    # Configure taps
    taps = [
      "warrensbox/tap" # For tfswitch
      "localstack/tap" # For localstack-cli
      "nguyenphutrong/tap" # For quotio
    ];

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # Remove old versions
      cleanup = "zap"; # More aggressive cleanup
    };

    # CLI Tools
    brews = [
      # Core System Utilities
      # These are installed via Homebrew for macOS-specific optimizations
      "coreutils" # GNU core utilities
      "duf" # Disk usage/free utility
      "dust" # More intuitive du
      "gnu-getopt" # GNU implementation of getopt
      # eza - MOVED to Home Manager programs.eza (includes package + config)
      "fd" # Simple find alternative
      "mas" # Mac App Store CLI
      "zoxide" # Smarter cd command

      # Python Development Environment
      # System-wide Python 3.12 and uv for project management
      "uv" # Python package and version manager
      "poetry" # Python dependency management and packaging tool
      "python@3.12" # System-wide Python 3.12

      # Development Tools
      # These versions are preferred over Nix for various reasons
      "cmake" # Build system
      "duckdb" # In-process SQL OLAP database
      "maven" # Java build tool
      "neovim" # Modern vim implementation
      "pkg-config" # Development tool
      # git - MOVED to Home Manager programs.git (includes package + config)
      # gh - MOVED to Home Manager programs.gh (includes package + config)
      "git-lfs" # Git large file storage
      # lazygit - MOVED to Home Manager programs.lazygit (includes package + config)
      "go" # Go programming language
      # rustup - MOVED to Nix (using rustc + cargo directly)
      "node" # Node.js (includes npm and npx)
      "shellcheck" # Shell script analysis tool
      "yamlresume" # Resume editor
      # "tectonic" # PDFLaTeX

      # Text Processing and Search
      # bat - MOVED to Home Manager programs.bat (includes package + config)
      "fzf" # Fuzzy finder
      # jq - MOVED to Home Manager programs.jq (includes package + config)
      # ripgrep - MOVED to Home Manager programs.ripgrep (includes package + config)
      "yq" # YAML processor

      # Terminal Utilities
      # bottom - MOVED to Home Manager programs.bottom (includes package + config)
      # btop - MOVED to Home Manager programs.btop (includes package + config)
      "glow" # Markdown viewer
      "neofetch" # System information tool
      # starship - MOVED to Home Manager programs.starship (includes package + config)
      "tldr" # Simplified man pages
      # tmux - MOVED to Home Manager programs.tmux (includes package + config)

      # Security and Secrets Management
      "gnupg" # OpenPGP implementation
      "sops" # Secrets OPerationS (encryption)
      "age" # Modern encryption tool

      # Cloud and Infrastructure Tools
      "awscli" # AWS CLI
      "helm" # Kubernetes package manager
      "localstack/tap/localstack-cli" # LocalStack CLI for local AWS development
      "terraform-docs" # Terraform documentation
      "tflint" # Terraform linter
      "warrensbox/tap/tfswitch" # Terraform version manager
    ];

    # GUI Applications (Casks)
    casks = [
      # Development Tools - JDKs
      # "temurin@8" # Eclipse Temurin JDK 8 LTS
      "temurin@11" # Eclipse Temurin JDK 11 LTS
      "temurin@17" # Eclipse Temurin JDK 17 LTS

      # Communication
      "slack" # Slack
      "discord" # Discord

      # Office tools
      "microsoft-office" # Microsoft Office

      # Development Tools (Other)
      "cursor"
      "antigravity"
      "claude-code" # Claude Code CLI tool
      "docker-desktop" # Docker Desktop for macOS
      # "google-cloud-sdk" # Google Cloud SDK
      "jetbrains-toolbox" # JetBrains IDE manager
      "postman" # API testing tool
      "visual-studio-code" # Code editor

      # Terminal and System Tools
      "alacritty" # GPU-accelerated terminal
      "karabiner-elements" # Keyboard customization
      "rectangle" # Window management
      "the-unarchiver" # Archive extraction

      # Productivity and Communication
      "bitwarden" # Password manager
      "brave-browser" # Privacy-focused browser
      "google-chrome" # Google Chrome browser
      # "chatgpt" # ChatGPT AI desktop app
      "claude" # Claude AI desktop app
      "lm-studio" # Local language model runner
      "insync" # Google Drive client
      "obsidian" # Knowledge base and note-taking
      "quotio" # AI subscription & quota tracker

      "spotify" # Music streaming
      "whatsapp" # Messaging

      # Media
      "vlc" # Media player

      # Fonts - Comprehensive font collection via Homebrew
      # Primary Nerd Fonts (for terminal/coding)
      "font-jetbrains-mono-nerd-font" # Primary coding font
      "font-fira-code-nerd-font" # Alternative with ligatures
      "font-hack-nerd-font" # Clean monospace
      "font-meslo-lg-nerd-font" # Terminal font
      
      # System UI Fonts
      "font-inter" # Modern UI font (for Stylix sansSerif)
      "font-source-serif-4" # Adobe serif font (for Stylix serif)
      "font-source-sans-3" # Adobe sans font (backup)
      
      # Additional Nerd Fonts (consolidated from Nix)
      "font-sauce-code-pro-nerd-font" # Adobe Source Code Pro
      "font-ubuntu-mono-nerd-font" # Ubuntu monospace
      "font-dejavu-sans-mono-nerd-font" # DejaVu monospace
      "font-inconsolata-nerd-font" # Google Inconsolata

      # Cloud tools/vpn
      "tailscale-app" # Tailscale
    ];

    # Global options
    global = {
      autoUpdate = true;
      brewfile = true;
      lockfiles = true;
    };

    # Mac App Store apps
    masApps = {
    };
  };
}
