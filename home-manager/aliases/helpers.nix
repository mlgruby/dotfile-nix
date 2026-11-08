# home-manager/aliases/helpers.nix
#
# Alias Helper Functions
#
# Purpose:
# - DRY helper functions for generating aliases
# - Platform detection and conditional alias creation
# - Template-based complex command generation
#
# Functions:
# - mkPlatformAliases: Platform-conditional aliases
# - mkTemplateAlias: Multi-line command templates
# - mkUserDirAliases: Directory navigation aliases from user config
{pkgs, ...}: let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
in {
  # Platform flags
  inherit isDarwin isLinux;
  isMacOS = isDarwin;

  # Platform-conditional alias creation
  # Only returns aliases if current platform matches
  mkPlatformAliases = platform: aliases:
    if (platform == "darwin" && isDarwin) || (platform == "linux" && isLinux)
    then aliases
    else {};

  # Template-based alias for complex multi-line commands
  # Replaces @varname@ with actual values
  mkTemplateAlias = template: vars:
    builtins.replaceStrings
      (map (v: "@${v.name}@") vars)
      (map (v: v.value) vars)
      template;

  # Generate directory aliases from user config
  mkUserDirAliases = userDirs: homeDir:
    builtins.listToAttrs (
      builtins.filter (item: item.name != null && item.value != null) (
        builtins.attrValues (
          builtins.mapAttrs (dirName: dirPath: {
            name =
              if dirName == "dotfiles" then "dotfile"
              else if dirName == "downloads" then "dl"
              else if dirName == "documents" then "docdir"
              else if dirName == "workspace" then "ws"
              else dirName;
            value = "cd ${homeDir}/${dirPath}";
          }) userDirs
        )
      )
    );
}
