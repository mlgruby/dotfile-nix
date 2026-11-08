# Quick Reference

Your daily command cheat sheet for productive work with Nix Darwin dotfiles.

## 🚀 Essential Commands

### System Management

```bash
# Rebuild system with latest configuration
rebuild

# Quick rebuild (faster, less verification)
rebuild-fast

# Check what changes would be made (dry run)
rebuild-check

# Clean up old generations and free space
cleanup

# Interactive rollback with live package diff preview
rollback

# Full system garbage collection
nix-collect-garbage -d
```

### Health & Monitoring

```bash
# Quick system health check
health-check

# Detailed health report
health-report

# System maintenance (cleanup, updates, optimization)
health-maintain
```

### Development Environment

```bash
# List available development templates
setup-dev-env --list

# Set up Python environment
setup-dev-env python

# Set up Node.js environment
setup-dev-env nodejs

# Auto-detect and set up environment
setup-dev-env --auto

# Check language server availability (for Claude Code & IDEs)
which rust-analyzer           # Rust LSP
which kotlin-language-server  # Kotlin LSP
```

## 🔧 Package Management

### Adding Software

```bash
# Add CLI tool (prefer Home Manager package modules)
vim ~/dotfile/home-manager/modules/packages/system.nix

# Add GUI app or macOS integration
vim ~/dotfile/darwin/homebrew-packages/casks/apps.nix

# Apply changes
rebuild
```

### Package Categories

| Type | Location | Examples |
|------|----------|----------|
| **CLI Tools** | `home-manager/modules/packages/*.nix` | `fd`, `duf`, `shellcheck`, `awscli2` |
| **Language Runtimes & LSPs** | `home-manager/modules/packages/languages.nix` | `python312`, `uv`, `nodejs`, `bun`, `go`, `rustup` |
| **GUI Apps & Vendor Casks** | `darwin/homebrew-packages/casks/*.nix` | `ghostty`, `zed`, `brave-browser`, `orbstack`, `temurin@21` |
| **Project tooling** | Template-specific | Project `.envrc`, `uv`, or dev flakes |

See [Toolchain Ownership](../guides/toolchain-ownership.md) before moving
global runtimes or build tools.

## 📁 Directory Navigation

### Quick Shortcuts

```bash
# Navigate to dotfiles
dotfile

# Go to development workspace
ws  # or dev

# Common directories
dl       # Downloads
docs     # Documents
desktop  # Desktop
```

### Development Directories

```bash
# Project-specific (if configured)
personal    # ~/Development/Personal
work        # ~/Development/Work
opensource  # ~/Development/OpenSource
```

## 🔍 Discovering Aliases

**NEW!** Interactive tools to learn your ~220 aliases:

```bash
# Quick reference (most-used aliases)
alias-quick

# Interactive fuzzy search
alias-find

# Category-specific help
alias-help git      # Git aliases only
alias-help docker   # Docker aliases only
alias-help k8s      # Kubernetes aliases only

# Search by keyword
alias-search docker # Find docker-related aliases

# List all aliases alphabetically
alias-list

# Count total aliases
alias-count
```

See: [Complete Alias Guide](../../home-manager/aliases/README.md) | [Quick Start](../../SCRIPTS_QUICKSTART.md)

## 🔄 Git & GitHub

### Git Shortcuts

```bash
# Git status
gs

# Add all and commit
gaa
gcm "commit message"

# Push to origin
gp

# Pull with rebase
gl
```

### Quick Workflows (NEW!)

```bash
# Stage all + commit
quickcommit "feat: add feature"

# Stage + commit + push
quickpush "fix: bug fix"

# Stage + amend last commit
quickamend

# Quick WIP commit
quicksave
```

### Interactive Git (NEW!)

```bash
# Checkout branch with fuzzy search & preview
gcb

# Browse commits with diff preview
fshow

# Select and apply stash interactively
fstash
```

### GitHub CLI

```bash
# Create pull request
ghpr

# Checkout PR interactively
ghprco

# List PRs (all / open / fuzzy)
ghprl
ghpro
ghprf

# Check PR status
ghprch

# View repository in browser
ghrv
```

## 🤖 AI Agents & Terminal Ergonomics

