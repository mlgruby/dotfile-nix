# Shell Aliases Reference

Quick reference guide for all available shell aliases.

## File Organization

```
aliases/
├── core.nix          # Essential shell navigation and utilities
├── dev-tools.nix     # Development tools (Docker, K8s, Terraform, etc.)
├── git.nix           # Git workflows and GitHub CLI
├── homelab.nix       # Homelab and self-hosted service aliases
├── platform.nix      # macOS/Linux system management
├── helpers.nix       # Helper functions for alias generation
└── default.nix       # Main entry point
```

## Quick Navigation

### Most Used Aliases

| Alias | Description | Example |
|-------|-------------|---------|
| `gs` | Git status (short) | `gs` |
| `gaa` | Git add all | `gaa` |
| `gcm` | Git commit | `gcm "message"` |
| `gp` | Git push | `gp` |
| `gl` | Git pull | `gl` |
| `d` | Docker | `d ps` |
| `k` | Kubectl | `k get pods` |
| `cc` | Claude Code | `cc` |
| `rebuild` | Rebuild system (supports profile flags) | `rebuild --work` |
| `cleanup` | Confirm, then clean system | `cleanup` |

### Dangerous Operations

⚠️ **These aliases can cause data loss - use with caution:**

- `grhh` - Hard reset (discards all local changes)
- `groh` - Reset to remote HEAD (discards local commits)
- `gnuke` - Nuclear reset (resets everything)
- `gclean` - Remove untracked files

## Category Overview

### 1. Core Shell (core.nix)
- Navigation: `..`, `...`, `~`, `-`
- File operations: `backup`, `xtract`, `compress`
- Documentation: `rtfm`, `cheat`, `md`
- Network: `myip`, `ports`, `flushdns`
- Clipboard: `copy`, `paste`

### 2. Development Tools (dev-tools.nix)
- Modern CLI: `eza`, `fd`, `duf`, `btm`
- Claude Code: `cc`, `ccc`, `ccr`
- Tmux: `tn`, `ta`, `tk`, `t`
- FZF: `fe`, `fcd`, `fif`, `fkill`
- Docker: `d`, `dc`, `dsp`, `drm`, `dlog`
- Kubernetes: `k`, `kgp`, `klogs`, `kexec`
- Terraform: `tf`, `tfin`, `tfp`, `tfa`

### 3. Git Workflows (git.nix)
- Basic: `gs`, `gaa`, `gcm`, `gp`, `gl`
- Branches: `gco`, `gcob`, `gbd`, `gba`
- Stash: `gst`, `gstp`, `gstl`
- Rebase: `grb`, `grbi`, `grbc`
- GitHub: `ghpr`, `ghprs`, `ghprv`
- Conventional: `feat`, `fix`, `docs`, `chore`

### 4. System Management (platform.nix)
- macOS: `rebuild`, `update`, `cleanup`, `rollback`
- Health: `health-check`, `health-report`
- Logs: `logs-health`, `logs-alerts`
- Finder: `showhidden`, `hidedesktop`

### 5. Homelab (homelab.nix)
- Lazywarden: `lwdec`, `lw-decrypt`, `lw-restore`

| Alias | Description | Example |
|-------|-------------|---------|
| `lwdec` | Short form for `lazywarden-decrypt` | `lwdec backup.zip --output ~/Secure/lazywarden-restore` |
| `lw-decrypt` | Readable alias for `lazywarden-decrypt` | `lw-decrypt backup.zip --no-attachments` |
| `lw-restore` | Restore with default secure output directory | `lw-restore backup.zip` |

## Interactive Aliases (FZF-powered)

These aliases open interactive fuzzy-finder menus:

| Alias | Description |
|-------|-------------|
| `gcb` | Checkout branch with preview |
| `fshow` | Browse commits with diff |
| `fstash` | Select and apply stash |
| `fe` | Find and edit file |
| `fcd` | Find and change directory |
| `fif` | Search file contents |
| `dsp` | Select and stop Docker container |
| `kfp` | Select Kubernetes pod |

## Pipe-able Aliases

These aliases work with pipes:

```bash
# JSON/YAML formatting
cat data.json | json          # Pretty-print JSON
cat config.yaml | yaml        # Pretty-print YAML

# Clipboard
echo "text" | copy            # Copy to clipboard
paste | grep "pattern"        # Search clipboard

# Process search
psg nginx                     # Find nginx processes
```

## Tips for Reducing Cognitive Load

1. **Use tab completion** - Most aliases support tab completion
2. **Check before running** - Add `-n` or `--dry-run` flags when available
3. **Start with safe operations** - Use read-only aliases first (e.g., `gs` before `gaa`)
4. **Use interactive versions** - FZF aliases (`gcb`, `fe`) are safer
5. **Create your own** - Add custom aliases in `default.nix`

## Common Patterns

### Git Workflow
```bash
gs              # Check status
gaa             # Stage all
gcm "message"   # Commit
gp              # Push
```

### Docker Workflow
```bash
d ps            # List containers
dlog            # Tail logs (interactive)
dexec           # Exec into container (interactive)
dsp             # Stop container (interactive)
```

### Kubernetes Workflow
```bash
k get pods      # List pods
klogs pod-name  # Follow logs
kexec pod-name -- /bin/sh  # Exec into pod
```

## Getting Help

### Interactive Discovery
- `alias-find` - Fuzzy search all aliases (interactive with fzf)
- `alias-quick` - Quick reference of most used aliases
- `alias-help [category]` - Show documentation (categories: all, core, git, dev, docker, k8s, terraform, quick)
- `alias-search <keyword>` - Search aliases by keyword
- `alias-list` - List all aliases alphabetically
- `alias-count` - Count total aliases

### Traditional Methods
- `alias | grep <keyword>` - Search for aliases
- Check comments in each `.nix` file for usage examples
- Use `tldr <command>` for command examples (aliased as `rtfm`)
- Run `man <command>` for full documentation

### Examples
```bash
alias-quick                  # Show quick reference
alias-help git              # Show git aliases
alias-find                  # Interactive fuzzy search
alias-search docker         # Search for docker-related aliases
```

## Contributing

When adding new aliases:
1. Place in appropriate category file
2. Add descriptive comment
3. Include usage example if it requires arguments
4. Mark destructive operations with warning
5. Update this README
