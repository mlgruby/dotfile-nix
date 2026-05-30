# Security and encryption CLI tools managed by Home Manager.
#
# Package-only module: prefer programs.* when Home Manager has a first-class
# configuration module for a tool.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bitwarden-cli # Bitwarden password manager CLI (bw)
    sops # Encrypted secrets editor
    age # Modern file encryption tool
  ];
}
