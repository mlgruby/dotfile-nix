# Installation Guide

A step-by-step guide for setting up your Nix Darwin configuration. This guide will walk you through the complete installation process, from prerequisites to post-installation setup.

## Prerequisites

Before starting the installation, ensure your system meets all requirements and has the necessary tools installed.

### System Requirements

Your Mac needs to meet these basic requirements:

- macOS (Apple Silicon - M*)
- Administrative access
- Internet connection
- 10GB+ free space

### Required Tools

You'll need to install some basic development tools before proceeding:

1. **Command Line Tools**

   Essential development tools from Apple:

   ```bash
   xcode-select --install
   ```

2. **Rosetta 2** (if needed)

   Required for running Intel-based applications:

   ```bash
   softwareupdate --install-rosetta
   ```

## Installation Steps

Follow these steps in order. Each step builds upon the previous one.

### 1. Clone Repository

First, we'll get the configuration files onto your system:

```bash
# Create Documents directory if it doesn't exist
mkdir -p ~/Documents

# Clone the repository
cd ~/Documents
git clone <your-repo-url> dotfile
cd dotfile
```

### 2. Configure User Settings

Personalize the configuration for your use:

1. **Create user configuration**

   Start by copying the template:

   ```bash
   cp hosts.example.nix hosts.nix
   ```

2. **Edit user settings**

   Customize the configuration with your information:

   ```nix
   {
     common = {
       username = "your-macos-username";
       fullName = "Your Full Name";
       githubUsername = "your-github-username";
     };

     hosts = {
       work = {
         hostname = "your-work-hostname";
         profile = "work";
       };

       personal = {
         hostname = "your-personal-hostname";
         profile = "personal";
       };
     };
   }
   ```

   Configure Git emails locally (not in `hosts.nix`):

   ```bash
   git config -f ~/.gitconfig-work user.email "your.work@email.com"
   git config -f ~/.gitconfig-personal user.email "your.personal@email.com"
   git config --global --replace-all "includeIf.gitdir:$HOME/Development/Work/.path" "$HOME/.gitconfig-work"
   git config --global --replace-all "includeIf.gitdir:$HOME/Development/Personal/.path" "$HOME/.gitconfig-personal"
   ```

### 3. Run Installation

Now we'll run the installation script that sets up Nix and all required components:

```bash
chmod +x scripts/install/pre-nix-installation.sh

# Run installation
./scripts/install/pre-nix-installation.sh
```

## Post-Installation

After installation completes, verify everything is working correctly:

### 1. Verify Installation

Check that all major components are installed and working:

```bash
# Check Nix
which nix
nix --version

# Check Home Manager
home-manager --version

# Check Homebrew
brew --version
```

### 2. Initial System Build

Build your system for the first time:

```bash
# Build the system
rebuild
```

### 3. Shell Setup

Ensure your shell is properly configured:

```bash
# Reload shell
exec zsh

# Verify shell configuration
echo $SHELL
```

## Next Steps

After successful installation, you can:

1. Review the [Configuration Guide](../guides/configuration-basics.md)
2. Check [Troubleshooting](../help/troubleshooting.md) if needed
3. Explore [Git & GitHub Setup](../guides/git-setup.md)

## Uninstallation

If you need to remove the configuration and start fresh:

```bash
./uninstall.sh
```
