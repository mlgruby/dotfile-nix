#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  cleanup           Run regular system cleanup
  cleanup --docker  Remove unused Docker data, including unused images
  cleanup --deep    Run regular cleanup plus Docker cleanup
  cleanup --help    Show this help
USAGE
}

confirm() {
  local prompt="$1"
  local answer
  printf "%s [y/N] " "$prompt"
  read -r answer
  [[ "$answer" = [Yy] || "$answer" = [Yy][Ee][Ss] ]]
}

get_available_kb() {
  df -k / | awk 'NR==2 { print $4 }'
}

format_kb_delta() {
  local before_kb="$1"
  local after_kb="$2"
  local diff_kb=$((after_kb - before_kb))
  if (( diff_kb <= 0 )); then
    echo "0 MiB"
  elif (( diff_kb >= 1048576 )); then
    awk -v kb="$diff_kb" 'BEGIN { printf "%.2f GiB\n", kb / 1048576 }'
  else
    awk -v kb="$diff_kb" 'BEGIN { printf "%.1f MiB\n", kb / 1024 }'
  fi
}

run_regular_cleanup() {
  echo "Starting regular system cleanup..."

  echo "Running Nix garbage collection (user & system generations)..."
  nix-collect-garbage -d --option max-jobs auto --option cores 0
  sudo nix-collect-garbage -d --option max-jobs auto --option cores 0
  echo "Nix garbage collection complete"

  echo "Cleaning macOS metadata files in workspace directories..."
  local dir
  for dir in "$HOME/Desktop" "$HOME/Documents" "$HOME/Downloads" "$HOME/Development" "$HOME/dotfile"; do
    if [ -d "$dir" ]; then
      find "$dir" \( -name ".git" -o -name "node_modules" -o -name ".direnv" -o -name ".venv" \) -prune \
        -o -type f -name ".DS_Store" -delete 2>/dev/null || true
      if [ -x /usr/sbin/dot_clean ]; then
        /usr/sbin/dot_clean -m "$dir" 2>/dev/null || true
      fi
    fi
  done

  echo "Cleaning screenshots..."
  if [ -d "$HOME/Screenshots" ]; then
    find "$HOME/Screenshots" -type f -name "*.png" -exec /usr/bin/trash {} + 2>/dev/null || true
  fi
  if [ -d "$HOME/Desktop" ]; then
    find "$HOME/Desktop" -type f -name "Screenshot *.png" -exec /usr/bin/trash {} + 2>/dev/null || true
  fi

  echo "Cleaning package caches..."
  if command -v npm >/dev/null 2>&1; then
    npm cache clean --force 2>/dev/null || true
  fi

  if command -v brew >/dev/null 2>&1; then
    HOMEBREW_NO_CLEANUP_FORMULAE="${HOMEBREW_NO_CLEANUP_FORMULAE:+$HOMEBREW_NO_CLEANUP_FORMULAE,}herdr" \
      brew autoremove 2>/dev/null || true
    HOMEBREW_NO_CLEANUP_FORMULAE="${HOMEBREW_NO_CLEANUP_FORMULAE:+$HOMEBREW_NO_CLEANUP_FORMULAE,}herdr" \
      brew cleanup --prune=all 2>/dev/null || true
  fi

  if command -v uv >/dev/null 2>&1; then
    uv cache clean 2>/dev/null || true
  elif [ -x "$HOME/.local/bin/uv" ]; then
    "$HOME/.local/bin/uv" cache clean 2>/dev/null || true
  fi

  echo "Optimizing Nix store..."
  nix store optimise --option max-jobs auto --option cores 0

  echo "Regular cleanup complete"
}

print_completion_note() {
  local before_kb="$1"
  local after_kb
  after_kb="$(get_available_kb)"
  echo "Disk space reclaimed: $(format_kb_delta "$before_kb" "$after_kb")"
  echo "Cleanup complete. Start a new shell manually if you want to refresh the environment."
}

run_docker_cleanup() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is not installed or not on PATH."
    return 0
  fi

  echo "Cleaning Docker unused data..."
  docker system prune -a --force
  echo "Docker cleanup complete"
}

case "${1:-}" in
  "")
    if confirm "Run regular cleanup? This removes old generations and package caches."; then
      before_kb="$(get_available_kb)"
      run_regular_cleanup
      print_completion_note "$before_kb"
    else
      echo "Cleanup cancelled."
    fi
    ;;
  --docker)
    if confirm "Run Docker cleanup? This removes all unused images, containers, networks, and build cache."; then
      before_kb="$(get_available_kb)"
      run_docker_cleanup
      after_kb="$(get_available_kb)"
      echo "Disk space reclaimed: $(format_kb_delta "$before_kb" "$after_kb")"
    else
      echo "Docker cleanup cancelled."
    fi
    ;;
  --deep)
    if confirm "Run deep cleanup? This runs regular cleanup plus Docker cleanup."; then
      before_kb="$(get_available_kb)"
      run_regular_cleanup
      run_docker_cleanup
      print_completion_note "$before_kb"
    else
      echo "Deep cleanup cancelled."
    fi
    ;;
  --help | -h)
    usage
    ;;
  *)
    echo "Unknown cleanup option: $1" >&2
    usage >&2
    exit 2
    ;;
esac
