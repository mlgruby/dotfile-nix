#!/usr/bin/env bash
# gpg-github.sh
#
# Configure Git commit signing with GPG and upload public keys to GitHub.
# This script is local-only:
# - It writes signing config to ~/.gitconfig-work and/or ~/.gitconfig-personal
# - It does NOT modify tracked files (e.g., hosts.nix)
#
# Usage:
#   ./scripts/setup/gpg-github.sh --work
#   ./scripts/setup/gpg-github.sh --personal
#   ./scripts/setup/gpg-github.sh --all

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TARGET_SCOPE="all"
FULL_NAME=""
KEY_EXPIRY="2y"

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
  cat <<'EOF'
Usage:
  ./scripts/setup/gpg-github.sh --work
  ./scripts/setup/gpg-github.sh --personal
  ./scripts/setup/gpg-github.sh --all

Options:
  --work        Configure work profile only (~/.gitconfig-work)
  --personal    Configure personal profile only (~/.gitconfig-personal)
  --all         Configure both profiles (default)
  --help        Show this help

Behavior:
  - Uses email from ~/.gitconfig-work or ~/.gitconfig-personal (prompts if missing)
  - Generates signing key if none exists for the email
  - Uploads public key to GitHub via gh CLI
  - Sets user.signingkey + commit.gpgsign in the selected ~/.gitconfig-* file(s)
EOF
}

