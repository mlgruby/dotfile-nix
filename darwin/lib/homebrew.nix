# Helpers for composing Homebrew package lists.
#
# Shared lists come from darwin/profiles/common.nix and profile files can add or
# remove items. composeList preserves order while removing duplicates.

let
  unique =
    list: builtins.foldl' (acc: item: if builtins.elem item acc then acc else acc ++ [ item ]) [ ] list;

  removeItems = list: toRemove: builtins.filter (item: !(builtins.elem item toRemove)) list;
in
{
  inherit unique removeItems;

  composeList =
    base: extra: remove:
    unique (removeItems (base ++ extra) remove);
}
