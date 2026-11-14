#!/usr/bin/env bash
#
# Pre-PR Local Validation
# Runs all repository guardrails, shell/Zsh syntax checks, Herdr unit tests,
# and Nix flake evaluation locally before opening or updating a PR.
#
# Usage:
#   ./scripts/testing/pre-pr-check.sh
#   ./scripts/testing/pre-pr-check.sh --build   # Also run full `nix flake check` builds

set -euo pipefail

RUN_FULL_BUILD=0
for arg in "$@"; do
  case "$arg" in
    --build)
      RUN_FULL_BUILD=1
      ;;
    *)
      printf 'Unknown argument: %s\n' "$arg" >&2
      exit 2
      ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

printf '[INFO] running pre-PR local checks from %s\n' "$ROOT_DIR"

./scripts/testing/onboarding-smoke.sh --strict-shellcheck

shopt -s nullglob
zsh_files=(home-manager/scripts/*.zsh devcontainer-shell/*.zsh)
shopt -u nullglob

for zsh_file in "${zsh_files[@]}"; do
  zsh -n "$zsh_file"
done
printf '[PASS] Zsh syntax check passed (%d files)\n' "${#zsh_files[@]}"

PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s home-manager/modules/herdr
printf '[PASS] Herdr Python unit tests passed\n'

if [[ "$RUN_FULL_BUILD" -eq 1 ]]; then
  nix flake check
  printf '[PASS] full nix flake check build passed\n'
fi

printf '[PASS] all pre-PR local checks passed\n'
