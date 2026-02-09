# System Overview

Understanding how your Nix Darwin dotfiles system works and how all the
pieces fit together.

## 🏗️ Architecture Overview

Your dotfiles system is built on several layers that work together:

```text
┌─────────────────────────────────────────────────────────────────┐
│                        Your Daily Workflow                      │
├─────────────────────────────────────────────────────────────────┤
│                     Shell Commands & Aliases                    │
│                   (rebuild, health-check, awsp)                 │
├─────────────────────────────────────────────────────────────────┤
│                       Home Manager                              │
│                  (User Environment & Dotfiles)                  │
├─────────────────────────────────────────────────────────────────┤
│                        Nix Darwin                               │
│                     (System Configuration)                      │
├─────────────────────────────────────────────────────────────────┤
│                      Nix Package Manager                        │
│                   (Reproducible Builds)                         │
├─────────────────────────────────────────────────────────────────┤
│                          macOS                                  │
│                    (Operating System)                           │
└─────────────────────────────────────────────────────────────────┘
```

## 🔧 Core Components

### 1. Nix Package Manager

**What it does**: Provides reproducible, declarative package management

**Key features**:

- Packages are immutable and isolated
- Multiple versions can coexist
- Atomic upgrades and rollbacks
- Shared store for efficiency

**Where you see it**:

```bash
/nix/store/    # All packages live here
nix-channel    # Package repositories
nix-env        # User package management
```

### 2. Nix Darwin

**What it does**: Manages macOS system-level configuration

**Key features**:

- System settings and preferences
- System-wide packages
- macOS-specific integrations
- Homebrew management

**Configuration files**:

```text
darwin/
├── configuration.nix      # Main system config
├── homebrew.nix          # Package management
├── nix-settings.nix      # Nix daemon config
├── macos-defaults.nix    # macOS system defaults
└── misc-system.nix       # Additional settings
```

### 3. Home Manager

**What it does**: Manages user-level configuration and dotfiles

**Key features**:

- User environment setup
- Dotfile management
- Application configuration
- Shell environment

**Configuration files**:

```text
home-manager/
├── default.nix           # Main user config
├── aliases.nix           # Shell shortcuts
├── neovim.nix           # Editor config
└── modules/             # Individual tool configs
    ├── alacritty/       # Terminal
    ├── git.nix          # Version control
    ├── zsh.nix          # Shell
    └── aws-sso.nix      # Cloud tools
```

### 4. Flake System

**What it does**: Defines your entire system as code

**Key features**:

- Input management (dependencies)
- Reproducible builds
- Version locking
- Multiple output targets

**Main file**: `flake.nix` - Your system definition

## 📦 Package Management Strategy

Your system uses a **hybrid approach** for maximum compatibility:

### Nix Packages (Preferred)

```nix
# Fast, reproducible, isolated
environment.systemPackages = with pkgs; [
  git curl wget jq
];
```

**Best for**: CLI tools, development utilities, libraries

### Homebrew (Compatibility)

```nix
# Native macOS integration
homebrew = {
  brews = [ "awscli" "terraform" ];
  casks = [ "brave-browser" "docker-desktop" ];
};
```

**Best for**: GUI applications, macOS-specific tools

### Development Templates (Project-specific)

```bash
# Project-isolated environments
setup-dev-env python  # Creates .envrc with Python tools
setup-dev-env nodejs  # Creates .envrc with Node.js tools
```

**Best for**: Language runtimes, project dependencies

## 🔄 Build and Deployment Process

### How Changes Get Applied

1. **Edit Configuration**

   ```bash
   vim darwin/homebrew.nix  # Add a package
   ```

2. **Build System**

   ```bash
   rebuild  # darwin-rebuild switch --flake .
   ```

3. **Nix Evaluates**
   - Reads your configuration
   - Determines what needs to change
   - Downloads required packages

4. **System Updates**
   - Switches to new generation
   - Updates symlinks
   - Restarts affected services

5. **Rollback Available**

   ```bash
   sudo darwin-rebuild rollback  # If something breaks
   ```

