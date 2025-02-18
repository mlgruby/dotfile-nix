# home/default.nix
#
# User-specific configuration and package management
#
# Purpose:
# - Central configuration for Home Manager
# - Manages user-specific packages and settings
# - Coordinates all module imports
#
# Packages:
# - Development tools
#   - pyenv: Python version management
#   - gh: GitHub CLI
#   - lazygit: Git TUI
#
# - CLI utilities
#   - eza: Modern ls replacement
#   - fd: Find alternative
#   - fzf: Fuzzy finder
#   - ripgrep: Modern grep
#
# - Cloud tools
#   - google-cloud-sdk: GCP tools
#
# Imports:
# Core:
# - Shell configuration (zsh)
# - Terminal emulator (alacritty)
# - Keyboard customization (karabiner)
#
# Development:
# - Git configuration and utilities
# - LazyGit TUI configuration
# - GitHub CLI settings
#
# Cloud & Infrastructure:
# - Cloud platform configs (aws, gcloud)
# - AWS credentials management
#
# Integration:
# - Works with darwin/configuration.nix
# - Uses homebrew.nix for macOS packages
# - Coordinates with aliases.nix for shell commands
{ config, pkgs, lib, username, fullName, email, githubUsername, userConfig, ... }: {
  imports = [
    # Shell Environment
    ./shell.nix
    ./modules/tmux.nix
    # Cloud Platform Tools
    ./modules/aws.nix
    ./modules/aws-cred.nix
    ./modules/gcloud.nix
    # Development Tools
    ./modules/git.nix
    ./modules/github.nix
    # Core Environment
    ./modules/zsh.nix
    ./modules/alacritty
    ./modules/karabiner
    ./modules/lazygit.nix
  ];

  # Core packages required for basic functionality
  home.packages = with pkgs; [
    oh-my-zsh
  ];

  programs = {
    # Shell Configuration
    zsh = {
      enable = true;
      # Import aliases from central location
      shellAliases = import ./aliases.nix { inherit pkgs config userConfig; };
    };
    # Fuzzy Finder Configuration
    fzf = {
      enable = true;
      enableZshIntegration = true;
      # Use fd for file finding (respects .gitignore)
      defaultCommand = "fd --type f";
      # Default appearance and behavior
      defaultOptions = ["--height 40%" "--border"];
    };
    home-manager.enable = true;
  };

  # Enable font configuration
  fonts.fontconfig.enable = true;

  # User Environment Settings
  home = {
    username = username;
    homeDirectory = "/Users/${username}";
    # Version for home-manager
    stateVersion = "23.11";
  };
}
