# Development and analysis CLI tools managed by Home Manager.
#
# Package-only module: prefer programs.* when Home Manager has a first-class
# configuration module for a tool.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    codex # OpenAI Codex CLI
    claude-code # Claude Code CLI; configuration remains in modules/claude-code.nix
    antigravity-cli # Antigravity CLI; statusline configuration remains in modules/antigravity.nix
    opencode # OpenCode CLI; LM Studio configuration remains in modules/opencode.nix
    pi-coding-agent # Pi Coding Agent CLI; local model configuration remains in modules/pi.nix
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
