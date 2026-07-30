#!/usr/bin/env bash
#
# Nix Policy Ownership Guardrail
# Keeps compatibility and package-set policy in one authoritative module.

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

check_single_owner() {
  local label="$1"
  local pattern="$2"
  shift 2

  local matches
  local count
  matches="$(rg -n "$pattern" "$@" || true)"
  count="$(printf '%s\n' "$matches" | awk 'NF { count++ } END { print count + 0 }')"

  if [[ "$count" -eq 1 ]]; then
    pass "$label"
  else
    fail "$label (expected one declaration, found $count)"
    [[ -z "$matches" ]] || printf '%s\n' "$matches"
  fi
}

check_single_owner \
  "nix-darwin state version has one owner" \
  '^[[:space:]]*(system\.)?stateVersion[[:space:]]*=' \
  darwin

check_single_owner \
  "Home Manager state version has one owner" \
  '^[[:space:]]*(home\.)?stateVersion[[:space:]]*=[[:space:]]*"24\.05";' \
  flake.nix home-manager/default.nix

check_single_owner \
  "allowUnfree policy has one owner" \
  '^[[:space:]]*(nixpkgs\.)?(config\.)?allowUnfree[[:space:]]*=' \
  flake.nix darwin

check_single_owner \
  "host platform has one owner" \
  '^[[:space:]]*(nixpkgs\.)?hostPlatform[[:space:]]*=' \
  flake.nix darwin

check_single_owner \
  "nixpkgs policy is applied once" \
  '^[[:space:]]*nixpkgs[[:space:]]*=[[:space:]]*nixpkgsConfig;' \
  flake.nix darwin

if rg -n 'stateVersion[[:space:]]*=[^;]*mkForce|mkForce[^;]*stateVersion' flake.nix darwin home-manager/default.nix; then
  fail "state versions must not be hidden behind mkForce"
else
  pass "state versions do not use mkForce"
fi

effective_policy_expr='configs:
  let
    values = builtins.attrValues configs;
    valid = cfg:
      cfg.config.system.stateVersion == 4
      && cfg.pkgs.stdenv.hostPlatform.system == "aarch64-darwin"
      && cfg.config.nixpkgs.config.allowUnfree
      && cfg.config.home-manager.users.${cfg.config.system.primaryUser}.home.stateVersion == "24.05";
  in
  if builtins.all valid values then "ok" else throw "unexpected effective Nix policy"'

if [[ "$(nix eval --raw .#darwinConfigurations --apply "$effective_policy_expr")" == "ok" ]]; then
  pass "effective Nix policy matches every configured host"
else
  fail "effective Nix policy does not match every configured host"
fi

if [[ "$HAS_FAILURES" -eq 0 ]]; then
  pass "Nix policy ownership passed"
  exit 0
fi

fail "Nix policy ownership failed"
exit 1
