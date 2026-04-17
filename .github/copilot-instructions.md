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
- `darwin/homebrew.nix` - GUI applications and macOS-specific packages

## Critical Patterns

### 1. Host Config Validation (`lib/hosts.nix`)
All configuration flows through `hosts.nix` (preferred) validation:
- Required host attributes: `username`, `hostname`, `fullName`, `githubUsername`
- Hostname validation: only letters, numbers, hyphens allowed
- Directory paths: configurable defaults with validation against dangerous characters
- **Pattern**: Invalid config causes build-time errors, not runtime failures

```nix
# Typical hosts.nix structure
{
  common = {
    username = "satya";
    fullName = "Satya Sheel";
    githubUsername = "mlgruby";
  };
  hosts = {
    work = {
      hostname = "satya-work-mbp";
      email = "satya@company.com";
      profile = "work";
    };
    personal = {
      hostname = "satya-personal-mbp";
      email = "satya@example.com";
      profile = "personal";
    };
  };
}
```

### 2. Modular Home-Manager Structure
Each program/service gets dedicated module in `home-manager/modules/`:
- **Module pattern**: `{ config, pkgs, ... }: { ... }`
- **Comments explain**: purpose, configuration areas, integration points
- **Defaults** provided where sensible, overrideable via hosts config
- Examples: `git.nix` (87 lines), `zsh.nix` (220 lines), `aws-sso.nix` (376 lines)

### 3. Shell Aliases Architecture (~220 aliases)
Location: `home-manager/aliases/`
- **Entry point**: `default.nix` imports modular alias files
- **Modules**: helpers.nix, core.nix (~40), git.nix (~80), dev-tools.nix (~70), platform.nix (~30)
- **Pattern**: Aliases are pure data/functions, not imperative config
- **FZF integration**: Many interactive aliases use fuzzy selection
- See [alias documentation](../home-manager/aliases/README.md) for full reference

### 4. Performance Optimization
- **AWS SSO functions**: Lazy-loaded in `aws-sso.nix` to avoid startup delay
- **Shell initialization**: Optimized for fast zsh startup
- **Rebuild strategy**: Use `home-manager switch --no-build` for shell-only changes to skip full rebuild
- **Monitoring**: Run `scripts/monitoring/analyze-build-performance.sh` to measure bottlenecks

## Development Workflows

### Standard Configuration Update
```bash
# 1. Edit configuration (e.g., hosts.nix or home-manager module)
# 2. Test build (dry-run, no system changes)
time darwin-rebuild build --flake . --dry-run

# 3. Apply system configuration
darwin-rebuild switch --flake .

# 4. For shell-only changes (faster)
home-manager switch --no-build
```

### Rollback
```bash
# List previous generations
darwin-rebuild list-generations

# Rollback to previous generation (replace GEN with generation number)
darwin-rebuild switch --flake . --rollback
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
| `darwin/homebrew.nix` | GUI app management | Adding/removing Homebrew casks |
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

**Post-Activation Scripts**
- Java: SDKMAN setup (Java 8, 11, 17 via Amazon Corretto)
- Python: System Python 3.12 via Homebrew + uv for project versions
- AWS: Credential management setup

## Common Refactoring Opportunities

From [refactoring analysis](../REFACTORING_ANALYSIS.md):
- **aws-sso.nix** (376 lines): Extract embedded shell functions to separate `~/.config/aws-sso/functions.sh`
- **fonts.nix** (243 lines): Use generate functions to reduce repetition
- **Large config blocks**: Consider helper functions to abstract patterns
- **Backup files**: `aliases.nix.bak` can be removed

## Testing & Validation

✅ **Before applying changes:**
- Syntax check: `nix flake check`
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
