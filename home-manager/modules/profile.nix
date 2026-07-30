# home-manager/modules/profile.nix
#
# Declarative profile configuration.
#
{
  config,
  lib,
  userConfig,
  ...
}:
{
  options.homelab.profile = {
    name = lib.mkOption {
      type = lib.types.str;
      default = userConfig.profile or "personal";
      description = "The profile name (work or personal)";
    };
    isWork = lib.mkOption {
      type = lib.types.bool;
      default = (userConfig.profile or "personal") == "work";
      description = "Whether the current profile is work";
    };
    isPersonal = lib.mkOption {
      type = lib.types.bool;
      default = (userConfig.profile or "personal") == "personal";
      description = "Whether the current profile is personal";
    };
  };
}
