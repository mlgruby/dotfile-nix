# Dotfile Map

This repository is the workstation control plane. It configures macOS, Home
Manager, shell UX, development tools, work credentials, and homelab access.
Operational procedures belong in runbooks unless they are reusable local
workstation automation.

## Core Workstation

- `flake.nix`, `flake.lock` - flake inputs and host outputs.
- `hosts.nix`, `hosts.example.nix`, `lib/hosts.nix` - user and host inventory.
- `darwin/` - nix-darwin system configuration, macOS defaults, Homebrew, and
  system-level services.
- `home-manager/default.nix` - Home Manager entrypoint and import wiring.

## Shell And Terminal UX

- `home-manager/modules/zsh.nix` - zsh Home Manager options and small shell
  functions.
- `home-manager/scripts/zsh-integration.zsh` - interactive zsh behavior.
- `home-manager/modules/starship.nix` - prompt configuration.
- `home-manager/modules/tmux.nix` - tmux wiring and status script installation.
- `home-manager/scripts/tmux/status/` - tmux status modules.
- `home-manager/modules/alacritty/` - terminal configuration.

## Aliases

- `home-manager/aliases/` - short interactive entrypoints.
- Aliases should stay thin. Multi-step behavior belongs in scripts.

## Packages And Programs

- `home-manager/modules/package-groups.nix` - package group imports.
- `home-manager/modules/packages/` - Home Manager-owned CLI packages.
- `home-manager/modules/programs/` - program-specific configuration.
- `darwin/homebrew-packages/` - Homebrew-owned GUI apps, casks, taps, and
  toolchains that are better managed by Homebrew on macOS.

## Work Profile

- `darwin/profiles/work.nix` - work-specific system/Homebrew choices.
- `home-manager/config/aws.nix` - AWS account/profile naming.
- `home-manager/modules/aws-sso.nix` - declarative AWS config wiring.
- `home-manager/scripts/aws-sso.zsh` - AWS SSO and credentials workflow.
- `home-manager/scripts/work.zsh` - work shell helpers.

## Personal Profile

- `darwin/profiles/personal.nix` - personal machine system/Homebrew choices.
- Profile-specific behavior should live behind profile modules instead of being
  mixed into shared modules.

## Homelab Access

- `home-manager/config/ssh.nix` - homelab host inventory.
- `home-manager/modules/ssh.nix` - SSH client config generated from inventory.
- `home-manager/aliases/homelab.nix` - short homelab entrypoints.
- `home-manager/modules/msgvault.nix` and `home-manager/scripts/msgvault-*` -
  reusable local msgvault client integration.

## Runbooks And Operational Artifacts

- `docs/runbooks/homelab/` - procedures for external systems such as monitoring,
  Grafana, Paperless, Uptime Kuma, and Proxmox.
- `Grafana_dashboards/` - dashboard and alerting source artifacts. These are not
  workstation config, but they are tracked here as homelab operational assets.

## Testing And Guardrails

- `scripts/testing/` - smoke tests and repository guardrails.
- `.github/workflows/onboarding-checks.yml` - GitHub onboarding checks.
- `nix flake check --no-build` - primary Nix evaluation check.

## Archive

- `docs/archive/` - historical analysis and superseded documentation. Files here
  should not be treated as current instructions.
