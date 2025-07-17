# Frequently Asked Questions (FAQ)

Common questions and answers about the Nix Darwin dotfiles configuration.

## 🚀 Getting Started

### Q: What is Nix and why should I use it?

**A:** Nix is a package manager that provides reproducible, declarative package management. Benefits include:

- **Reproducible**: Same configuration always produces same result
- **Rollback capability**: Can always go back to previous working state
- **Isolation**: Packages don't interfere with each other
- **Declarative**: Describe what you want, not how to get there

### Q: How is this different from other dotfiles?

**A:** This configuration uses Nix Darwin + Home Manager for:

- **System-wide consistency**: Both system and user environment managed declaratively
- **Reproducibility**: Exact same setup across machines
- **Safety**: Atomic updates with rollback capability
- **Integration**: macOS-specific optimizations with Homebrew compatibility

### Q: Do I need to know Nix to use this?

**A:** No! The configuration is designed to be usable without deep Nix knowledge:

- Pre-configured with sensible defaults
- Simple commands (`rebuild`, `update`, `cleanup`)
- Comprehensive documentation and guides
- You can learn Nix gradually as you customize

## 🔧 Configuration

### Q: How do I add new software?

**A:** Depends on the type:

- **CLI tools**: Add to `home-manager/default.nix` or `darwin/configuration.nix`
- **GUI apps**: Add to `darwin/homebrew.nix` casks
- **Development tools**: Use `setup-dev-env` for project-specific environments

See: [Package Management Guide](../guides/package-management.md)

### Q: How do I customize the theme?

**A:** Edit the Stylix configuration in `darwin/configuration.nix`:

```nix
stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
```

Available themes: Gruvbox, Tokyo Night, Catppuccin, Nord, Solarized

See: [Personalization Guide](../guides/personalization.md)

### Q: Can I change the directory structure?

**A:** Yes! Edit `user-config.nix`:

```nix
directories = {
  dotfiles = "config/dotfiles";  # Instead of Documents/dotfile
  workspace = "projects";        # Instead of Development
  # Add custom directories
  personal = "projects/personal";
};
```

## 🐛 Troubleshooting

### Q: My build is failing, what should I do?

**A:** Try these steps in order:

1. `health-check` - Check system status
2. `cleanup && rebuild` - Clean and rebuild
3. Check [Troubleshooting Guide](../technical/troubleshooting.md)
4. Review recent changes: `git log --oneline -10`

### Q: How do I roll back a bad change?

**A:** Nix provides easy rollback:

```bash
# Roll back to previous generation
sudo darwin-rebuild rollback

# Or list all generations and pick one
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
sudo darwin-rebuild switch --flake .#$(hostname) --rollback
```

### Q: Updates are slow, how can I speed them up?

**A:** The configuration includes several optimizations:

- Binary caches for pre-built packages
- Parallel builds with all CPU cores
- Keep derivations for faster rebuilds

For more: [Performance Optimization](../performance/rebuild-optimization.md)

## 🔄 Updates and Maintenance

### Q: How often should I update?

**A:** Recommended approach:

- **Weekly**: `update` to get latest packages
- **Monthly**: Review and clean with `cleanup`
- **As needed**: Add new software or configuration changes

### Q: What's the difference between `rebuild` and `update`?

**A:**

- `rebuild`: Apply current configuration changes
- `update`: Update all package versions, then rebuild
- `cleanup`: Remove old generations and clean Nix store

### Q: How do I backup my configuration?

**A:** Your entire configuration is in Git:

```bash
# Your config is already version controlled
git add . && git commit -m "Current configuration"
git push

# Export list of installed packages
nix-env -q > package-list.txt
brew list > homebrew-list.txt
```

## 🛠️ Customization

### Q: How do I add custom shell aliases?

**A:** Edit `home-manager/aliases.nix`:

```nix
shellAliases = {
  # Your custom aliases
  myproject = "cd ~/Development/my-project";
  deploy = "./scripts/deploy.sh";
};
```

### Q: Can I use this with my existing dotfiles?

**A:** Yes, but carefully:

1. **Backup existing dotfiles** first
2. **Gradually migrate** configurations
3. **Use Home Manager** to manage conflicts
4. **Test changes incrementally**

### Q: How do I add a new development environment?

**A:** Use the development environment templates:

```bash
setup-dev-env python   # Creates Python environment
setup-dev-env nodejs   # Creates Node.js environment
setup-dev-env rust     # Creates Rust environment
```

See: [Development Environment Templates](../development/environment-templates.md)

## 🌐 macOS Integration

### Q: Does this work with macOS updates?

**A:** Yes, the configuration is designed to be compatible with macOS updates:

- Uses stable Nix Darwin patterns
- Homebrew handles macOS-specific tools
- System defaults are safely configurable

### Q: Can I use this alongside other package managers?

**A:** Yes, but with care:

- **Homebrew**: Fully integrated and managed by the configuration
- **MacPorts**: Not recommended (conflicts possible)
- **pip/npm/cargo**: Use project-specific environments instead

### Q: How does this affect my existing macOS apps?

**A:** It doesn't interfere with:

- Mac App Store apps
- Existing applications in `/Applications`
- System preferences (unless explicitly configured)

## 🤔 Advanced Questions

### Q: Can I use this configuration on multiple Macs?

**A:** Absolutely! That's a key benefit:

1. **Clone the repository** on each machine
2. **Update `user-config.nix`** with machine-specific details
3. **Run the installation** script
4. **Enjoy identical environments**

### Q: How do I contribute improvements?

**A:** Contributions welcome:

1. **Fork the repository**
2. **Create feature branch**
3. **Test thoroughly**
4. **Submit pull request**

See: [Contributing Guidelines](contributing.md)

### Q: Is this production-ready?

**A:** Yes, this configuration is:

- **Battle-tested** on daily development workflows
- **Incrementally adoptable** - start small, grow over time
- **Rollback-safe** - can always return to working state
- **Well-documented** with comprehensive guides

## 📚 Still Have Questions?

- **Documentation**: [Complete Guide Index](../README.md)
- **Issues**: Check [GitHub Issues](https://github.com/mlgruby/dotfile-nix/issues)
- **Troubleshooting**: [Technical Guide](../technical/troubleshooting.md)
- **Community**: [Nix Community Resources](community.md)
