# Helpers for profile-specific Homebrew overrides.
#
# Profiles should describe only what differs from darwin/profiles/common.nix.
# Use extra* lists to add packages for a profile and remove* lists to subtract
# shared packages from that profile.

{
  mkProfile =
    {
      extraTaps ? [ ],
      extraBrews ? [ ],
      extraCasks ? [ ],
      removeTaps ? [ ],
      removeBrews ? [ ],
      removeCasks ? [ ],
      masApps ? { },
    }:
    {
      inherit
        extraTaps
        extraBrews
        extraCasks
        removeTaps
        removeBrews
        removeCasks
        masApps
        ;
    };
}
