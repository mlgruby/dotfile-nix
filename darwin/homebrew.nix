# darwin/homebrew.nix
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
      "jetbrains-mono"  # Updated font package names
      "font-hack"
      "font-fira-code"
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
