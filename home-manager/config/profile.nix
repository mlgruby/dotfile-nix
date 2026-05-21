# home-manager/config/profile.nix
#
# Shared profile helpers for Home Manager modules.
#
# Keep profile checks here instead of scattering string comparisons through
# modules. Host selection still lives in hosts.nix.
{ userConfig }:
let
  name = userConfig.profile or "personal";
in
{
  inherit name;
  isWork = name == "work";
  isPersonal = name == "personal";
}
