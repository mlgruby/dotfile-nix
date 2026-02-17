# Nix Darwin System Configuration

A modular, reproducible system configuration for macOS using Nix, nix-darwin, and home-manager.

## 🚀 Quick Start

**New to this system?** → [**📖 Complete Documentation Guide**](docs/README.md)

**Just want it working?** → [⚡ Installation Guide](docs/getting-started/installation.md)

**Already installed?** → [📋 Quick Reference](docs/getting-started/quick-reference.md)

## What is Nix?

Nix is a powerful package manager and system configuration tool that takes a unique approach to package management and system configuration. It ensures that installing or upgrading one package cannot break other packages, enables multiple versions of a package to coexist, and makes it easy to roll back to previous versions.

### Key Features

- **Declarative Configuration**
  - Your entire system defined as code
  - Reproducible environments
  - Safe, atomic updates

### Why Use Nix?

- **For Developers**
  - Consistent development environments
  - Project-specific package versions
  - Easy sharing of development setups

- **For System Configuration**
  - Version control your entire system
  - Test changes safely
  - Roll back when needed

### Learn More

- 📘 [Nix Package Manager Guide](https://nixos.org/manual/nix/stable/)
- 🎓 [Nix Pills Tutorial](https://nixos.org/guides/nix-pills/)
- 💡 [Home Manager Manual](https://nix-community.github.io/home-manager/)
- 🔧 [Nix Darwin Documentation](https://github.com/LnL7/nix-darwin)

## Core Components

Each component serves a specific purpose in creating a reproducible system:

- **nix-darwin**: System-level macOS configuration
  - Manages macOS settings and preferences
  - Handles system-level packages
  - Controls system defaults and security

- **Home Manager**: User environment management
  - Manages user-specific configurations
  - Handles dotfiles and program settings
  - Ensures consistent user environment

- **Homebrew**: macOS package management
  - Manages GUI applications
  - Handles macOS-specific packages
  - Provides quick updates for certain tools

## Design Decisions

### Why Nix?

1. **Reproducibility**
    - Exact same setup across machines
    - Version-controlled configuration
    - Declarative system definition

2. **Modularity**
    - Separate system and user config
    - Easy to enable/disable features
    - Reusable configuration modules

3. **Reliability**
    - Atomic updates
    - Rollback capability
    - Consistent state management

4. **Performance Optimized**
    - Lazy loading for heavy functions
    - Streamlined configuration files
    - Fast shell startup times

### File Structure

The repository is organized into logical, optimized components:

- `darwin/` - System configuration
  - Separates macOS-specific settings
  - Manages system-wide packages
  - Controls security policies

- `home-manager/` - User environment (Optimized)
  - Modular program configurations with helper functions
  - Lazy-loaded AWS SSO functions for fast startup
  - Personal preferences and tools
  - Shell and terminal setup

- `nix/` - Core Nix setup
  - Basic Nix configuration
  - Shell integration
  - Dynamic configurations

## Prerequisites

- macOS (Apple Silicon - M*)
- Administrative access
- Basic terminal knowledge

## Quick Start

### Option 1: One-Command Setup (Automatic)

For a quick setup that proceeds automatically after 5 seconds:

```bash
curl -sSL <your-repo-raw-url>/setup.sh | DOTFILES_REPO_URL=<your-repo-raw-url> bash
```

### Option 2: Download and Run (Interactive)

For full interactive control with confirmation prompts:

```bash
curl -o setup.sh <your-repo-raw-url>/setup.sh
chmod +x setup.sh
DOTFILES_REPO_URL=<your-repo-raw-url> ./setup.sh
```

This will automatically:

- Download the full installation script
- Perform system checks
- Ask for your preferred directory name (defaults to `dotfile`)
- Guide you through the complete setup process

## Manual Installation

If you prefer to do the setup manually:

1. **Install Command Line Tools**

```bash
xcode-select --install
```

1. **Clone Configuration**

```bash
mkdir -p ~/Documents
cd ~/Documents
git clone <your-repo-url> dotfile
cd dotfile
```

1. **Configure User Settings**

```bash
cp hosts.example.nix hosts.nix
```

Edit `hosts.nix` with your information:

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

1. **Run Installation**

This script automates the initial setup: installs Xcode tools (if needed), Homebrew, Nix, clones this repository if needed, sets up initial symlinks (including for a temporary shell environment from `nix/`), and performs the first system build using `nix-darwin`.

```bash
./scripts/install/pre-nix-installation.sh
```

After the script completes and the first build is successful, **open a new terminal window** for the fully configured environment managed by Home Manager to take effect.

## SSH Setup & Validation

The installation script includes intelligent SSH key management:

- **Detects existing SSH keys** and lets you choose which to use
- **Creates GitHub-specific key** at `~/.ssh/github` (via symlink or new key)
- **Automatically uploads** your public key to GitHub
- **Configures SSH properly** for seamless GitHub authentication

**Validate your SSH setup anytime:**

```bash
./scripts/setup/validate-ssh.sh
```

This will check:

- SSH key existence and type
- SSH agent configuration
- GitHub connection status
- Home-manager SSH configuration
- Provide troubleshooting guidance

## GPG Setup for GitHub (Optional but Recommended)

For enhanced security and verified commits on GitHub, you can automatically set up GPG signing:

```bash
./scripts/setup/gpg-github.sh --all
# or one scope only:
./scripts/setup/gpg-github.sh --work
./scripts/setup/gpg-github.sh --personal
```

This script will:

- ✅ Read email from `~/.gitconfig-work` / `~/.gitconfig-personal` (prompts if missing)
- ✅ Check if a GPG key already exists for each selected email
- ✅ Generate a new GPG key if needed (using secure defaults)
- ✅ Authenticate with GitHub (if not already done)
- ✅ Upload your public key to GitHub automatically
- ✅ Configure `user.signingkey` + `commit.gpgsign=true` in local `~/.gitconfig-*`
- ✅ Test GPG signing functionality

**Prerequisites:**

- Git email configured locally via `~/.gitconfig-work` / `~/.gitconfig-personal`
- GitHub CLI authentication (script will prompt if needed)

**After setup:**

- All your commits will be automatically signed
- GitHub will show "Verified" badges on your commits
- Your signing key IDs are stored only in local `~/.gitconfig-*` files (not tracked in git)

**Manual GitHub Authentication (if needed):**

```bash
gh auth login
```

**Example Output (`--work`):**

```text
=== GPG + GitHub Signing Setup (Local Profiles) ===

[INFO] Checking prerequisites...
[SUCCESS] Prerequisites check passed
[INFO] Configuring scope: work
[WARNING] No existing GPG key found for john@example.com
[INFO] Generating new GPG key for john@example.com...
[SUCCESS] GPG key generated successfully: ABC123DEF456789
[INFO] Uploading GPG key to GitHub...
[SUCCESS] GPG key uploaded to GitHub successfully
[SUCCESS] Configured /Users/<you>/.gitconfig-work
[SUCCESS] GPG signing test passed
[SUCCESS] GPG setup completed
```

## Applying Changes

After the initial setup, to apply any changes you make to the configuration files in this repository, run the following command from the `~/Documents/dotfile` directory:

```bash
sudo darwin-rebuild switch --flake .#<hostname-from-hosts.nix>
# Or use the 'rebuild' alias (which includes sudo automatically)
rebuild
```

**Note:** The `sudo` is required due to recent nix-darwin updates that require system activation to run as root for security reasons.

## Directory Structure

```bash
dotfile/
├── flake.nix                   # Main configuration
├── flake.lock                  # Dependency lock file
├── hosts.nix                   # Machine configurations (work/personal)
├── hosts.example.nix           # Hosts template
├── setup.sh                    # Quick setup script
├── scripts/                    # Organized scripts
│   ├── install/
│   │   ├── pre-nix-installation.sh    # Installation script
│   │   └── uninstall.sh              # Uninstallation script
│   ├── setup/                        # Setup utilities
│   ├── monitoring/                   # System monitoring
│   └── utils/                        # Utility scripts
```

**Note on `nix/` Directory:** The files `nix/zshrc` and `nix/dynamic-config.zsh` are symlinked directly into `~/` by the `pre-nix-installation.sh` script. They provide a minimal, temporary shell environment immediately after the script finishes, before you open a new terminal. The full, robust shell environment is declaratively configured by Home Manager (`home-manager/modules/zsh.nix`) and takes effect in new terminal sessions after the first build.

## Quick Reference

**⚡ Performance Optimized**: Fast shell startup with lazy-loaded functions and streamlined configurations.

### System Commands

```bash
rebuild   # Uses hostname resolved from active host in hosts.nix
          # (resolved from the active host entry in hosts.nix)
          # Optional: rebuild --work | rebuild --personal
rebuild-work      # Explicit work target
rebuild-personal  # Explicit personal target
update    # Update flake inputs and rebuild
cleanup   # Clean old Nix generations
```

### Common Tools

```bash
# Git
gs        # Status
gp        # Push
gl        # Pull
lg        # LazyGit TUI

# GitHub
ghprc     # Checkout PR
ghprl     # List PRs

# Cloud (lazy-loaded for fast startup)
awsp      # Switch AWS profile
awsf      # Ultimate AWS workflow
```

## Documentation

Comprehensive documentation is organized into the following sections:

### Core Guides

- [Installation Guide](docs/core/installation.md) - Complete setup instructions
- [Configuration Guide](docs/core/configuration.md) - System configuration
- [Troubleshooting Guide](docs/core/troubleshooting.md) - Common issues and solutions

### Tool Configuration

- [Git & GitHub](docs/git.md)
- [Cloud Tools](docs/cloud.md)
- [Terminal Tools](docs/terminal.md)

### Customization

- [Package Management](docs/customization/packages.md) - Adding and managing packages
- [Module System](docs/customization/modules.md) - Working with modules
- [Theme Configuration](docs/customization/themes.md) - Visual customization

Each guide contains detailed examples and best practices for its respective area.

## Uninstallation

```bash
./uninstall.sh
```

## Acknowledgments

This configuration was developed with the assistance of [Cursor](https://cursor.sh), an AI-powered code editor that helped:

- Generate and structure configuration files
- Debug Nix expressions
- Create comprehensive documentation
- Maintain consistent code style

## Important Notes

-*   **Neovim:** The Neovim configuration (`home-manager/neovim.nix`) uses an activation script to bootstrap a [LazyVim](https://www.lazyvim.org/) starter configuration into `~/.config/nvim` if that directory doesn't exist. Subsequent Neovim configuration changes should be made manually within `~/.config/nvim`. For a fully declarative setup, `programs.neovim` would need significant refactoring.
