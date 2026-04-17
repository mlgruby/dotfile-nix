# Personal profile Homebrew overrides.
#
# Keep this file focused on differences from common.nix. Shared packages belong
# in darwin/homebrew-packages/; personal-only additions or removals belong here.

(import ./lib.nix).mkProfile {
  # Example:
  # extraCasks = [ "spotify" "discord" ];
  # removeCasks = [ "microsoft-office" "slack" ];
}
