# Profile Surface

This repo has two workstation profiles: `work` and `personal`.

Profile selection starts in `hosts.nix`. Darwin uses that host entry to choose
Homebrew overrides from `darwin/profiles/`, while Home Manager modules use
`home-manager/config/profile.nix` for profile-aware behavior.

## Current Work-Only Behavior

- `home-manager/scripts/work.zsh` is sourced only for the work profile.
- Tmux shows the AWS VPN status segment only for the work profile.
- Work and personal Homebrew differences belong in `darwin/profiles/work.nix`
  and `darwin/profiles/personal.nix`.

## Rules

- Shared workstation behavior belongs in common modules, not profile files.
- Profile files should only describe differences.
- Home Manager modules should import `home-manager/config/profile.nix` instead
  of comparing `userConfig.profile` directly.
- Work-only shell helpers belong in `home-manager/scripts/work.zsh`.
