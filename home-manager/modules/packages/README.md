# Home Manager Package Groups

This directory owns package-only Home Manager modules. Use these files for CLI
tools that need to be installed but do not need a dedicated `programs.*`
configuration block.

## Ownership Rules

- Prefer `programs.*` when Home Manager has a first-class module for the tool.
  Examples: `git`, `gh`, `tmux`, `starship`, `fzf`, `zoxide`, `bat`, `eza`,
  and `tealdeer`.
- Prefer these package groups for user-level CLI tools that are just binaries.
  Examples: `shellcheck`, `fd`, `duf`, `glow`, `sops`, `age`, `awscli2`, and
  `terraform-docs`.
- Prefer Homebrew for GUI apps, fonts, vendor-managed desktop software, and
  global runtimes/build chains intentionally shared with IDEs.
- Prefer project-local tools for dependencies that should be pinned per repo.
  Use `direnv`, `uv`, language package managers, or project flakes for those.

## Files

- `cloud.nix` - AWS, Kubernetes, Terraform, and infrastructure CLIs.
- `development.nix` - Developer productivity, linting, benchmarking, and code
  analysis CLIs.
- `languages.nix` - Language servers and language tooling managed at user level.
- `security.nix` - Secret management and encryption CLIs.
- `system.nix` - Filesystem, networking, archive, and system inspection CLIs.
- `text.nix` - Document, Markdown, PDF, JSON, YAML, and search helpers.

The aggregator is `../package-groups.nix`; it imports these groups so the main
Home Manager config has one stable import path.
