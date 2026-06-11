# Development and analysis CLI tools managed by Home Manager.
#
# Package-only module: prefer programs.* when Home Manager has a first-class
# configuration module for a tool.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    httpie # Modern HTTP client
    shellcheck # Shell script linting
    git-extras # Additional Git commands and utilities
    tokei # Code statistics and line counting
    hyperfine # Command-line benchmarking tool
    choose # Human-friendly cut/awk alternative
    sd # Modern sed alternative
    grex # Generate regular expressions from examples
    duckdb # Embedded analytical database CLI
  ];
}
