# Shell Scripts Guide

Helper scripts for complex alias operations. These scripts provide better error handling, dependency checking, and user feedback than inline aliases.

## 📁 Installation

These scripts are automatically installed to `~/.config/home-manager/scripts/` when you run `rebuild`.

## 🚀 Usage

All scripts are already aliased! You can use them directly:

### 1. Git Fuzzy Checkout (`gcb`)

**Alias**: `gcb`
**Direct**: `~/.config/home-manager/scripts/git-fuzzy-checkout.sh`

Interactive branch checkout with commit preview.

```bash
# Use the alias (easiest)
gcb

# Or run directly
~/.config/home-manager/scripts/git-fuzzy-checkout.sh
```

**What it does:**
- Lists all local and remote branches
- Shows recent commits for each branch in preview
- Fuzzy search to select a branch
- Checks out the selected branch

**Requirements:** fzf, git

---

### 2. Git Fuzzy Log (`fshow`)

**Alias**: `fshow`
**Direct**: `~/.config/home-manager/scripts/git-fuzzy-log.sh`

Interactive commit browser with diff preview.

```bash
# Use the alias
fshow

# Or run directly
~/.config/home-manager/scripts/git-fuzzy-log.sh
```

**What it does:**
- Shows git log with graph
- Preview full diff for each commit
- Press ENTER to view commit in pager
- Press ESC to exit

**Requirements:** fzf, git

---

### 3. Git Fuzzy Stash (`fstash`)

**Alias**: `fstash`
**Direct**: `~/.config/home-manager/scripts/git-fuzzy-stash.sh`

Interactive stash browser and applicator.

```bash
# Use the alias
fstash

# Or run directly
~/.config/home-manager/scripts/git-fuzzy-stash.sh
```

**What it does:**
- Lists all stashes
- Shows stash contents in preview
- Fuzzy search to select a stash
- Applies the selected stash

**Requirements:** fzf, git

---

### 4. System Rollback (`rollback`)

**Alias**: `rollback`
**Direct**: `~/.config/home-manager/scripts/system-rollback.sh`

Interactive system generation rollback (macOS/nix-darwin only).

```bash
# Use the alias
rollback

# Or run directly
~/.config/home-manager/scripts/system-rollback.sh
```

**What it does:**
- Lists all system generations
- Shows what's included in each generation
- Fuzzy search to select a generation
- Rolls back to the selected generation

**Requirements:** fzf, darwin-rebuild (macOS only)

---

### 5. Alias Cheatsheet (`alias-help`, `alias-quick`)

**Aliases**: `alias-help`, `alias-quick`
**Direct**: `~/.config/home-manager/scripts/alias-cheatsheet.sh`

Interactive alias documentation viewer.

```bash
# Quick reference (most-used aliases)
alias-quick

# Full documentation
alias-help

# Category-specific
alias-help git
alias-help docker
alias-help k8s
alias-help terraform
alias-help core
alias-help dev

# Or run directly
~/.config/home-manager/scripts/alias-cheatsheet.sh [category]
```

**Categories:**
- `all` - Full README (default)
- `quick` - Quick reference of most-used
- `core` - Core shell aliases
- `git` - Git workflow aliases
- `dev` - Development tools
- `docker` - Docker-specific
- `k8s` - Kubernetes-specific
- `terraform` - Terraform-specific

**Requirements:** bat (optional, for syntax highlighting)

---

## 📋 Complete Workflow Examples

### Git Workflow
```bash
# 1. Check current status
gs

# 2. Interactive branch selection
gcb

# 3. Browse commits to understand history
fshow

# 4. Make changes...

# 5. Quick commit and push
quickpush "feat: add new feature"
```

### Stash Workflow
```bash
# 1. Stash your work
gst

# 2. Do something else...

# 3. Interactive stash selection
fstash
```

### System Management
```bash
# 1. Make system changes
rebuild

# 2. If something breaks, rollback
rollback
```

### Learning Aliases
```bash
# 1. See most-used aliases
alias-quick

# 2. Interactive search
alias-find

# 3. Search by keyword
alias-search docker

# 4. View specific category
alias-help git
```

---

## 🔧 Manual Usage (Without Aliases)

If you want to use the scripts directly (useful for testing or custom workflows):

```bash
# Git scripts
~/.config/home-manager/scripts/git-fuzzy-checkout.sh
~/.config/home-manager/scripts/git-fuzzy-log.sh
~/.config/home-manager/scripts/git-fuzzy-stash.sh

# System scripts
~/.config/home-manager/scripts/system-rollback.sh

# Help scripts
~/.config/home-manager/scripts/alias-cheatsheet.sh quick
~/.config/home-manager/scripts/alias-cheatsheet.sh git
```

---

## 🐛 Troubleshooting

### Scripts not found
```bash
# After adding scripts, rebuild your system
rebuild

# Check if scripts exist
ls -la ~/.config/home-manager/scripts/
```

### Permission denied
```bash
# Scripts should be executable automatically
# If not, fix permissions:
chmod +x ~/.config/home-manager/scripts/*.sh
```

### FZF not available
```bash
# FZF should be installed via home-manager
# If missing, install it:
nix-env -iA nixpkgs.fzf

# Or add to your home-manager packages
```

### Script errors
All scripts have error checking built in. Common issues:

1. **"Not a git repository"** - Run the git scripts inside a git repo
2. **"fzf not found"** - Install fzf (should be in your config)
3. **"darwin-rebuild not found"** - System rollback is macOS-only

---

## 🎯 Quick Reference Card

| What | Alias | Direct Path |
|------|-------|-------------|
| Checkout branch | `gcb` | `~/.config/home-manager/scripts/git-fuzzy-checkout.sh` |
| Browse commits | `fshow` | `~/.config/home-manager/scripts/git-fuzzy-log.sh` |
| Apply stash | `fstash` | `~/.config/home-manager/scripts/git-fuzzy-stash.sh` |
| System rollback | `rollback` | `~/.config/home-manager/scripts/system-rollback.sh` |
| Quick help | `alias-quick` | `~/.config/home-manager/scripts/alias-cheatsheet.sh quick` |
| Full help | `alias-help` | `~/.config/home-manager/scripts/alias-cheatsheet.sh all` |

---

## 💡 Pro Tips

1. **Use aliases** - They're shorter and easier to remember
2. **Try interactive first** - FZF-powered scripts are safer
3. **Check dependencies** - Scripts will tell you if something is missing
4. **Customize freely** - Scripts are in your dotfiles, modify as needed
5. **Add your own** - Follow the same pattern for new scripts

---

## 📚 Further Reading

- See `../aliases/README.md` for complete alias documentation
- See `../aliases/IMPROVEMENTS.md` for development history
- Check individual script headers for detailed documentation
