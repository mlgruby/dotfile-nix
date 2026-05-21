# Ownership Rules

These rules keep the dotfiles useful without letting one-off work turn into
permanent clutter.

## Repository Purpose

The repository configures the local workstation and exposes reusable workflows.
It should not become the source of truth for every external system operation.

## Module Responsibilities

- Nix modules configure state.
- Shell scripts execute behavior.
- Aliases expose tiny entrypoints.
- Docs explain workflows.
- Runbooks operate external systems.
- Secrets are encrypted or generated locally, never committed in plaintext.

## Promotion Rules

A one-off command can become a script only when it is expected to be reused.
A script can become a Home Manager module only when it needs declarative files,
packages, activation, or profile-aware wiring.
An external-system procedure belongs in `docs/runbooks/` unless it must run from
the local workstation repeatedly.

## Profile Rules

Shared modules must stay profile-neutral. Work-only behavior belongs behind the
work profile or a clearly work-gated module. Personal machines should not inherit
work-specific labels, credentials, or VPN assumptions.

## Alias Rules

Aliases should be short and memorable. They should not hide long workflows with
stateful side effects. Put multi-step behavior in `home-manager/scripts/` and
make the alias call that script.

## Tmux Status Rules

The tmux status bar may show machine/session state, not per-command details that
already appear in the shell prompt. Segments should be conditional when possible
and cheap to compute. Network calls from the status bar are forbidden.

## Documentation Rules

README stays onboarding-first. Deep explanations belong in `docs/`. External
system operations belong in runbooks. Archived docs must not be linked as current
guidance.
