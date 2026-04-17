#!/usr/bin/env bash
#
# Package Ownership Guardrail
# Ensures Home Manager-owned CLI tools do not drift back into Homebrew.

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

homebrew_files=(
  "darwin/profiles/common.nix"
  "darwin/profiles/personal.nix"
  "darwin/profiles/work.nix"
)

# Format: brew-formula|declarative-owner
home_manager_owned=(
  "age|home-manager/modules/packages/security.nix"
  "aws-iam-authenticator|home-manager/modules/packages/cloud.nix"
  "awscli|home-manager/modules/packages/cloud.nix via pkgs.awscli2"
  "duckdb|home-manager/modules/packages/development.nix"
  "duf|home-manager/modules/packages/system.nix"
  "dust|home-manager/modules/packages/system.nix"
  "fd|home-manager/modules/packages/system.nix"
  "fzf|home-manager/modules/zsh.nix via programs.fzf"
  "git-lfs|home-manager/modules/git.nix via programs.git.lfs"
  "glow|home-manager/modules/packages/text.nix"
  "helm|home-manager/modules/packages/cloud.nix via pkgs.kubernetes-helm"
  "neofetch|home-manager/modules/packages/system.nix via pkgs.fastfetch"
  "poppler|home-manager/modules/packages/text.nix via pkgs.poppler-utils"
  "shellcheck|home-manager/modules/packages/development.nix"
  "sops|home-manager/modules/packages/security.nix"
  "terraform-docs|home-manager/modules/packages/cloud.nix"
  "tflint|home-manager/modules/packages/cloud.nix"
  "tldr|home-manager/modules/programs/terminal-tools.nix via programs.tealdeer"
  "yq|home-manager/modules/packages/text.nix via pkgs.yq-go"
  "zoxide|home-manager/modules/zsh.nix via programs.zoxide"
)

check_file_exists() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    fail "package ownership check missing expected file: $file"
  fi
}

active_brew_lines() {
  local file="$1"
  awk '
    /^[[:space:]]*#/ { next }
    inRemove && /\]/ { inRemove = 0; next }
    /removeBrews[[:space:]]*=/ { inRemove = 1; next }
    inRemove { next }
    { print }
  ' "$file"
}

check_formula_not_in_homebrew() {
  local formula="$1"
  local owner="$2"
  local file
  local matches

  for file in "${homebrew_files[@]}"; do
    check_file_exists "$file"
    [[ -f "$file" ]] || continue

    matches="$(active_brew_lines "$file" | rg -n "\"${formula}\"" || true)"
    if [[ -n "$matches" ]]; then
      fail "Homebrew formula '$formula' is owned by $owner, but appears in $file"
      printf '%s\n' "$matches"
    fi
  done
}

info "checking package ownership boundaries"

for entry in "${home_manager_owned[@]}"; do
  formula="${entry%%|*}"
  owner="${entry#*|}"
  check_formula_not_in_homebrew "$formula" "$owner"
done

if [[ "$HAS_FAILURES" -eq 0 ]]; then
  pass "Home Manager-owned packages are absent from Homebrew brews"
  exit 0
fi

fail "package ownership guardrail failed"
exit 1
