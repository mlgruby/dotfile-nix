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
  "darwin/homebrew-packages/brews/core.nix"
  "darwin/homebrew-packages/brews/development.nix"
  "darwin/homebrew-packages/brews/toolchains.nix"
  "darwin/profiles/common.nix"
  "darwin/profiles/personal.nix"
  "darwin/profiles/work.nix"
)

# Format: brew-formula|nix-pname|declarative-owner
home_manager_owned=(
  "age|age|home-manager/modules/packages/security.nix"
  "aws-iam-authenticator|aws-iam-authenticator|home-manager/modules/packages/cloud.nix"
  "awscli|awscli2|home-manager/modules/packages/cloud.nix"
  "duckdb|duckdb|home-manager/modules/packages/development.nix"
  "duf|duf|home-manager/modules/packages/system.nix"
  "dust|du-dust|home-manager/modules/packages/system.nix via pkgs.dust"
  "fd|fd|home-manager/modules/packages/system.nix"
  "fzf|fzf|home-manager/modules/zsh.nix via programs.fzf"
  "git-lfs|git-lfs|home-manager/modules/git.nix via programs.git.lfs"
  "glow|glow|home-manager/modules/packages/text.nix"
  "helm|kubernetes-helm|home-manager/modules/packages/cloud.nix"
  "hyperfine|hyperfine|home-manager/modules/packages/development.nix"
  "jq|jq|home-manager/modules/programs/jq.nix via programs.jq"
  "libpq|postgresql|home-manager/modules/packages/development.nix"
  "lsof|lsof|home-manager/modules/packages/system.nix"
  "netcat|libressl|home-manager/modules/packages/system.nix via pkgs.netcat"
  "neofetch|fastfetch|home-manager/modules/packages/system.nix"
  "nmap|nmap|home-manager/modules/packages/system.nix"
  "poppler|poppler-utils|home-manager/modules/packages/text.nix"
  "postgresql|postgresql|home-manager/modules/packages/development.nix"
  "shellcheck|ShellCheck|home-manager/modules/packages/development.nix via pkgs.shellcheck"
  "sops|sops|home-manager/modules/packages/security.nix"
  "terraform-docs|terraform-docs|home-manager/modules/packages/cloud.nix"
  "tflint|tflint|home-manager/modules/packages/cloud.nix"
  "tldr|tealdeer|home-manager/modules/programs/terminal-tools.nix"
  "tree|tree|home-manager/modules/packages/system.nix"
  "watch|procps|home-manager/modules/packages/system.nix via pkgs.watch"
  "yq|yq-go|home-manager/modules/packages/text.nix"
  "zoxide|zoxide|home-manager/modules/zsh.nix via programs.zoxide"
)

check_file_exists() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    fail "package ownership check missing expected file: $file"
  fi
}

check_package_not_in_darwin_system() {
  local package="$1"
  local owner="$2"

  if jq -e --arg package "$package" \
    'to_entries[] | select(.value | index($package))' \
    <<< "$darwin_system_packages" >/dev/null; then
    fail "Nix package '$package' is owned by $owner, but appears in a Darwin system profile"
  fi
}

active_brew_lines() {
  local file="$1"
  awk '
    /^[[:space:]]*#/ { next }
    inRemove && /\]/ { inRemove = 0; next }
    /removeBrews[[:space:]]*=/ {
      if ($0 !~ /\]/) {
        inRemove = 1
      }
      next
    }
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

darwin_system_packages="$(
  nix eval --json .#darwinConfigurations --apply \
    'configs: builtins.mapAttrs (_: cfg: map (package: package.pname or package.name or "") cfg.config.environment.systemPackages) configs'
)"

for entry in "${home_manager_owned[@]}"; do
  formula="${entry%%|*}"
  remainder="${entry#*|}"
  nix_package="${remainder%%|*}"
  owner="${remainder#*|}"
  check_formula_not_in_homebrew "$formula" "$owner"
  check_package_not_in_darwin_system "$nix_package" "$owner"
done

if [[ "$HAS_FAILURES" -eq 0 ]]; then
  pass "Home Manager-owned packages are absent from Homebrew brews"
  exit 0
fi

fail "package ownership guardrail failed"
exit 1
