# Work profile Homebrew overrides.
#
# Keep this file focused on differences from common.nix. Shared packages belong
# in darwin/homebrew-packages/; work-only additions or removals belong here.

(import ./lib.nix).mkProfile {
  extraBrews = [ "newrelic-cli" ];

  # Example:
  # extraCasks = [ "microsoft-office" "slack" ];
  # removeCasks = [ "discord" "spotify" "whatsapp" ];
}
