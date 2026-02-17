#!/usr/bin/env bash
#
# Onboarding Full Checklist
# Runs smoke checks and validates core onboarding guardrails.
#
# Usage:
#   ./scripts/testing/onboarding-full-checklist.sh
#   ./scripts/testing/onboarding-full-checklist.sh --print-only

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

PRINT_ONLY=0
if [[ "${1:-}" == "--print-only" ]]; then
  PRINT_ONLY=1
fi

HAS_FAILURES=0

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  HAS_FAILURES=1
}

check_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if rg -n "$pattern" "$file" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label"
  fi
}

run_guardrail_checks() {
  check_contains \
    ./setup.sh \
    'DOTFILES_REPO_URL is required in non-interactive mode' \
    'setup.sh enforces DOTFILES_REPO_URL in non-interactive mode'

  check_contains \
    ./scripts/install/pre-nix-installation.sh \
    'safe_link_config_dir\(\)' \
    'installer has safe config-link helper'

  check_contains \
    ./scripts/install/pre-nix-installation.sh \
    'normalize_hostname\(\)' \
    'installer normalizes hostname for flake output'

  check_contains \
    ./flake.nix \
    'hosts\.nix not found\.' \
    'flake has clear missing host-config error'

  check_contains \
    ./home-manager/aliases/platform.nix \
    'userConfig\.hostname' \
    'darwin rebuild aliases use resolved host hostname'
}

print_vm_checklist() {
  cat <<'EOF'

Manual VM checklist (fresh macOS snapshot)
1. Clone repo to ~/Documents/dotfile.
2. Run setup in non-interactive mode:
   DOTFILES_REPO_URL=<your-repo-raw-url> ./setup.sh --yes
3. Confirm host config values:
   hosts.nix has username/fullName/githubUsername and host hostname/profile.
4. Run rebuild:
   sudo darwin-rebuild switch --flake .#<hostname-from-hosts.nix>
5. Validate key commands:
   rebuild
   health-check
   perf-analyze
   ./scripts/setup/validate-ssh.sh
6. Confirm links/backups:
   ~/.config/{nix,darwin,home-manager} are symlinked
   ~/.config-backups/dotfile-install-<timestamp>/ exists if prior config was present
7. Take pass/fail notes and reset VM snapshot.

EOF
}

run_guardrail_checks

if [[ "$PRINT_ONLY" -eq 0 ]]; then
  if ./scripts/testing/onboarding-smoke.sh --strict-shellcheck; then
    pass "smoke checks passed in strict mode"
  else
    fail "smoke checks failed in strict mode"
  fi
fi

print_vm_checklist

if [[ "$HAS_FAILURES" -eq 0 ]]; then
  pass "full onboarding checklist passed"
  exit 0
fi

fail "full onboarding checklist failed"
exit 1
