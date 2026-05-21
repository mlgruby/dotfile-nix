# Language tooling managed by Home Manager.
#
# Package-only module: keep project-pinned dependencies in project configs
# instead of installing them globally here.

{ pkgs, ... }:

let
  pyright-lsp = pkgs.writeShellScriptBin "pyright-lsp" ''
    exec ${pkgs.pyright}/bin/pyright-langserver "$@"
  '';
in

{
  home.packages = with pkgs; [
    kotlin-language-server # Kotlin LSP
    pyright # Python LSP (type checking + intelligence)
    pyright-lsp # Compatibility command for tools expecting pyright-lsp
    typescript-language-server # TypeScript/JavaScript LSP
    typescript # TypeScript compiler (required by ts-ls)
    rust-analyzer # Rust LSP for code intelligence
    rustc # Rust compiler
    cargo # Rust package manager and build tool
    rustfmt # Rust code formatter
    clippy # Rust linter
  ];
}
