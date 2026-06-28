# Development formulae intentionally owned by Homebrew.
#
# Prefer Home Manager for user-level CLI tools. Keep tools here only when their
# Homebrew installation is the deliberate global source of truth.
[
  "herdr" # nixpkgs build broken on aarch64-darwin (DarwinSdkNotFound in Zig/Ghostty dep)
  "yamlresume" # Not in nixpkgs
]
