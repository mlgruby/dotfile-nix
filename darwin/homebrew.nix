# darwin/homebrew.nix
#
# Homebrew package management for macOS
#
# Purpose:
# - Manages packages that are better installed via Homebrew
# - Handles GUI applications (casks) that aren't available via Nix
# - Maintains consistent font installation across systems
#
# Manages:
# - GUI Applications
#   - Development: VSCode, JetBrains Toolbox
#   - Terminal: Alacritty
#   - Utilities: Rectangle, The Unarchiver
#   - Browsers: Brave
#
# - CLI Tools (when Homebrew versions preferred)
#   - git
#   - starship (shell prompt)
#
# - Fonts
#   - JetBrains Mono Nerd Font (primary)
#   - Fira Code Nerd Font
#   - Hack Nerd Font
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
#
# Usage:
# - New packages can be added to appropriate sections (brews/casks)
# - Use cleanup = "zap" for aggressive cleanup of old versions
# - Brewfile is auto-generated for backup/replication

{ config, lib, ... }: {
  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;

    # Set Homebrew owner
    user = "satyasheel";

    # Handle existing Homebrew installations
    autoMigrate = true;
  };

  # Homebrew packages configuration
  homebrew = {
    enable = true;
    
    # Configure taps
    taps = [
      "homebrew/bundle"
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
      "stow"                        # Symlink farm manager
      "zoxide"                      # Smarter cd command
      
      # Python Development Environment
      # Managed via Homebrew for better macOS integration
      "pyenv"                       # Python version manager
      "uv"                          # Python package manager
      
      # Development Tools
      # These versions are preferred over Nix for various reasons
      "cmake"                       # Build system
      "pkg-config"                  # Development tool
      "git"                         # Version control
      "gh"                          # GitHub CLI
      "git-lfs"                     # Git large file storage
      "lazygit"                     # Terminal UI for git
      
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
      # Communication
      "discord"                     # Move from configuration.nix
      
      # Cloud Tools
      "google-cloud-sdk"           # Google Cloud Platform SDK
      
      # Development Tools
      "cursor"
      "docker"
      "postman"                        # API testing tool
      "visual-studio-code"             # Code editor
      
      # Terminal and System Tools
      "alacritty"                      # GPU-accelerated terminal
      "karabiner-elements"             # Keyboard customization
      "rectangle"                      # Window management
      "the-unarchiver"                 # Archive extraction
      
      # Productivity and Communication
      "bitwarden"                      # Password manager
      "brave-browser"                  # Privacy-focused browser
      "insync"                         # Google Drive client
      "spotify"                        # Music streaming
      "whatsapp"                       # Messaging
      
      # Media
      "vlc"                            # Media player
      
      # Fonts
      "font-fira-code-nerd-font"       # Alternative with ligatures
      "font-hack-nerd-font"            # Clean monospace
      "font-jetbrains-mono-nerd-font"  # Primary coding font
      "font-meslo-lg-nerd-font"        # Terminal font
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
