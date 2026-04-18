# Refactoring Backlog

This is the current refactoring backlog. Historical audit notes live in
`docs/archive/`.

## Completed In This Refactor Series

- Consolidated Homebrew package ownership and guardrails.
- Consolidated macOS defaults ownership into `darwin/macos-defaults.nix`.
- Consolidated Nix daemon/settings ownership into `darwin/nix-settings.nix`.
- Refactored system monitoring launchd paths and helpers.
- Removed the unused Home Manager config compatibility aggregator.
- Declared stable macOS Finder, locale, Dock, text-input, and trackpad defaults.
- Moved LazyVim bootstrap logic into a dedicated script.
- Reduced bootstrap shell config to minimal pre-Home-Manager helpers.
- Added confirmation before broad cleanup and maintenance commands.

## Remaining Ideas

- Revisit whether LazyVim should stay mutable or become fully declarative.
- Keep AWS SSO standalone setup only if non-Nix users still need it.
- Continue moving complex aliases into scripts when quoting or prompts grow.
- Review scheduled monitoring after a week of logs to tune cadence and noise.
