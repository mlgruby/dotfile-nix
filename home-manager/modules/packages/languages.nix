# Language tooling managed by Home Manager.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kotlin-language-server # Kotlin LSP for code intelligence
    rust-analyzer # Rust LSP for code intelligence
    rustc # Rust compiler
    cargo # Rust package manager and build tool
    rustfmt # Rust code formatter
    clippy # Rust linter
  ];
}
