# Text, document, JSON, and YAML tools managed by Home Manager.
#
# Package-only module: prefer programs.* when Home Manager has a first-class
# configuration module for a tool.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pandoc # Universal document converter
    marp-cli # Markdown presentation deck renderer
    poppler-utils # PDF utilities such as pdftotext and pdfinfo
    glow # Terminal markdown renderer
    yq-go # YAML processor
    fx # Interactive JSON viewer and processor
    yj # Convert YAML to JSON and vice versa
    ripgrep-all # Extended ripgrep with more file type support
  ];
}
