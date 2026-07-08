#!/usr/bin/env bash

# setup-dev-env.sh - Automated Developer Environment Setup Script
#
# Purpose:
# - Installs Nix Package Manager (Determinate Systems) if missing
# - Installs direnv using system package manager if missing
# - Registers shell hooks for Bash, Zsh, and Fish
#

set -euo pipefail

# Helper formatting functions
info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[1;32m[SUCCESS]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*"; exit 1; }

info "Starting developer environment automation setup..."

# 1. Detect OS
OS_TYPE="$(uname -s)"
info "Detected Operating System: ${OS_TYPE}"

# 2. Install Nix Package Manager if missing
if ! command -v nix &>/dev/null; then
    info "Nix Package Manager not found. Installing Determinate Systems Nix Installer..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
    success "Nix Package Manager installed successfully!"
    
    # Load Nix profile path for current script execution
    if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
else
    success "Nix Package Manager is already installed."
fi

# 3. Install direnv if missing
if ! command -v direnv &>/dev/null; then
    info "direnv not found. Installing..."
    if [ "${OS_TYPE}" = "Darwin" ]; then
        if command -v brew &>/dev/null; then
            brew install direnv
        else
            info "Homebrew not found. Installing direnv via Nix..."
            nix-env -iA nixpkgs.direnv
        fi
    elif [ "${OS_TYPE}" = "Linux" ]; then
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y direnv
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y direnv
        else
            info "No supported package manager found. Installing direnv via Nix..."
            nix-env -iA nixpkgs.direnv
        fi
    fi
    success "direnv installed successfully!"
else
    success "direnv is already installed."
fi

# 4. Register Shell Hooks
USER_SHELL="$(basename "${SHELL:-/bin/bash}")"
info "Detected active user shell: ${USER_SHELL}"

hook_registered=false

case "${USER_SHELL}" in
    zsh)
        SHELL_RC="${HOME}/.zshrc"
        HOOK_CMD='eval "$(direnv hook zsh)"'
        if ! grep -q "direnv hook zsh" "${SHELL_RC}" 2>/dev/null; then
            echo -e "\n# direnv environment hook\n${HOOK_CMD}" >> "${SHELL_RC}"
            success "Registered direnv hook in ${SHELL_RC}"
            hook_registered=true
        fi
        ;;
    bash)
        SHELL_RC="${HOME}/.bashrc"
        HOOK_CMD='eval "$(direnv hook bash)"'
        if ! grep -q "direnv hook bash" "${SHELL_RC}" 2>/dev/null; then
            echo -e "\n# direnv environment hook\n${HOOK_CMD}" >> "${SHELL_RC}"
            success "Registered direnv hook in ${SHELL_RC}"
            hook_registered=true
        fi
        ;;
    fish)
        SHELL_RC="${HOME}/.config/fish/config.fish"
        HOOK_CMD='direnv hook fish | source'
        mkdir -p "$(dirname "${SHELL_RC}")"
        if ! grep -q "direnv hook fish" "${SHELL_RC}" 2>/dev/null; then
            echo -e "\n# direnv environment hook\n${HOOK_CMD}" >> "${SHELL_RC}"
            success "Registered direnv hook in ${SHELL_RC}"
            hook_registered=true
        fi
        ;;
    *)
        info "Unsupported shell (${USER_SHELL}). Please manually configure your shell hook."
        ;;
esac

if [ "${hook_registered}" = "false" ]; then
    info "Shell hook was already registered in your configuration file."
fi

success "Developer onboarding setup complete! Please restart your terminal window."
