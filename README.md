# Nix Darwin System Configuration

A modular, reproducible system configuration for macOS using Nix, nix-darwin, and home-manager.

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

### File Structure

The repository is organized into logical components:

- `darwin/` - System configuration
  - Separates macOS-specific settings
  - Manages system-wide packages
  - Controls security policies

- `home-manager/` - User environment
  - Modular program configurations
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

## Initial Setup

1. **Install Command Line Tools**

```bash
xcode-select --install
```

2. **Clone Configuration**

```bash
mkdir -p ~/Documents
cd ~/Documents
git clone <your-repo-url> dotfile
cd dotfile
```

3. **Configure User Settings**

```bash
cp user-config.template.nix user-config.nix
```

     Edit `user-config.nix` with your information:

```nix
{
  username = "your-macos-username";  # Must match your macOS login
  fullName = "Your Full Name";
  email = "your.email@example.com";
  githubUsername = "your-github-username";
  hostname = "your-hostname";  # e.g., macbook-pro
}
```

4. **Run Installation**

This script automates the initial setup: installs Xcode tools (if needed), Homebrew, Nix, clones this repository if needed, sets up initial symlinks (including for a temporary shell environment from `nix/`), and performs the first system build using `nix-darwin`.

```bash
./pre-nix-installation.sh
```

After the script completes and the first build is successful, **open a new terminal window** for the fully configured environment managed by Home Manager to take effect.

## Applying Changes

After the initial setup, to apply any changes you make to the configuration files in this repository, run the following command from the `~/Documents/dotfile` directory:

```bash
sudo darwin-rebuild switch --flake .#$(hostname)
# Or use the 'rebuild' alias (which includes sudo automatically)
rebuild
```

**Note:** The `sudo` is required due to recent nix-darwin updates that require system activation to run as root for security reasons.

## Directory Structure

```bash
.
├── darwin/                      # macOS system configuration
│   ├── configuration.nix        # Core system settings
│   ├── homebrew.nix             # Homebrew package management
│   ├── nix-settings.nix         # Nix daemon configuration
│   ├── macos-defaults.nix       # macOS system defaults
│   └── misc-system.nix          # Miscellaneous system settings
├── flake.lock                   # Lock file for dependencies
├── flake.nix                    # System definition
├── home-manager/                # User environment
│   ├── aliases.nix              # Shell aliases
│   ├── default.nix              # Main user configuration
│   ├── neovim.nix               # Neovim configuration
│   └── modules/                 # Configuration modules
│       ├── alacritty/           # Terminal emulator
│       │   ├── config.toml      # Alacritty configuration
│       │   └── default.nix      # Module definition
│       ├── aws-cred.nix         # AWS credentials management
│       ├── aws.nix              # AWS CLI configuration
│       ├── git.nix              # Git configuration
│       ├── github.nix           # GitHub CLI setup
│       ├── karabiner/           # Keyboard customization
│       │   └── default.nix      # Module definition
│       ├── lazygit.nix          # Git TUI configuration
│       ├── rectangle.nix        # Window management
│       ├── starship.nix         # Shell prompt
│       ├── tmux.nix             # Terminal multiplexer
│       └── zsh.nix              # Shell configuration
├── nix/                         # Nix configuration
│   ├── dynamic-config.zsh       # Dynamic shell config
│   ├── nix.conf                 # Nix settings
│   └── zshrc                    # ZSH configuration
├── docs/                        # Documentation
├── pre-nix-installation.sh      # Installation script
├── uninstall.sh                 # Uninstallation script
├── user-config.nix              # User settings (Created from template)
└── user-config.template.nix     # Template for user settings
```

**Note on `nix/` Directory:** The files `nix/zshrc` and `nix/dynamic-config.zsh` are symlinked directly into `~/` by the `pre-nix-installation.sh` script. They provide a minimal, temporary shell environment immediately after the script finishes, before you open a new terminal. The full, robust shell environment is declaratively configured by Home Manager (`home-manager/modules/zsh.nix`) and takes effect in new terminal sessions after the first build.

## Quick Reference

### System Commands

```bash
rebuild   # Alias for sudo darwin-rebuild switch --flake .#$(hostname)
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

# Cloud
awsp      # Switch AWS profile
gcs       # Switch GCloud config
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
