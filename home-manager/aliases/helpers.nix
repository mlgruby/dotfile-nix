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
# - mkAliases: Generate prefixed alias sets
# - mkPlatformAliases: Platform-conditional aliases
# - mkTemplateAlias: Multi-line command templates
# - mkFileTypeAliases: Extension-based alias patterns
# - mkPathAliases: Directory navigation aliases
{pkgs, ...}: let
  inherit (pkgs.stdenv) isDarwin isLinux;
in {
  # Platform flags
  inherit isDarwin isLinux;
  isMacOS = isDarwin;

  # Generate prefixed aliases from options list
  # Example: mkAliases "ls" "eza" [{suffix="a"; args="-la";}]
  # Result: { lsa = "eza -la"; }
  mkAliases = prefix: cmd: options:
    builtins.listToAttrs (
      map (opt: {
        name = "${prefix}${opt.suffix}";
        value = "${cmd} ${opt.args}";
      })
      (builtins.filter (opt: opt ? suffix && opt ? args) options)
    );

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

  # Generate aliases for file extensions
  # Example: mkFileTypeAliases "f" "fd" ["py" "js"]
  # Result: { fpy = "fd -e py"; fjs = "fd -e js"; }
  mkFileTypeAliases = prefix: cmd: extensions:
    builtins.listToAttrs (
      map (ext: {
        name = "${prefix}${ext}";
        value = "${cmd} -e ${ext}";
      }) extensions
    );

  # Generate directory navigation aliases
  mkPathAliases = paths:
    builtins.listToAttrs (
      map (path: {
        name = path.alias;
        value = "cd ${path.dir}";
      }) paths
    );

  # Generate directory aliases from user config
  mkUserDirAliases = userDirs: homeDir:
    builtins.listToAttrs (
      builtins.filter (item: item.name != null && item.value != null) (
        builtins.attrValues (
          builtins.mapAttrs (dirName: dirPath: {
            name =
              if dirName == "dotfiles" then "dotfile"
              else if dirName == "downloads" then "dl"
              else if dirName == "documents" then "docs"
              else if dirName == "workspace" then "ws"
              else dirName;
            value = "cd ${homeDir}/${dirPath}";
          }) userDirs
        )
      )
    );
}
