#!/usr/bin/env bash
#
# Documentation Stale Pattern Guardrail
# Catches old guidance after package and module ownership refactors.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

HAS_FAILURES=0

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  HAS_FAILURES=1
}

info() {
  printf '[INFO] %s\n' "$1"
}

check_no_matches() {
  local label="$1"
  local pattern="$2"
  shift 2

  local matches
  matches="$(rg -n --glob '!docs/archive/**' "$pattern" "$@" || true)"
  if [[ -n "$matches" ]]; then
    fail "$label"
    printf '%s\n' "$matches"
  fi
}

docs_scope=(
  README.md
  docs
  home-manager/aliases/README.md
)

repo_guidance_scope=(
  README.md
  .github/copilot-instructions.md
  docs
  home-manager/aliases/README.md
  scripts/setup
)

info "checking documentation stale patterns"

check_no_matches \
  "docs should not recommend installing AWS CLI with Homebrew" \
  'brew install awscli|AWSCLIV2\.pkg' \
  "${repo_guidance_scope[@]}"

check_no_matches \
  "docs should not refer to removed neofetch command" \
  'neofetch' \
  "${docs_scope[@]}"

check_no_matches \
  "docs should not point to old monolithic aliases file" \
  'home-manager/aliases\.nix' \
  "${docs_scope[@]}"

check_no_matches \
  "docs should not point to old Home Manager package aggregator" \
  'utility-packages\.nix' \
  "${repo_guidance_scope[@]}" \
  home-manager

# shellcheck disable=SC2016 # Literal regex: backticks are part of stale docs text.
check_no_matches \
  "docs should not show old Lazywarden command usage" \
  'decrypt_lazywarden\.py[[:space:]]+[^[:space:]]|`decrypt_lazywarden\.py` command still works' \
  "${docs_scope[@]}"

check_no_matches \
  "docs should not say migrated CLI tools stay in Homebrew" \
  '(duf|dust|fd|zoxide|sops|age|terraform-docs|tflint|shellcheck|glow|yq|tldr|awscli)[[:space:]]*\|[[:space:]]*❌[[:space:]]*\|[[:space:]]*Keep Homebrew' \
  "${docs_scope[@]}"

# shellcheck disable=SC2016 # Literal regex: backticks are part of stale docs text.
check_no_matches \
  "docs should not tell users to edit darwin/homebrew.nix package lists directly" \
  'Add to `darwin/homebrew\.nix` casks|# In darwin/homebrew\.nix|# Add to darwin/homebrew\.nix|vim[[:space:]]+[^#]*darwin/homebrew\.nix[[:space:]]+# Add|`darwin/homebrew\.nix` - Python 3\.12' \
  "${repo_guidance_scope[@]}"

# shellcheck disable=SC2016 # Literal regex: $profile is stale docs text.
check_no_matches \
  "docs and setup scripts should not recommend eval for AWS credential exports" \
  'eval[[:space:]]+["]?\$?\(?aws configure export-credentials|Copy and paste these commands to export credentials|AWS Credentials for \$profile|export-credentials --format env > \.env' \
  "${repo_guidance_scope[@]}"

if [[ "$HAS_FAILURES" -eq 0 ]]; then
  pass "documentation has no stale refactor patterns"
  exit 0
fi

fail "documentation stale pattern guardrail failed"
exit 1
