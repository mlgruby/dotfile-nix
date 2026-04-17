# home-manager/modules/package-groups.nix
#
# Aggregates package-only Home Manager modules by ownership group.
# Keep package ownership split by purpose under ./packages/.

{
  imports = [
    ./packages/cloud.nix
    ./packages/development.nix
    ./packages/languages.nix
    ./packages/security.nix
    ./packages/system.nix
    ./packages/text.nix
  ];
}
