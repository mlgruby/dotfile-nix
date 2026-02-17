# Onboarding Test Plan

This plan validates that a new user can bootstrap and use the dotfiles on a
fresh macOS system.

## Automated Checks

Run from repository root:

```bash
./scripts/testing/onboarding-smoke.sh --strict-shellcheck
./scripts/testing/onboarding-full-checklist.sh --print-only
```

Automated checks include:

- `nix flake check --no-build`
- `bash -n` syntax checks for shell scripts
- `shellcheck` lint checks
- Documentation script-path validation
- Detection of stale onboarding references

## Manual VM Validation

Use a clean macOS VM snapshot and run:

```bash
DOTFILES_REPO_URL=<your-repo-raw-url> ./setup.sh --yes
sudo darwin-rebuild switch --flake .#<hostname-from-hosts.nix>
```

Then validate:

1. `rebuild`, `health-check`, and `perf-analyze` execute.
2. `./scripts/setup/validate-ssh.sh` runs and shows actionable guidance.
3. `~/.config/nix`, `~/.config/darwin`, and `~/.config/home-manager` are symlinked.
4. If prior config existed, backup directory `~/.config-backups/dotfile-install-<timestamp>/` is created.

## Pass Criteria

- All automated checks pass.
- VM setup completes without manual file surgery.
- First rebuild succeeds with configured hostname.
- Core aliases/scripts are available in a fresh terminal session.
