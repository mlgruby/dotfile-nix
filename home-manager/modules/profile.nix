# home-manager/modules/profile.nix
#
# Declarative profile configuration.
#
{
  lib,
  userConfig,
  ...
}:
let
  profileDefaults = import ../config/profile.nix { inherit userConfig; };
in
{
  options.homelab.profile = {
    name = lib.mkOption {
      type = lib.types.str;
      default = profileDefaults.name;
      description = "The profile name (work or personal)";
    };
    isWork = lib.mkOption {
      type = lib.types.bool;
      default = profileDefaults.isWork;
      description = "Whether the current profile is work";
    };
    isPersonal = lib.mkOption {
      type = lib.types.bool;
      default = profileDefaults.isPersonal;
      description = "Whether the current profile is personal";
    };
  };
}
