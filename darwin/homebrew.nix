# darwin/homebrew.nix
#
# Homebrew package management for macOS
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
    ];
    
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";      # More aggressive cleanup
      upgrade = true;
    };

    # CLI Tools
    brews = [
      "git"      # Required for initial setup
      "mas"
      "sbt"
      "starship"
    ];

    # GUI Applications (Casks)
    casks = [
      "alacritty"                      # Fast, GPU-accelerated terminal emulator
      "bitwarden"
      "brave-browser"
      "cursor"
      "font-fira-code-nerd-font"       # Alternative with nice ligatures
      "font-hack-nerd-font"            # Clean and minimal
      "font-jetbrains-mono-nerd-font"  # Primary coding font
      "font-meslo-lg-nerd-font"        # Good for terminals
      "insync" 
      "jetbrains-toolbox"
      "karabiner-elements"             # Powerful keyboard customization
      "postman"
      "rectangle"
      "spotify"
      "the-unarchiver"
      "visual-studio-code"
      "vlc"
      "whatsapp"
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
