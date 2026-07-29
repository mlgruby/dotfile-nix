#!/usr/bin/env bash
# Update pinned inputs, validate every host, then update Homebrew and activate.

set -euo pipefail

DOTFILE_DIR="${DOTFILE_DIR:-$HOME/Documents/dotfile}"
CURRENT_CONFIG_HOST="${CURRENT_CONFIG_HOST:-}"
LOCK_BACKUP=""
UPDATE_COMPLETE=0
SKIP_HOMEBREW=0
REBUILD_ARGS=()

usage() {
  cat <<'EOF'
Usage: update [--work|--personal|--current] [--skip-homebrew] [darwin-rebuild args]

The update is staged:
  1. Update root and agent-extra lock files
  2. Run repository checks
  3. Build every configured host
  4. Upgrade Homebrew
  5. Activate the selected host
EOF
}

restore_locks() {
  if [[ "$UPDATE_COMPLETE" -eq 0 && -n "$LOCK_BACKUP" ]]; then
    echo "Update failed; restoring the last working Nix lock files." >&2
    cp "$LOCK_BACKUP/root.lock" "$DOTFILE_DIR/flake.lock"
    cp "$LOCK_BACKUP/agent-extras.lock" \
      "$DOTFILE_DIR/home-manager/agent-extras/flake.lock"
  fi

  if [[ -n "$LOCK_BACKUP" ]]; then
    rm -rf "$LOCK_BACKUP"
  fi
}

for arg in "$@"; do
  case "$arg" in
    --skip-homebrew)
      SKIP_HOMEBREW=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      REBUILD_ARGS+=("$arg")
      ;;
  esac
done

cd "$DOTFILE_DIR"
LOCK_BACKUP="$(mktemp -d)"
cp flake.lock "$LOCK_BACKUP/root.lock"
cp home-manager/agent-extras/flake.lock "$LOCK_BACKUP/agent-extras.lock"
trap restore_locks EXIT

echo "Stage 1/5: updating pinned Nix inputs"
nix flake update --flake "$DOTFILE_DIR/home-manager/agent-extras"
nix flake update --flake "$DOTFILE_DIR"

echo "Stage 2/5: running repository checks"
nix develop --command ./scripts/testing/onboarding-smoke.sh \
  --strict-shellcheck \
  --skip-flake-check

echo "Stage 3/5: building every configured host"
nix flake check --option sandbox relaxed

if [[ "$SKIP_HOMEBREW" -eq 0 ]]; then
  echo "Stage 4/5: updating Homebrew packages"
  brew update
  brew upgrade
else
  echo "Stage 4/5: skipping Homebrew update"
fi

echo "Stage 5/5: activating the selected host"
export DOTFILE_DIR CURRENT_CONFIG_HOST
bash "$DOTFILE_DIR/home-manager/scripts/rebuild-system.sh" "${REBUILD_ARGS[@]}"

UPDATE_COMPLETE=1
echo "System update complete."