```bash
# Launch project workspace (Work 3-tab / Personal 4-tab in Tmux)
p

# Run command and copy ANSI-stripped output to clipboard
cb <command>
rc              # Re-run last command into clipboard

# Screenshots for AI Agents
pbimg           # Save clipboard image to /tmp and copy path
cshot           # Copy latest screenshot path to clipboard

# AI Coding Agents
cc / ccr / ccc  # Claude Code (new / resume / continue)
ag / agr / agc  # Antigravity (open / fzf resume / chat)
cx / cxr        # Codex (new / resume)
pil / pig / pib # Pi Coding Agent (local / Gemini / Bedrock)

# AI Usage Reports
cau-t           # Today's token & cost breakdown
cau-w           # 7-day rolling usage
cau-m           # 30-day rolling usage
```

## ☁️ AWS Management

### Profile Switching

```bash
# Switch to production
awsp

# Switch to development/default
awsd

# Refresh SSO and file credentials for default/dev apps
awsrd

# Refresh SSO and file credentials for production/prod apps
awsrp

# Check current status
awsw
```

### Credential Export

```bash
# Export credentials as environment variables
awse

# Export current profile to a named profile in ~/.aws/credentials
awsef

# Super workflow: login both SSO profiles + export both to ~/.aws/credentials
awsf

# Clear all credentials
awsc
```

## 🎨 Customization

### Theme & Appearance

```bash
# Primary terminal config (Ghostty)
vim ~/dotfile/home-manager/modules/ghostty.nix

# Secondary terminal config (Alacritty)
vim ~/dotfile/home-manager/modules/alacritty/default.nix
```

### Configuration Files

| What to Change | File to Edit |
|----------------|--------------|
| **Personal Info** | `hosts.nix` |
| **System Settings** | `darwin/configuration.nix` |
| **Packages** | `home-manager/modules/packages/`, `darwin/homebrew-packages/` |
| **Shell Aliases** | `home-manager/aliases/` (organized by category) |
| **Helper Scripts** | `home-manager/scripts/` (standalone scripts) |
| **Terminal** | `home-manager/modules/ghostty.nix`, `home-manager/modules/herdr.nix` |

## 🔍 Troubleshooting

### Quick Fixes

```bash
# Rebuild failed? Clean and retry
nix-collect-garbage -d && rebuild

# Shell functions missing? Reload
source ~/.zshrc

# Git authentication issues? Test SSH
ssh -T git@github.com

# Bitwarden SSH Agent keys visible to SSH
bwssh

# Fuzzy-pick a Bitwarden item and copy its password
bwp

# AWS credentials expired? Re-login
awsl
```

### Getting Help

```bash
# View system status
health-check

# Check build performance
perf-analyze

# View macOS nix-daemon service status
sudo launchctl list | grep nix-daemon

# Reset to known good state
cd ~/dotfile && git stash && rebuild
```

## ⌨️ Keyboard Shortcuts

### System-wide (Karabiner)

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+4` | Capture screenshot to file + clipboard |
| `Cmd+Shift+Enter` | Open Ghostty |
| `Cmd+Shift+K` | Open Claude |
| `Cmd+Shift+I` | Open IntelliJ IDEA |
| `Cmd+Shift+P` | Open PyCharm |
| `Cmd+Shift+S` | Open Slack |
| `Cmd+Shift+X` | Open Codex |
| `Cmd+Shift+D` | Open Beekeeper Studio |
| `Cmd+Shift+A` | Open Calendar |
| `Cmd+Shift+G` | Open Google Chrome |
| `Cmd+Shift+B` | Open Brave Browser |

### Terminal (Zsh)

| Shortcut | Action |
|----------|--------|
| `Ctrl+G` | FZF Git status |
| `Alt+D` | FZF directory navigation |
| `Ctrl+_` | Open file in Zed with FZF |
| `Alt+←/→` | Word navigation |
| `Ctrl+U` | Clear line before cursor |

## 📊 Performance Commands

```bash
# Analyze build performance
perf-analyze

# Profile system performance  
perf-profile

# Optimize system performance
perf-optimize
```

## 💡 Pro Tips

1. **Start with `alias-quick`** - Learn the most-used aliases first
2. **Use `alias-find`** - Discover aliases interactively with fuzzy search
3. **Try interactive scripts** - `gcb`, `fshow`, `fstash` with previews
4. **Use workflow shortcuts** - `quickcommit`, `quickpush` save time
5. **Tab completion works** - Most commands support autocompletion
6. **When in doubt, rebuild** - It's safe and fixes most issues

## 🔗 Quick Links

- **[Full Documentation](../README.md)** - Complete guide index
- **[Troubleshooting](../technical/troubleshooting.md)** - Fix problems
- **[Customization](../guides/personalization.md)** - Make it yours
- **[Development Setup](../development/environment-templates.md)** - Coding environments

---

💡 **Remember**: Your configuration is declarative and version-controlled.
Changes are safe, and you can always roll back!
