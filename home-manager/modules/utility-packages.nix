# home-manager/modules/utility-packages.nix
#
# Compatibility aggregator for package-only Home Manager modules.
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
