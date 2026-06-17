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
  taps = homebrewLib.composeList common.taps profile.extraTaps profile.removeTaps;
  brews = homebrewLib.composeList common.brews profile.extraBrews profile.removeBrews;
  casks = homebrewLib.composeList common.casks profile.extraCasks profile.removeCasks;
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
    taps = taps;

    onActivation = {
      # Keep rebuilds deterministic and avoid Homebrew cask API fetch failures
      # during nix-darwin activation. Use the `update` alias for explicit
      # Homebrew updates/upgrades.
      autoUpdate = false;
      upgrade = false;
      # Treat the composed Nix package lists as the source of truth. Packages
      # removed from those lists are uninstalled on the next rebuild, while
      # application preferences and user data are preserved.
      cleanup = "uninstall";
      extraEnv = {
        HOMEBREW_NO_ENV_HINTS = "1";
        HOMEBREW_NO_REQUIRE_TAP_TRUST = "1";
      };
    };

    # Compose common + profile-specific package lists.
    brews = brews;
    casks = casks;

    # Global options
    global = {
      autoUpdate = false;
      brewfile = true;
    };

    # Mac App Store apps
    masApps = common.masApps // profile.masApps;
  };
}
