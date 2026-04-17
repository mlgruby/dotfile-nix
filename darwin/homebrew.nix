# darwin/homebrew.nix
#
# Homebrew package management for macOS
#
# Purpose:
# - Manages packages that are better installed via Homebrew
# - Handles GUI applications and macOS integrations
# - Maintains consistent font installation across systems
#
# Package Categories:
# 1. GUI Applications (Casks):
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
# 2. Fonts:
#    - Programming fonts with ligatures
#    - Terminal-optimized fonts
#    - Nerd Font variants for icons
#
# 3. Selected CLI Formulae:
#    - macOS integration helpers such as mas
#    - Language runtimes and build chains intentionally kept global
#    - Tools where Homebrew is the deliberate owner
#
# Configuration:
# - Auto-updates enabled
# - Brewfile generation
# - Mac App Store integration
#
# Note:
# - Prefer Home Manager/Nix for shell tools, configured CLI programs, and
#   user-level terminal utilities.
# - Prefer Homebrew for GUI apps, fonts, vendor apps, and macOS system
#   integrations.
# - Keep language runtimes and build chains here only when they are deliberately
#   global rather than project-local.
#
# - Tools with Home Manager programs.* modules or home.packages are handled
#   there:
#   - git, gh, lazygit (managed by programs.git, programs.gh, programs.lazygit)
#   - tmux, starship, fzf, zoxide (managed by programs.* modules)
#   - fd, duf, dust, shellcheck, yq, glow, awscli2, sops, age, etc.
#     (managed by modules under home-manager/modules/packages/)
#   - This follows Home Manager best practices: one source per tool
# - scripts/testing/check-package-ownership.sh enforces the boundary so
#   Home Manager-owned tools do not drift back into Homebrew.
#
# Usage:
# - Shared package lists live in darwin/profiles/common.nix
# - Profile overrides live in darwin/profiles/personal.nix and darwin/profiles/work.nix
# - Select profile via hosts.nix (hostname -> profile mapping)
{ userConfig, ... }:
let
  profileName = userConfig.profile or "personal";
  common = import ./profiles/common.nix;
  profile = import (./profiles + "/${profileName}.nix");

  unique =
    list: builtins.foldl' (acc: item: if builtins.elem item acc then acc else acc ++ [ item ]) [ ] list;

  removeItems = list: toRemove: builtins.filter (item: !(builtins.elem item toRemove)) list;

  composeList =
    base: extra: remove:
    unique (removeItems (base ++ extra) remove);
in
{
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
    };

    # Mac App Store apps
    masApps = common.masApps // profile.masApps;
  };
}
