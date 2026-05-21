# home-manager/aliases/homelab.nix
#
# Homelab and self-hosted service aliases.

{ config, ... }:
let
  secureRestoreDir = "${config.home.homeDirectory}/Secure/lazywarden-restore";
in
{
  # Msgvault remote archive
  mv = "msgvault-remote";
  mvt = "msgvault-remote";
  mvstats = "msgvault-remote stats";
  mvaccounts = "msgvault-remote list-accounts";
  mvsearch = "msgvault-remote search";
  mvp = "msgvault-pick";
  mvat = "msgvault-pick-attachments";
  mva = "msgvault-pick-account";
  mvhealth = "msgvault-api GET /health";
  mvscheduler = "msgvault-api GET /api/v1/scheduler/status | jq";
  mvvector = "msgvault-api GET /api/v1/stats | jq '.vector_search'";
  mvhybrid = "msgvault-api-search hybrid";
  mvsemantic = "msgvault-api-search vector";
  mvkey = "msgvault-api-key";
  mvrotate = "msgvault-rotate-key";
  mvschedule = "msgvault-schedule-sync";

  # Lazywarden backup recovery
  lwdec = "lazywarden-decrypt";
  lw-decrypt = "lazywarden-decrypt";
  lw-restore = "lazywarden-decrypt --output ${secureRestoreDir}";
}