is_valid_email() {
  [[ "${1:-}" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]
}

ensure_gnupg_permissions() {
  local gnupg_dir="$HOME/.gnupg"
  mkdir -p "$gnupg_dir"
  chmod 700 "$gnupg_dir"
  find "$gnupg_dir" -type d -exec chmod 700 {} \;
  find "$gnupg_dir" -type f -exec chmod 600 {} \;
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "Missing required command: $cmd"
    exit 1
  fi
}

check_prerequisites() {
  log_info "Checking prerequisites..."
  require_command gpg
  require_command gh
  require_command git
  require_command mktemp
  ensure_gnupg_permissions

  if ! gh auth status >/dev/null 2>&1; then
    log_warning "GitHub CLI is not authenticated."
    read -r -p "Run 'gh auth login' now? (y/N): " reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      gh auth login
    else
      log_error "GitHub authentication required. Run: gh auth login"
      exit 1
    fi
  fi

  log_success "Prerequisites check passed"
}

resolve_full_name() {
  FULL_NAME="$(git config --global --get user.name || true)"
  if [[ -z "$FULL_NAME" ]]; then
    read -r -p "Enter full name for GPG keys: " FULL_NAME
  fi
  if [[ -z "$FULL_NAME" ]]; then
    log_error "Full name is required."
    exit 1
  fi
}

scope_gitconfig_path() {
  local scope="$1"
  echo "$HOME/.gitconfig-$scope"
}

resolve_scope_email() {
  local scope="$1"
  local cfg
  cfg="$(scope_gitconfig_path "$scope")"
  local scope_label
  scope_label="$(echo "$scope" | tr '[:lower:]' '[:upper:]')"
  local email
  email="$(git config -f "$cfg" --get user.email || true)"

  if [[ -z "$email" ]]; then
    read -r -p "Enter ${scope_label} email for Git commits: " email
  fi

  while ! is_valid_email "$email"; do
    log_warning "Invalid email format."
    read -r -p "Enter ${scope_label} email for Git commits: " email
  done

  echo "$email"
}

find_secret_key_for_email() {
  local email="$1"
  gpg --list-secret-keys --with-colons "$email" 2>/dev/null | awk -F: '$1=="sec"{print $5; exit}'
}

generate_signing_key() {
  local email="$1"
  local uid="${FULL_NAME} <${email}>"
  log_info "Generating GPG signing key for ${uid}..."
  gpg --quick-generate-key "$uid" ed25519 sign "$KEY_EXPIRY"
}

export_public_key_to_file() {
  local key_id="$1"
  local out_file="$2"
  gpg --armor --export "$key_id" > "$out_file"
}

upload_key_to_github() {
  local key_id="$1"
  local scope="$2"
  local tmp_file
  tmp_file="$(mktemp)"
  export_public_key_to_file "$key_id" "$tmp_file"

  local host_label
  host_label="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
  local key_name="gpg-${scope}-${host_label}"

  log_info "Uploading public key to GitHub for scope '${scope}'..."
  local upload_out
  if upload_out="$(gh api user/gpg_keys --method POST -F armored_public_key=@"$tmp_file" -f name="$key_name" 2>&1)"; then
    log_success "GPG key uploaded to GitHub"
  else
    if echo "$upload_out" | grep -Ei 'already (exists|in use|been taken)' >/dev/null 2>&1; then
      log_warning "GitHub already has this GPG key, continuing"
    else
      log_error "Failed to upload GPG key to GitHub"
      echo "$upload_out" >&2
      rm -f "$tmp_file"
      exit 1
    fi
  fi

  rm -f "$tmp_file"
}

configure_git_signing_for_scope() {
  local scope="$1"
  local email="$2"
  local key_id="$3"
  local cfg
  cfg="$(scope_gitconfig_path "$scope")"

  git config -f "$cfg" user.email "$email"
  git config -f "$cfg" user.signingkey "$key_id"
  git config -f "$cfg" commit.gpgsign true
  git config -f "$cfg" gpg.program gpg

  log_success "Configured $cfg"
}

test_key_signing() {
  local key_id="$1"
  if echo "signing-check" | gpg --clearsign --local-user "$key_id" >/dev/null 2>&1; then
    log_success "GPG signing test passed for key: $key_id"
  else
    log_error "GPG signing test failed for key: $key_id"
    exit 1
  fi
}

configure_scope() {
  local scope="$1"
  log_info "Configuring scope: $scope"

  local email
  email="$(resolve_scope_email "$scope")"

  local key_id
  key_id="$(find_secret_key_for_email "$email" || true)"
  if [[ -n "$key_id" ]]; then
    log_success "Found existing key for $email: $key_id"
  else
    log_warning "No existing key found for $email"
    generate_signing_key "$email"
    key_id="$(find_secret_key_for_email "$email" || true)"
    if [[ -z "$key_id" ]]; then
      log_error "Failed to resolve key ID after generation for $email"
      exit 1
    fi
    log_success "Generated new key for $email: $key_id"
  fi

  upload_key_to_github "$key_id" "$scope"
  configure_git_signing_for_scope "$scope" "$email" "$key_id"
  test_key_signing "$key_id"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --work)
        TARGET_SCOPE="work"
        shift
        ;;
      --personal)
        TARGET_SCOPE="personal"
        shift
        ;;
      --all)
        TARGET_SCOPE="all"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done
}

print_summary() {
  log_success "GPG setup completed"
  echo
  echo "Configured files:"
  case "$TARGET_SCOPE" in
    work)
      echo "  - $HOME/.gitconfig-work"
      ;;
    personal)
      echo "  - $HOME/.gitconfig-personal"
      ;;
    all)
      echo "  - $HOME/.gitconfig-work"
      echo "  - $HOME/.gitconfig-personal"
      ;;
  esac
  echo
  echo "Verify in any repository:"
  echo "  git config --show-origin --get user.signingkey"
  echo "  git config --show-origin --get commit.gpgsign"
}

main() {
  parse_args "$@"

  echo -e "${BLUE}=== GPG + GitHub Signing Setup (Local Profiles) ===${NC}"
  check_prerequisites
  resolve_full_name

  case "$TARGET_SCOPE" in
    work)
      configure_scope "work"
      ;;
    personal)
      configure_scope "personal"
      ;;
    all)
      configure_scope "work"
      configure_scope "personal"
      ;;
  esac

  print_summary
}

main "$@"
