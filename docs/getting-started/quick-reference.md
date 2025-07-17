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

# Monitor system performance
monitor-status
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
```

## 🔧 Package Management

### Adding Software

```bash
# Add CLI tool (edit homebrew.nix)
vim ~/Documents/dotfile/darwin/homebrew.nix

# Add GUI app (edit homebrew.nix casks section)
vim ~/Documents/dotfile/darwin/homebrew.nix

# Apply changes
rebuild
```

### Package Categories

| Type | Location | Examples |
|------|----------|----------|
| **CLI Tools** | `homebrew.brews` | `git`, `curl`, `jq` |
| **GUI Apps** | `homebrew.casks` | `brave-browser`, `docker-desktop` |
| **Development** | Template-specific | Language runtimes, debuggers |

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

### GitHub CLI

```bash
# Create pull request
ghpr

# List PRs with fzf selection
ghprlist

# Check PR status
ghprcheck

# View repository in browser
ghrepo
```

## ☁️ AWS Management

### Profile Switching

```bash
# Switch to production
awsp

# Switch to development
awsd

# Login to AWS SSO
awsl

# Check current status
awsw
```

### Credential Export

```bash
# Export credentials as environment variables
awse

# Generate .env file
awsf

# Clear all credentials
awsc
```

## 🎨 Customization

### Theme & Appearance

```bash
# View available Alacritty themes
ls ~/.config/alacritty/themes/themes/

# Edit terminal theme
vim ~/.config/alacritty/config.toml

# Reload terminal configuration
# (restart Alacritty or use Cmd+R)
```

### Configuration Files

| What to Change | File to Edit |
|----------------|--------------|
| **Personal Info** | `user-config.nix` |
| **System Settings** | `darwin/configuration.nix` |
| **Packages** | `darwin/homebrew.nix` |
| **Shell Aliases** | `home-manager/aliases.nix` |
| **Terminal** | `home-manager/modules/alacritty/` |

## 🔍 Troubleshooting

### Quick Fixes

```bash
# Rebuild failed? Clean and retry
nix-collect-garbage -d && rebuild

# Shell functions missing? Reload
source ~/.zshrc

# Git authentication issues? Test SSH
ssh -T git@github.com

# AWS credentials expired? Re-login
awsl
```

### Getting Help

```bash
# View system status
health-check

# Check build performance
perf-analyze

# View detailed logs
journalctl -u nix-daemon

# Reset to known good state
cd ~/Documents/dotfile && git stash && rebuild
```

## ⌨️ Keyboard Shortcuts

### System-wide (Karabiner)

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+Enter` | Open Alacritty |
| `Cmd+Shift+I` | Open IntelliJ IDEA |
| `Cmd+Shift+P` | Open PyCharm |
| `Cmd+Shift+C` | Open Cursor |
| `Cmd+Shift+G` | Open Google Chrome |
| `Cmd+Shift+B` | Open Brave Browser |

### Terminal (Zsh)

| Shortcut | Action |
|----------|--------|
| `Ctrl+G` | FZF Git status |
| `Alt+D` | FZF directory navigation |
| `Ctrl+_` | Open file in VSCode with FZF |
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

# Monitor resource usage
perf-monitor
```

## 💡 Pro Tips

1. **Bookmark this page** - Keep it handy for daily reference
2. **Use tab completion** - Most commands support autocompletion
3. **Check aliases** - Run `alias` to see all available shortcuts
4. **Read the status** - Many commands show helpful status information
5. **When in doubt, rebuild** - It's safe and fixes most issues

## 🔗 Quick Links

- **[Full Documentation](../README.md)** - Complete guide index
- **[Troubleshooting](../technical/troubleshooting.md)** - Fix problems
- **[Customization](../guides/personalization.md)** - Make it yours
- **[Development Setup](../development/environment-templates.md)** - Coding environments

---

💡 **Remember**: Your configuration is declarative and version-controlled.
Changes are safe, and you can always roll back!
