# darwin/homebrew.nix
#
# Manages Homebrew package installation and configuration.
# 
# Key features:
# - Automatic Homebrew installation and migration
# - Package auto-updates and cleanup
# - Development tools: git, sbt
# - Essential applications:
#   - Browsers: Brave
#   - Development: VSCode, iTerm2, Cursor, JetBrains Toolbox
#   - Productivity: Rectangle, Insync
#   - Media: Spotify, VLC
#   - Communication: WhatsApp
#   - Security: Bitwarden
# - Programming fonts:
#   - JetBrains Mono Nerd Font (primary)
#   - Fira Code Nerd Font
#   - Hack Nerd Font
#   - Meslo LG Nerd Font
#
# Note: Configured to auto-update and cleanup on activation

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
      upgrade = true;
      cleanup = "uninstall";
    };

    # CLI Tools
    brews = [
      "mas"
      "starship"
      "git"      # Required for initial setup
      "sbt"
    ];

    # GUI Applications (Casks)
    casks = [
      "bitwarden"
      "brave-browser"
      "cursor"
      "iterm2"
      "font-jetbrains-mono-nerd-font"  # Primary coding font
      "font-fira-code-nerd-font"       # Alternative with nice ligatures
      "font-hack-nerd-font"            # Clean and minimal
      "font-meslo-lg-nerd-font"        # Good for terminals
      "insync" 
      "jetbrains-toolbox"
      "rectangle"
      "the-unarchiver"
      "vlc"
      "whatsapp"
      "spotify"
      "visual-studio-code"
      "postman"
    ];

    # Global options
    global = {
      autoUpdate = true;
      brewfile = true;
    };

    # Mac App Store apps
    masApps = {};
  };
}
