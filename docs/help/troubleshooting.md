# Troubleshooting Guide

This troubleshooting guide has been moved to provide better organization.

## 🔗 Updated Location

The comprehensive troubleshooting guide is now located at:

**[Technical Troubleshooting Guide](../technical/troubleshooting.md)**

## 🚀 Quick Help

### Common Issues

- **Build failures** → [Build Issues](../technical/troubleshooting.md#build-failures)
- **Package conflicts** → [Package Issues](../technical/troubleshooting.md#homebrew-problems)
- **Configuration errors** → [Config Issues](../technical/troubleshooting.md#configuration-issues)
- **Git problems** → [Git Setup Guide](../guides/git-setup.md)

### Quick Commands

```bash
# System health check
health-check

# Clean and rebuild
cleanup && rebuild

# Check system logs
sudo dmesg | tail -20

# Verify configuration
nix show-config
```

### Getting Help

1. **Check the main troubleshooting guide**: [Technical Troubleshooting](../technical/troubleshooting.md)
2. **Review recent changes**: `git log --oneline -10`
3. **Check system status**: `health-check`
4. **Try a clean rebuild**: `cleanup && rebuild`

If you're still having issues, the comprehensive troubleshooting guide has detailed solutions for common problems.
