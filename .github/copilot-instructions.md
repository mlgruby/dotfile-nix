# AI Instructions for Nix Darwin Dotfiles

This repository manages a reproducible macOS system configuration using Nix, nix-darwin, and home-manager.

## Architecture Overview

**Layer 1: System Config (nix-darwin)**
- `darwin/` - macOS system-level settings, security, package defaults
- Manages: system packages, defaults, services, kernel settings
- Output: `/etc/` configurations, system preferences

**Layer 2: User Environment (home-manager)**
- `home-manager/` - User environment, shell config, program settings
- Manages: dotfiles, aliases (~220), tool configurations
- Modular design: each tool gets its own `.nix` file

**Layer 3: Package Management**
- `flake.nix` - Orchestrates both layers and imports validated host config
- `lib/hosts.nix` - Validates `hosts.nix` and applies host defaults
- `hosts.nix` - User/host personalization (common + per-host settings)
- `darwin/homebrew.nix` - Homebrew activation and profile composition
- `darwin/homebrew-packages/` - Shared Homebrew formulae, casks, fonts, and taps
- `darwin/profiles/` - Profile-specific Homebrew additions/removals

## Critical Patterns

### 1. Host Config Validation (`lib/hosts.nix`)
All configuration flows through `hosts.nix` (preferred) validation:
- Required host attributes: `username`, `hostname`, `fullName`, `githubUsername`
- Hostname validation: only letters, numbers, hyphens allowed
- Directory paths: configurable defaults with validation against dangerous characters
- **Pattern**: Invalid config causes build-time errors, not runtime failures

```nix
# Typical hosts.nix structure (note: git emails live in local ~/.gitconfig-{work,personal}, never in hosts.nix)
{
  common = {
    username = "satya";
    fullName = "Satya Sheel";
    githubUsername = "mlgruby";
  };
  hosts = {
    work = {
      hostname = "satya-wmbp";
      profile = "work";
    };
    personal = {
      hostname = "satya-pmbp";
      profile = "personal";
    };
  };
}
```

### 2. Modular Home-Manager Structure
Each program/service gets a dedicated module in `home-manager/modules/`:
- **Module pattern**: `{ config, pkgs, lib, ... }: { ... }`
- **Comments explain**: purpose, configuration areas, integration points
- **Defaults** provided where sensible, overrideable via hosts config
- Examples: `git.nix`, `zsh.nix`, `ghostty.nix`, `herdr.nix`, `claude-code.nix`, `antigravity.nix`, `pi.nix`, `plugins.nix`, `aws-sso.nix`

### 3. Shell Aliases Architecture (~220 aliases)
Location: `home-manager/aliases/`
- **Entry point**: `default.nix` imports modular alias files
- **Modules**: `helpers.nix`, `core.nix`, `git.nix`, `dev-tools.nix`, `platform.nix`, `homelab.nix`
- **Pattern**: Aliases are pure data/functions, not imperative config
- **FZF integration**: Many interactive aliases use fuzzy selection
- See [alias documentation](../home-manager/aliases/README.md) for full reference

### 4. Performance Optimization
- **AWS SSO functions**: Lazy-loaded in `aws-sso.nix` to avoid startup delay
- **Shell initialization**: Optimized for fast zsh startup with deduplicated `$PATH` (`typeset -U path PATH`)
- **Rebuild strategy**: Use `rebuild` (wraps `sudo darwin-rebuild switch --flake .#<hostname>` and displays an `nvd diff` package summary)
- **Monitoring**: Run `./scripts/monitoring/analyze-build-performance.sh` on demand to measure build & store metrics

## Development Workflows

### Standard Configuration Update
```bash
# 1. Edit configuration (e.g., hosts.nix or home-manager module)
# 2. Check evaluation (no system changes)
nix flake check --no-build
rebuild-check

# 3. Apply system configuration (auto-detects active host and prints nvd diff)
rebuild
```

### Rollback
```bash
# Interactive generation selector with live nvd diff preview
rollback

# Or roll back directly to the previous generation
rollback --previous
```

