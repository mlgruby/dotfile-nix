#!/usr/bin/env bash
# rebuild-system.sh - Profile-aware darwin rebuild wrapper
#
# Usage:
#   rebuild-system.sh [--work|--personal|--current] [extra darwin-rebuild args]
#
# Behavior:
# - default / --current: uses CURRENT_CONFIG_HOST if provided (from alias wiring)
# - --work: uses hosts.work.hostname from hosts.nix
# - --personal: uses hosts.personal.hostname from hosts.nix

set -euo pipefail

DOTFILE_DIR="${DOTFILE_DIR:-$HOME/Documents/dotfile}"
CURRENT_CONFIG_HOST="${CURRENT_CONFIG_HOST:-}"
HOSTS_FILE="$DOTFILE_DIR/hosts.nix"

usage() {
  cat <<'EOF'
Usage: rebuild [--work|--personal|--current] [extra darwin-rebuild args]

Examples:
  rebuild
  rebuild --work
  rebuild --personal --show-trace
EOF
}

read_profile_hostname() {
  local profile="$1"
  nix eval --raw -f "$HOSTS_FILE" "hosts.${profile}.hostname" 2>/dev/null || return 1
}

normalize_hostname() {
  local raw="$1"
  raw="${raw%%.*}"
  raw="${raw//_/-}"
  raw="$(echo "$raw" | tr -cd '[:alnum:]-')"
  raw="$(echo "$raw" | sed -E 's/-+/-/g; s/^-+//; s/-+$//')"
  echo "$raw"
}

resolve_current_host() {
  if [[ -n "$CURRENT_CONFIG_HOST" ]]; then
    echo "$CURRENT_CONFIG_HOST"
    return 0
  fi

  local machine_host
  machine_host="$(normalize_hostname "$(scutil --get LocalHostName 2>/dev/null || hostname -s)")"

  local work_host personal_host
  work_host="$(read_profile_hostname "work" || true)"
  personal_host="$(read_profile_hostname "personal" || true)"

  if [[ -n "$machine_host" && "$machine_host" == "$work_host" ]]; then
    echo "$work_host"
    return 0
  fi

  if [[ -n "$machine_host" && "$machine_host" == "$personal_host" ]]; then
    echo "$personal_host"
    return 0
  fi

  return 1
}

if [[ ! -f "$HOSTS_FILE" ]]; then
  echo "Error: hosts.nix not found at: $HOSTS_FILE" >&2
  exit 1
fi

mode="current"
extra_args=()

for arg in "$@"; do
  case "$arg" in
    --work)
      mode="work"
      ;;
    --personal)
      mode="personal"
      ;;
    --current)
      mode="current"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      extra_args+=("$arg")
      ;;
  esac
done

target_host=""
case "$mode" in
  work)
    target_host="$(read_profile_hostname "work")"
    ;;
  personal)
    target_host="$(read_profile_hostname "personal")"
    ;;
  current)
    target_host="$(resolve_current_host || true)"
    ;;
esac

if [[ -z "$target_host" ]]; then
  echo "Error: Unable to resolve rebuild target for mode '$mode'." >&2
  echo "Hint: ensure hosts.nix has hosts.work/hosts.personal and use --work or --personal." >&2
  exit 1
fi

echo "Building system configuration for target: $target_host"
cd "$DOTFILE_DIR"
sudo darwin-rebuild switch --flake ".#$target_host" "${extra_args[@]}"
echo "System rebuild complete for: $target_host"
