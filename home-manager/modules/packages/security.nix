# Security and encryption CLI tools managed by Home Manager.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    sops # Encrypted secrets editor
    age # Modern file encryption tool
  ];
}
