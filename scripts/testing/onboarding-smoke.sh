#!/usr/bin/env bash
#
# Onboarding Smoke Checks
# Runs fast, deterministic checks for onboarding reliability.
#
# Usage:
#   ./scripts/testing/onboarding-smoke.sh
#   ./scripts/testing/onboarding-smoke.sh --strict-shellcheck

set -euo pipefail

REQUIRE_SHELLCHECK=0
if [[ "${1:-}" == "--strict-shellcheck" ]]; then
  REQUIRE_SHELLCHECK=1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

HAS_FAILURES=0

info() {
  printf '[INFO] %s\n' "$1"
}

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  HAS_FAILURES=1
}

check_command() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    pass "command available: $cmd"
  else
    fail "missing command: $cmd"
  fi
}

collect_shell_files() {
  find ./scripts -type f -name '*.sh' | sort
  printf '%s\n' ./setup.sh
}

check_required_files() {
  local config_template_found=0
  local file
  for file in \
    ./setup.sh \
    ./flake.nix \
    ./scripts/install/pre-nix-installation.sh \
    ./scripts/setup/validate-ssh.sh; do
    if [[ -f "$file" ]]; then
      pass "required file exists: $file"
    else
      fail "required file missing: $file"
    fi
  done

  if [[ -f "./hosts.example.nix" ]]; then
    config_template_found=1
  fi

  if [[ "$config_template_found" -eq 1 ]]; then
    pass "required config template exists (hosts.example.nix preferred)"
  else
    fail "missing config template: expected hosts.example.nix"
  fi
}

check_shell_syntax() {
  local failed=0
  local file
  while IFS= read -r file; do
    if ! bash -n "$file"; then
      printf '[FAIL] bash syntax failed: %s\n' "$file"
      failed=1
    fi
  done < <(collect_shell_files)

  if [[ "$failed" -eq 0 ]]; then
    pass "bash syntax check passed"
  else
    HAS_FAILURES=1
  fi
}

check_shellcheck() {
  local shellcheck_cmd=()
  local shell_files=()
  local file

  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck_cmd=(shellcheck)
  elif command -v nix >/dev/null 2>&1; then
    shellcheck_cmd=(nix run nixpkgs#shellcheck --)
  else
    if [[ "$REQUIRE_SHELLCHECK" -eq 1 ]]; then
      fail "shellcheck is required but not installed"
    else
      info "shellcheck not installed; skipping lint"
    fi
    return
  fi

  while IFS= read -r file; do
    shell_files+=("$file")
  done < <(collect_shell_files)

  if "${shellcheck_cmd[@]}" -S warning "${shell_files[@]}"; then
    pass "shellcheck passed"
  else
    fail "shellcheck warnings/errors"
    HAS_FAILURES=1
  fi
}

check_nix_flake() {
  if ! command -v nix >/dev/null 2>&1; then
    fail "nix not installed; cannot run flake check"
    return
  fi

  if nix flake check --no-build; then
    pass "nix flake check --no-build passed"
  else
    fail "nix flake check --no-build failed"
  fi
}

check_script_references() {
  local refs
  local missing=0
  refs="$(rg -n -o '\./scripts/[A-Za-z0-9_./-]+\.sh' README.md docs scripts | awk -F: '{print $NF}' | sort -u)"

  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    if [[ ! -f "$ref" ]]; then
      printf '[FAIL] missing script reference target: %s\n' "$ref"
      missing=1
    fi
  done <<< "$refs"

  if [[ "$missing" -eq 0 ]]; then
    pass "docs script references resolve to files"
  else
    HAS_FAILURES=1
  fi
}

check_stale_patterns() {
  local scope=(README.md docs setup.sh scripts/setup/validate-ssh.sh)
  local patterns=(
    '\./validate-ssh\.sh'
    '\./scripts/system-health-monitor\.sh'
    '\./scripts/analyze-build-performance\.sh'
    'home-manager/aliases\.nix'
    'scripts/deploy\.sh'
  )
  local pattern
  local found=0

  for pattern in "${patterns[@]}"; do
    local matches
    matches="$(rg -n "$pattern" "${scope[@]}" || true)"
    if [[ -n "$matches" ]]; then
      printf '[FAIL] stale pattern found: %s\n' "$pattern"
      printf '%s\n' "$matches"
      found=1
    fi
  done

  if [[ "$found" -eq 0 ]]; then
    pass "no stale onboarding patterns found"
  else
    HAS_FAILURES=1
  fi
}

check_hosts_no_emails() {
  if [[ ! -f ./hosts.nix ]]; then
    info "hosts.nix not present; skipping email-leak check"
    return
  fi

  local matches
  matches="$(rg -n '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' ./hosts.nix || true)"
  if [[ -n "$matches" ]]; then
    fail "hosts.nix contains email-like values; keep emails in local ~/.gitconfig-* only"
    printf '%s\n' "$matches"
  else
    pass "hosts.nix contains no email-like values"
  fi
}

info "running onboarding smoke checks from $ROOT_DIR"
check_command bash
check_command rg
check_command nix
check_required_files
check_shell_syntax
check_shellcheck
check_nix_flake
check_script_references
check_stale_patterns
check_hosts_no_emails

if [[ "$HAS_FAILURES" -eq 0 ]]; then
  pass "onboarding smoke checks passed"
  exit 0
fi

fail "onboarding smoke checks failed"
exit 1
