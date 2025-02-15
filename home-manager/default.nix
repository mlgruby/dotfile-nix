# home/default.nix
#
# User-specific configuration and package management
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
#   - awscli2: AWS CLI
#   - google-cloud-sdk: GCP tools
#   - tfswitch: Terraform version manager
#
# Imports:
# - Shell configuration (zsh)
# - Terminal emulator (alacritty)
# - Keyboard customization (karabiner)
# - Cloud platform configs (aws, gcloud)
{ config, pkgs, lib, ... }: {
  imports = [
    ./git.nix
    ./shell.nix
    ./modules/aws.nix
    ./modules/aws-cred.nix
    ./modules/gcloud.nix
    ./modules/git.nix
    ./modules/github.nix
    ./modules/zsh.nix
    ./modules/alacritty
    ./modules/karabiner
  ];

  # Packages needed for aliases and shell functions
  home.packages = with pkgs; [
    # Development tools
    pyenv
    gh
    lazygit

    # CLI utilities
    eza
    fd
    fzf
    ripgrep

    # Cloud tools
    awscli2
    google-cloud-sdk
    tfswitch

    # Shell
    oh-my-zsh
  ];

  # Programs configuration
  programs = {
    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd --type f";
      defaultOptions = ["--height 40%" "--border"];
    };
    home-manager.enable = true;
  };

  fonts.fontconfig.enable = true;

  home = {
    username = "satyasheel";
    homeDirectory = "/Users/satyasheel";
    stateVersion = "23.11";
  };
}
