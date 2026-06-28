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
    # Python
    python312 # System Python (project versions managed by uv)
    uv # Project deps + Python version management
    poetry # Alternative Python project manager

    # Kotlin
    kotlin-language-server # Kotlin LSP

    # Python LSP
    pyright # Python LSP (type checking + intelligence)
    pyright-lsp # Compatibility command for tools expecting pyright-lsp

    # TypeScript/JavaScript
    typescript-language-server # TypeScript/JavaScript LSP
    typescript # TypeScript compiler (required by ts-ls)

    # Rust
    rust-analyzer # Rust LSP for code intelligence
    rustc # Rust compiler
    cargo # Rust package manager and build tool
    rustfmt # Rust code formatter
    clippy # Rust linter

    # Go
    go # Go compiler and toolchain

    # JavaScript/Node
    nodejs # Node.js runtime
    bun # Fast JS runtime, bundler, package manager

    # Build tools
    cmake # Cross-platform build system
    maven # Java/JVM build tool
    pkg-config # Library metadata tool
    apacheKafka # Kafka CLI tools
  ];
}
