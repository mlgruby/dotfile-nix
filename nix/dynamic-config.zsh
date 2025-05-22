# nix/dynamic-config.zsh
#
# Dynamic ZSH configurations and functions
#
# Purpose:
# - Provides interactive shell functions
# - Manages dynamic configurations
# - Enhances shell experience with FZF
#
# Installation:
# - Used by @pre-nix-installation.sh
# - Copied to ~/.dynamic-config.zsh during setup
# - Part of initial Nix bootstrap (with nix.conf and zshrc)
#
# Related Files:
# - nix/nix.conf: Core Nix configuration
# - nix/zshrc: Initial shell configuration
# - home-manager/modules/zsh.nix: Main ZSH config
#
# Features:
# - FZF-enhanced history search
# - Docker container management
# - Git workflow helpers
# - AWS credential switching
#
# Categories:
# 1. Search Functions:
#    - History searching
#    - Command filtering
#    - Interactive selection
#
# 2. Docker Management:
#    - Container attachment
#    - Container stopping
#    - Container removal
#
# 3. Git Utilities:
#    - PR listing
#    - Branch detection
#    - Current branch info
#
# Integration:
# - Works with iTerm2
# - Supports AWS credentials
# - Uses GitHub CLI
#
# Note:
# - Functions require external tools
# - Some features need additional setup
# - iTerm2 integration is optional
# - Required for initial system setup

# History Search
# FZF-enhanced history searching functions
# Quick search with Ctrl-S
fzf-z-search() {
  local res=$(history -n 1 | tail -f | fzf)
  if [ -n "$res" ]; then
      BUFFER+="$res"
      zle accept-line
  else
      return 0
  fi
}
zle -N fzf-z-search
bindkey '^s' fzf-z-search

# Advanced History Selection
# Filtered history search with Ctrl-R
# Removes short commands and common exits
select-history() {
  BUFFER=$(history -n -r 1 \
      | awk 'length($0) > 2' \
      | rg -v "^...$" \          # Filter out 3-char commands
      | rg -v "^....$" \         # Filter out 4-char commands
      | rg -v "^.....$" \        # Filter out 5-char commands
      | rg -v "^......$" \       # Filter out 6-char commands
      | rg -v "^exit$" \         # Filter out exit commands
      | uniq -u \                # Remove duplicates
      | fzf-tmux --no-sort +m --query "$LBUFFER" --prompt="History > ")
  CURSOR=$#BUFFER
}
zle -N select-history
bindkey '^r' select-history

# Docker Container Management
# Interactive Docker container operations
# Docker functions
# Attach to container
# Usage: da [filter]
function da() {
  local cid
  cid=$(docker ps -a | sed 1d | fzf -1 -q "$1" | awk '{print $1}')
  [ -n "$cid" ] && docker start "$cid" && docker attach "$cid"
}

# Stop container
# Usage: ds [filter]
function ds() {
  local cid
  cid=$(docker ps | sed 1d | fzf -q "$1" | awk '{print $1}')
  [ -n "$cid" ] && docker stop "$cid"
}

# Remove container
# Usage: drm [filter]
function drm() {
  local cid
  cid=$(docker ps -a | sed 1d | fzf -q "$1" | awk '{print $1}')
  [ -n "$cid" ] && docker rm "$cid"
}

# Git Workflow Functions
# Enhanced Git operations and utilities
# Interactive PR listing
# NOTE: These functions are now managed by Home Manager in home-manager/modules/zsh.nix
# Keeping minimal versions here only for bootstrap compatibility

# AWS Credential Management
# Credential switching with clipboard clearing
# Usage: aws-switch [profile]
function aws-switch() {
  osascript -e 'tell application "System Events" to keystroke "k" using command down'
  source "/opt/aws_cred_copy/copy_and_unset $1"
}

# Git Branch Management
# Branch name detection utilities
# NOTE: gitdefaultbranch function is now managed by Home Manager in home-manager/modules/zsh.nix
# Keeping gitcurrentbranch here for bootstrap compatibility

# Get current branch name
function gitcurrentbranch() {
  git symbolic-ref --short HEAD | tr -d "\n"
}

# Terminal Integration
# iTerm2 integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Local Configuration
# Local configurations that might change frequently
[[ -f "$HOME/.aws_cred" ]] && source "$HOME/.aws_cred"
