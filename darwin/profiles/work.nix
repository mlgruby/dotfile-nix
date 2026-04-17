# Work profile Homebrew overrides.
#
# Keep this file focused on differences from common.nix. Shared packages belong
# in darwin/homebrew-packages/; work-only additions or removals belong here.

(import ./lib.nix).mkProfile {
  # Example:
  # extraCasks = [ "microsoft-office" "slack" ];
  # removeCasks = [ "discord" "spotify" "whatsapp" ];
}
