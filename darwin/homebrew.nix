# darwin/homebrew.nix
#
# Wires nix-homebrew into nix-darwin and composes common Homebrew packages with
# profile-specific overrides.
#
# Shared package lists live under darwin/homebrew-packages/. Profile overrides
# live in darwin/profiles/. Ownership policy lives in docs/guides/.
{ userConfig, ... }:
let
  homebrewLib = import ./lib/homebrew.nix;
  profileName = userConfig.profile or "personal";
  common = import ./profiles/common.nix;
  profile = import (./profiles + "/${profileName}.nix");
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
    taps = homebrewLib.composeList common.taps profile.extraTaps profile.removeTaps;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # Remove old versions
      cleanup = "zap"; # More aggressive cleanup
    };

    # Compose common + profile-specific package lists.
    brews = homebrewLib.composeList common.brews profile.extraBrews profile.removeBrews;
    casks = homebrewLib.composeList common.casks profile.extraCasks profile.removeCasks;

    # Global options
    global = {
      autoUpdate = true;
      brewfile = true;
    };

    # Mac App Store apps
    masApps = common.masApps // profile.masApps;
  };
}