### Generation Management

```bash
# List all generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Switch to previous generation
sudo darwin-rebuild rollback

# Delete old generations
sudo nix-collect-garbage -d
```

## 🗂️ File Organization

### Your Repository Structure

```text
dotfile/
├── flake.nix              # System definition (entry point)
├── flake.lock             # Dependency versions (auto-generated)
├── user-config.nix        # Your personal settings
├── darwin/                # System-level configuration
│   ├── configuration.nix  # Main system config
│   ├── homebrew.nix       # Package management
│   └── *.nix             # Other system modules
├── home-manager/          # User-level configuration
│   ├── default.nix       # Main user config
│   ├── aliases.nix       # Shell shortcuts
│   └── modules/          # Tool-specific configs
├── scripts/               # Automation scripts
│   ├── monitoring/
│   │   ├── system-health-monitor.sh
│   │   └── analyze-build-performance.sh
│   ├── install/
│   ├── setup/
│   └── utils/
└── docs/                 # Documentation
```

### Runtime File Locations

```text
~/.config/              # Application configurations
├── nix/               # Nix user settings
├── git/               # Git configuration
├── alacritty/         # Terminal configuration
└── starship.toml      # Shell prompt

~/.local/state/        # Application state
├── nix/               # Nix user state
└── home-manager/      # Home Manager state

/nix/store/            # All packages (immutable)
/etc/nix/              # System Nix configuration
```

## 🔍 Understanding the Magic

### How Nix Achieves Reproducibility

1. **Cryptographic Hashes**: Every package has a unique hash based on its inputs
2. **Functional Builds**: Same inputs always produce same outputs
3. **Isolation**: Packages can't interfere with each other
4. **Immutability**: Once built, packages never change

### How Home Manager Works

1. **Symlink Management**: Creates symlinks from `/nix/store` to your home directory
2. **File Generation**: Generates config files from Nix expressions
3. **Service Management**: Manages user services (launchd on macOS)
4. **Environment Setup**: Sets up PATH, environment variables, etc.

### How Darwin Integration Works

1. **System Preferences**: Configures macOS defaults and settings
2. **Package Installation**: Manages system-wide packages
3. **Service Management**: Handles system services and daemons
4. **Homebrew Integration**: Bridges Nix and Homebrew ecosystems

## 🎯 Daily Workflow

### Making Changes

1. **Small Config Changes**:

   ```bash
   vim user-config.nix    # Edit personal settings
   rebuild               # Apply changes
   ```

2. **Adding Software**:

   ```bash
   vim darwin/homebrew.nix  # Add to brews or casks
   rebuild                  # Install and configure
   ```

3. **Development Setup**:

   ```bash
   cd my-project
   setup-dev-env python    # Create project environment
   direnv allow            # Activate environment
   ```

### Monitoring and Maintenance

```bash
health-check          # Quick system status
health-maintain       # Full maintenance
cleanup              # Remove old generations
perf-analyze         # Performance analysis
```

## 🚨 Troubleshooting Philosophy

**Your system is designed to be safe**:

- **Declarative**: You describe what you want, not how to get there
- **Reproducible**: Same configuration always produces same result
- **Rollback-able**: You can always go back to previous working state
- **Atomic**: Changes either fully succeed or fully fail

**When something breaks**:

1. Don't panic - you can always roll back
2. Check the error message - Nix errors are usually descriptive
3. Try a clean rebuild - `nix-collect-garbage -d && rebuild`
4. Roll back if needed - `sudo darwin-rebuild rollback`

## 📚 Next Steps

Now that you understand the architecture:

- **[Configuration Basics](configuration-basics.md)** - Learn to modify your setup
- **[Personalization Guide](personalization.md)** - Make it yours
- **[Development Setup](../development/environment-templates.md)** - Set up coding environments
- **[Performance Guide](performance.md)** - Optimize your system

---

💡 **Remember**: Your entire system is defined as code. This means it's
reproducible, versionable, and shareable!
