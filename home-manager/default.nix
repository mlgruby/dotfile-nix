# home/default.nix
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
  ];

  # Packages needed for aliases and shell functions
  home.packages = with pkgs; [
    eza
    tfswitch
    gh
    lazygit
    fd
    fzf
    ripgrep
    awscli2
    google-cloud-sdk
    pyenv
    oh-my-zsh
    nerd-fonts.jetbrains-mono
    nerd-fonts.hack
    nerd-fonts.fira-code
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
