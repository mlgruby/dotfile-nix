let
  homebrewPackages = ../homebrew-packages;
in
{
  # Shared base packages for all macOS profiles.
  taps = import (homebrewPackages + "/taps.nix");

  brews =
    (import (homebrewPackages + "/brews/core.nix"))
    ++ (import (homebrewPackages + "/brews/development.nix"))
    ++ (import (homebrewPackages + "/brews/toolchains.nix"));

  casks =
    (import (homebrewPackages + "/casks/apps.nix"))
    ++ (import (homebrewPackages + "/casks/development.nix"))
    ++ (import (homebrewPackages + "/casks/fonts.nix"))
    ++ (import (homebrewPackages + "/casks/system.nix"));

  masApps = { };
}
