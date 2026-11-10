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
- `home-manager/scripts/zsh-integration.zsh` - interactive zsh behavior (`p` project workspace launcher, `cb`/`rc` clipboard wrappers, fzf bindings).
- `home-manager/modules/ghostty.nix` - primary Ghostty terminal configuration (`tmux` + `herdr` session entrypoint).
- `home-manager/modules/herdr.nix` - Herdr TUI session manager configuration.
- `home-manager/modules/alacritty/` - secondary Alacritty terminal configuration.
- `home-manager/modules/starship.nix` - prompt configuration.
- `home-manager/modules/tmux.nix` - tmux wiring and status script installation.
- `home-manager/scripts/tmux/status/` - tmux status modules (CPU, RAM, disk, battery, GitHub status `github.sh`, AI usage `codexbar.sh`).

## AI Agents And Skills

- `home-manager/agent-extras/flake.nix` - child flake locking upstream AI skill and plugin repositories (`flake = false`).
- `home-manager/modules/plugins.nix` - declarative skill/plugin installation into `~/.claude`, `~/.agents`, and `~/.gemini/config`.
- `home-manager/modules/claude-code.nix` - declarative Claude Code configuration (`~/.claude/settings.json`, AWS Bedrock profile, statusline, MCPs) while using the native `~/.local/bin/claude` binary (`package = null`).
- `home-manager/modules/antigravity.nix` - Google Antigravity CLI (`agy`) configuration and `agr` (`agy-resume`) picker.
- `home-manager/modules/pi.nix` - Pi coding agent wrapper (`pil`, `pig`, `pib`) and local LLM configuration.
- `home-manager/modules/packages/development.nix` - includes `px0` interactive terminal code navigator (`nav`, `navo`, `px`), `ccusage`, `delta`, `pngpaste`, and CLI dev utilities.

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
- `home-manager/modules/aws-sso.nix` - declarative AWS SSO accounts, profiles, and config wiring.
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

## Runbooks And Operational Artifacts

- `docs/runbooks/homelab/` - procedures for external systems such as monitoring,
  Grafana, Paperless, Uptime Kuma, and Proxmox.

## Testing And Guardrails

- `scripts/testing/` - smoke tests and repository guardrails.
- `nix flake check --no-build` - primary Nix evaluation check.

## Archive

- `docs/archive/` - historical analysis and superseded documentation. Files here
  should not be treated as current instructions.
