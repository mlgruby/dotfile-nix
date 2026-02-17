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
# - Shared package lists live in darwin/profiles/common.nix
# - Profile overrides live in darwin/profiles/personal.nix and darwin/profiles/work.nix
# - Select profile via hosts.nix (hostname -> profile mapping)
{userConfig, ...}: let
  profileName = userConfig.profile or "personal";
  common = import ./profiles/common.nix;
  profile = import (./profiles + "/${profileName}.nix");

  unique = list:
    builtins.foldl'
    (acc: item:
      if builtins.elem item acc
      then acc
      else acc ++ [item])
    []
    list;

  removeItems = list: toRemove:
    builtins.filter (item: !(builtins.elem item toRemove)) list;

  composeList = base: extra: remove:
    unique (removeItems (base ++ extra) remove);
in {
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
    taps = composeList common.taps profile.extraTaps profile.removeTaps;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # Remove old versions
      cleanup = "zap"; # More aggressive cleanup
    };

    # Compose common + profile-specific package lists.
    brews = composeList common.brews profile.extraBrews profile.removeBrews;
    casks = composeList common.casks profile.extraCasks profile.removeCasks;

    # Global options
    global = {
      autoUpdate = true;
      brewfile = true;
      lockfiles = true;
    };

    # Mac App Store apps
    masApps = common.masApps // profile.masApps;
  };
}
