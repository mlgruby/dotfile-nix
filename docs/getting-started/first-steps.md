# First Steps After Installation

Congratulations! You've successfully installed your Nix Darwin dotfiles. Here's
what to do next to get the most out of your new system.

## ✅ Verify Installation

First, let's make sure everything is working correctly:

```bash
# Check if darwin-rebuild is working
darwin-rebuild --version

# Verify home-manager is active
home-manager --version

# Test your shell configuration
echo $SHELL
which zsh
```

## 🎯 Essential First Steps

### 1. Update Your User Configuration

Your personal settings are stored in `user-config.nix`. Let's make sure
everything is correct:

```bash
# Navigate to your dotfiles
cd ~/Documents/dotfile

# Edit your user configuration
vim user-config.nix
```

**Key settings to verify:**

- `username` - Must match your macOS username
- `email` - Used for Git commits
- `githubUsername` - For GitHub integration
- `hostname` - Should match your Mac's hostname

### 2. Test Core Functionality

Run these commands to verify your setup:

```bash
# Test Git configuration
git config --list | grep user

# Test SSH keys (if GitHub setup was completed)
ssh -T git@github.com

# Test AWS SSO (if configured)
awsl  # AWS SSO login

# Check available aliases
alias | grep -E "^(rebuild|cleanup|health)"
```

### 3. Apply Your First Rebuild

Make a small change and test the rebuild process:

```bash
# Make a rebuild to ensure everything works
rebuild

# If that succeeds, try a full system check
health-check
```

## 🔧 Common Next Steps

### For Developers

```bash
# Set up development environment for your language
setup-dev-env --list

# For Python development
setup-dev-env python

# For Node.js development  
setup-dev-env nodejs
```

### For Customization Enthusiasts

```bash
# Explore available themes
ls ~/.config/alacritty/themes/themes/

# Check current Starship theme
starship config

# View available fonts
fc-list | grep -i nerd
```

### For System Administrators

```bash
# Check system health
health-check

# View performance metrics
perf-analyze

# Monitor system in real-time
monitor-status
```

## 📚 What to Read Next

Based on your interests:

**New to Nix?** → [System Overview](../guides/system-overview.md)

**Want to customize?** → [Personalization Guide](../guides/personalization.md)

**Developer setup?** → [Development Environment](../development/environment-templates.md)

**Need help?** → [Troubleshooting](../technical/troubleshooting.md)

## 🚨 If Something's Wrong

### Common Issues and Quick Fixes

**Rebuild fails?**

```bash
# Clean build and try again
nix-collect-garbage -d
rebuild
```

**Git not working?**

```bash
# Reconfigure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

**Shell functions missing?**

```bash
# Reload shell configuration
source ~/.zshrc
```

**Need to start over?**

```bash
# Reset to clean state (this is safe)
cd ~/Documents/dotfile
git stash
git pull
rebuild
```

## 🎉 You're All Set

Your Nix Darwin system is now ready to use! Here are some things you can do:

- **Explore**: Try different aliases and commands
- **Customize**: Modify themes, add packages, create shortcuts
- **Develop**: Set up project environments with `setup-dev-env`
- **Monitor**: Check system health with `health-check`
- **Learn**: Read through the documentation guides

Remember: Your configuration is declarative, so changes are safe and reversible!

---

💡 **Next**: Ready to make it yours? Check out [Personalization Guide](../guides/personalization.md)
