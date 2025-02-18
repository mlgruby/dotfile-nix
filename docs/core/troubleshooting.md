# Troubleshooting Guide

Common issues and their solutions when using the Nix Darwin configuration.

## Build Failures

### Command Line Tools Issues

```bash
# Error: Xcode Command Line Tools not found
xcode-select --install

# Error: Command Line Tools installation failed
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

### Nix Store Issues

```bash
# Error: Permission issues with /nix
sudo chown -R $(whoami):staff /nix

# Error: Corrupt Nix store
nix-store --verify --check-contents --repair
```

## Homebrew Problems

### Installation Issues

```bash
# Error: Homebrew not installing
rm -rf /opt/homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Error: Permissions on /opt/homebrew
sudo chown -R $(whoami):admin /opt/homebrew
```

### Package Issues

```bash
# Error: Brew package conflicts
brew doctor
brew update && brew upgrade
```

## Configuration Issues

### User Configuration

```bash
# Error: user-config.nix not found
cp user-config.template.nix user-config.nix
# Edit user-config.nix with your details

# Error: Wrong hostname
hostname  # Check current hostname
# Update hostname in user-config.nix
```

### Build Errors

```bash
# Error: Configuration not applying
darwin-rebuild switch --flake .

# Error: Flake not updating
rm flake.lock
nix flake update
```

## Common Error Messages

### "attribute 'foo' missing"

This usually means:

1. A package name is misspelled
2. The package isn't available in your current nixpkgs
3. You need to update your flake

Solution:

```bash
# Update flake and rebuild
update
```

### "cannot link '/nix/store/...'"

This usually means:

1. Permission issues
2. Disk space issues
3. Corrupt store path

Solution:

```bash
# Clean and repair
nix-collect-garbage -d
nix-store --verify --check-contents --repair
```

### "darwin-rebuild command not found"

This usually means:

1. Nix installation is incomplete
2. PATH is not set correctly

Solution:

```bash
# Reload shell configuration
source ~/.zshrc

# Reinstall if needed
./pre-nix-installation.sh
```

## Getting Help

1. **Check Logs**

   ```bash
   # Show last build log
   less /tmp/nix-build-*.log
   ```

2. **Verify Configuration**

   ```bash
   # Check nix configuration
   nix show-config
   
   # Check flake inputs
   nix flake info
   ```

3. **Reset to Known State**

   ```bash
   # Clean everything and rebuild
   nix-collect-garbage -d
   rm flake.lock
   nix flake update
   rebuild
   ```

## Prevention

1. **Before Making Changes**
   - Backup your `user-config.nix`
   - Commit working configuration
   - Create a new branch for testing

2. **Regular Maintenance**
   - Run `update` regularly
   - Clean old generations with `cleanup`
   - Monitor disk space usage

3. **Keep Track**
   - Document your changes
   - Use git commits effectively
   - Test changes incrementally