### Profile Management
- System uses flakes: `--flake .` points to current directory flake.nix
- Architecture target: `aarch64-darwin` (Apple Silicon M1/M2)
- State version in home-manager: `24.05` (version locked for reproducibility)

## File Structure & Responsibilities

| Path | Purpose | When to edit |
|------|---------|--------------|
| `flake.nix` | System orchestration, inputs, hosts validation | Adding dependencies, changing module layout |
| `hosts.nix` | Shared + per-host settings | Personalizing multi-machine setup |
| `darwin/` | macOS system config | System packages, defaults, security |
| `darwin/homebrew.nix` | Homebrew activation and composition | Changing Homebrew behavior |
| `darwin/homebrew-packages/` | Shared Homebrew package lists | Adding/removing shared formulae and casks |
| `darwin/profiles/` | Profile-specific Homebrew overrides | Adding/removing packages for one profile |
| `home-manager/default.nix` | Module imports, home directory settings | Adding new program modules |
| `home-manager/modules/` | Individual program configurations | Tool-specific config |
| `home-manager/aliases/` | Shell aliases organization | Adding/modifying shell shortcuts |
| `docs/` | User-facing documentation | Explaining features to users |
| `scripts/install/` | System setup scripts | Installation prerequisites |

## Key Design Decisions

### Why Modular?
- Each `.nix` file handles one concern (git, tmux, zsh, etc.)
- Easy to enable/disable features without editing multiple files
- Clear ownership and responsibility boundaries

### Why Host Config Validation?
- Catches configuration errors at build time, not runtime
- Ensures hostname is macOS-compatible
- Validates paths don't contain dangerous characters
- Makes error messages specific and actionable

### Why Homebrew Separate?
- Nix is deterministic but slower for UI apps
- Homebrew handles macOS-specific GUI applications
- `nix-homebrew` provides Nix-managed Homebrew configuration

### Why Home-Manager Separate from Darwin?
- System settings vs. user preferences are distinct concerns
- Easy to backup/move host config to different machines
- Home-manager can run independently

## Integration Points & Dependencies

**External Inputs (flake.nix)**
- `nixpkgs` (nixpkgs-unstable) - All packages
- `home-manager` - User environment management
- `darwin` - macOS system integration
- `nix-homebrew` - Homebrew management
- `stylix` - System-wide theming
- `agent-extras` (`path:./home-manager/agent-extras`) - Child flake locking upstream AI agent skills and plugins

**Toolchains & Runtimes**
- Java: `temurin@21` via Homebrew cask (`darwin/homebrew-packages/casks/development.nix`)
- Python / Node / Go / Rust: Managed declaratively via Nix in `home-manager/modules/packages/languages.nix` (`python312`, `uv`, `nodejs`, `bun`, `go`, `rustup`)
- AWS: Declarative SSO profiles + lazy-loaded credential helpers (`home-manager/modules/aws-sso.nix`)

## Common Refactoring Opportunities

Use [the current refactoring backlog](../docs/refactoring-backlog.md) for active
cleanup work. Historical analysis lives under `docs/archive/`.

## Testing & Validation

✅ **Before applying changes or opening a PR:**
- Local pre-PR check suite (required before creating/updating any PR): `./scripts/testing/pre-pr-check.sh` (use `--build` for full `nix flake check` derivation builds)
- Syntax check: `nix flake check --no-build`
- Dry-run build: `darwin-rebuild build --flake . --dry-run`
- Host config present: `hosts.nix` must exist and be valid

⚠️ **Watch for:**
- Missing required attributes in host config
- Invalid hostname format (only alphanumeric + hyphens)
- Dangerous characters in directory paths
- Conflicting module imports

## Documentation Structures

- **Quick paths**: `docs/getting-started/` for new users
- **Learning paths**: `docs/` organized by use case (developer, customization, performance)
- **Troubleshooting**: `docs/help/` and `docs/technical/troubleshooting.md`
- **Advanced topics**: `docs/advanced/` for architecture deep dives
