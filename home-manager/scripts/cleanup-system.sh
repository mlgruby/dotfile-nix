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

run_regular_cleanup() {
  echo "Starting regular system cleanup..."

  echo "Running Nix garbage collection..."
  nix-collect-garbage -d --option max-jobs auto --option cores 0
  echo "Nix garbage collection complete"

  echo "Cleaning macOS metadata files..."
  find "$HOME" -type f -name ".DS_Store" -delete 2>/dev/null || true
  find "$HOME" -type f -name "._*" -delete 2>/dev/null || true

  echo "Cleaning package caches..."
  if command -v npm >/dev/null 2>&1; then
    npm cache clean --force 2>/dev/null || true
  fi

  if command -v brew >/dev/null 2>&1; then
    brew cleanup --prune=all 2>/dev/null || true
  fi

  if command -v uv >/dev/null 2>&1; then
    uv cache clean 2>/dev/null || true
  elif [ -x "$HOME/.local/bin/uv" ]; then
    "$HOME/.local/bin/uv" cache clean 2>/dev/null || true
  fi

  echo "Running Nix store GC..."
  nix store gc --option max-jobs auto --option cores 0

  echo "Optimizing Nix store..."
  nix store optimise --option max-jobs auto --option cores 0

  echo "Regular cleanup complete"
}

print_completion_note() {
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
      run_regular_cleanup
      print_completion_note
    else
      echo "Cleanup cancelled."
    fi
    ;;
  --docker)
    if confirm "Run Docker cleanup? This removes all unused images, containers, networks, and build cache."; then
      run_docker_cleanup
    else
      echo "Docker cleanup cancelled."
    fi
    ;;
  --deep)
    if confirm "Run deep cleanup? This runs regular cleanup plus Docker cleanup."; then
      run_regular_cleanup
      run_docker_cleanup
      print_completion_note
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
