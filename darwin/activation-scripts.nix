{ config, pkgs, lib, ... }:

{
  # Activation Scripts extracted from flake.nix inline module
  
  # Homebrew Setup Pre-activation
  # Sets env var potentially used by nix-homebrew setup
  system.activationScripts.preUserActivation.text = ''
    export INSTALLING_HOMEBREW=1
  '';
} 