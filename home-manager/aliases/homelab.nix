# home-manager/aliases/homelab.nix
#
# Homelab and self-hosted service aliases.

{ config, ... }:
let
  secureRestoreDir = "${config.home.homeDirectory}/Secure/lazywarden-restore";
in
{
  # Lazywarden backup recovery
  lwdec = "lazywarden-decrypt";
  lw-decrypt = "lazywarden-decrypt";
  lw-restore = "lazywarden-decrypt --output ${secureRestoreDir}";
}
