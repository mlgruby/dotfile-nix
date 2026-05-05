# System Architecture

This document provides a comprehensive technical overview of the Nix Darwin dotfiles system architecture, explaining how all components work together
 to create a reproducible, maintainable macOS development environment.

## 🏗️ High-Level Architecture

The system is built on a layered architecture where each layer has specific responsibilities:

```text
┌─────────────────────────────────────────────────────────────────┐
│                        User Interface Layer                     │
│                   (Shell Commands & Aliases)                    │
│                  rebuild, health-check, awsp                    │
├─────────────────────────────────────────────────────────────────┤
│                       Application Layer                         │
│                     (Home Manager Modules)                      │
│                   Git, Zsh, Alacritty, AWS SSO                  │
├─────────────────────────────────────────────────────────────────┤
│                      Configuration Layer                        │
│                        (Nix Darwin)                             │
│                System Settings & Package Management             │
├─────────────────────────────────────────────────────────────────┤
│                       Package Layer                             │
│                     (Nix Store + Homebrew)                      │
│                  Reproducible Package Management                │
├─────────────────────────────────────────────────────────────────┤
│                       Foundation Layer                          │
│                          (macOS)                                │
│                     Operating System                            │
└─────────────────────────────────────────────────────────────────┘
```

## 🔧 Core Components

### 1. Nix Package Manager

**Purpose**: Provides the foundation for reproducible package management

**Technical Details**:

- **Store Path**: `/nix/store/` - Immutable package storage
- **Hash-based naming**: Each package has a unique cryptographic hash
- **Functional paradigm**: Same inputs always produce same outputs
- **Isolation**: Packages cannot interfere with each other

**Key Features**:

```bash
# All packages stored with hashes
/nix/store/abc123-git-2.41.0/
/nix/store/def456-nodejs-18.17.0/

# Multiple versions can coexist
/nix/store/ghi789-python-3.11.4/
/nix/store/jkl012-python-3.12.0/
```

### 2. Nix Darwin

**Purpose**: Manages macOS system-level configuration declaratively

**Architecture**:

```text
darwin/
├── configuration.nix      # Main system config entry point
├── nix-settings.nix      # Nix daemon configuration
├── macos-defaults.nix    # macOS system preferences
├── homebrew.nix          # Hybrid package management
├── homebrew-packages/    # Shared Homebrew package lists
├── misc-system.nix       # Additional system settings
└── system-monitoring.nix # Health monitoring & maintenance
```

**Responsibilities**:

- System-wide package installation
- macOS defaults and preferences
- Security settings (TouchID, sudo)
- Service management (launchd)
- Homebrew integration

### 3. Home Manager

**Purpose**: Manages user-level environment and dotfiles

**Modular Architecture**:

```text
home-manager/
├── default.nix           # Main entry point
├── aliases/              # Shell shortcuts grouped by domain
├── neovim.nix           # Editor configuration
└── modules/             # Individual application configs
    ├── alacritty/       # Terminal emulator
    ├── aws-sso.nix      # Cloud authentication
    ├── git.nix          # Version control
    ├── gpg.nix          # Encryption & signing
    ├── ssh.nix          # Secure shell
    ├── tmux.nix         # Terminal multiplexer
    ├── zsh.nix          # Shell configuration
    └── programs/        # CLI tool configurations
        ├── bat.nix      # Syntax highlighting
        ├── btop.nix     # System monitor
        ├── eza.nix      # Directory listing
        ├── jq.nix       # JSON processor
        └── ripgrep.nix  # Search tool
```

### 4. Flake System

**Purpose**: Defines the entire system as code with reproducible inputs

**Structure**:

```nix
{
  description = "Nix-darwin system configuration";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    darwin.url = "github:lnl7/nix-darwin";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    stylix.url = "github:danth/stylix";
  };
  
  outputs = { self, darwin, nixpkgs, home-manager, ... }: {
    darwinConfigurations."hostname" = darwin.lib.darwinSystem {
      # System definition
    };
  };
}
```

## 📦 Package Management Strategy

The system uses a **hybrid approach** for optimal compatibility and performance:

### Nix Packages (Primary)

**Use Cases**:

- CLI development tools
- Libraries and dependencies
- User-level language tooling
- System utilities

**Benefits**:

- Reproducible builds
- Atomic updates
- Rollback capability
- Isolation between packages

**Example**:

```nix
environment.systemPackages = with pkgs; [
  git curl wget jq       # Development tools
  python3 nodejs        # Language runtimes
  awscli2 terraform     # Cloud tools
];
```

### Homebrew (Compatibility Layer)

**Use Cases**:

- GUI applications
- macOS-specific tools
- Global runtimes/build chains intentionally shared across tools
- Proprietary software

**Benefits**:

- Native macOS integration
- Faster updates for GUI apps
- Access to macOS-specific packages

**Example**:

```nix
homebrew = {
  brews = [ "mas" "mackup" ];
  casks = [ "brave-browser" "docker-desktop" "visual-studio-code" ];
};
```

### Development Templates (Project-Specific)

**Use Cases**:

- Project-specific environments
- Language-specific tooling
- Temporary development setups

**Benefits**:

- Project isolation
- Consistent team environments
- Easy environment switching

## 🔄 Build and Deployment Process

### Configuration Evaluation

1. **Input Resolution**: Flake inputs are resolved and locked
2. **Evaluation**: Nix evaluates the configuration expression
3. **Dependency Graph**: Build dependencies are calculated
4. **Derivation**: Package build instructions are generated

### System Generation

```text
Current State → New Generation → Activation
     ↓              ↓              ↓
Generation N   Generation N+1    Active System
     ↓              ↓              ↓
Can rollback   Built but not    Running system
               activated        with new config
```

### Activation Process

1. **Build Phase**: New system generation is built
2. **Symlink Update**: System profile is updated
3. **Service Restart**: Affected services are restarted
4. **User Environment**: Home Manager activates user changes

## 🗂️ File System Organization

### Configuration Files

```text
~/Documents/dotfile/         # Repository root
├── flake.nix               # System definition
├── flake.lock              # Input version lock
├── hosts.nix               # Host configuration (work/personal)
├── darwin/                 # System configuration
├── home-manager/           # User environment
├── scripts/                # Automation scripts
└── docs/                   # Documentation
```

### Runtime Locations

```text
~/.config/                  # Application configurations
├── nix/                   # Nix user settings
├── git/                   # Git configuration
├── alacritty/            # Terminal config
└── ...

~/.local/state/            # Application state
├── nix/                   # Nix user state
└── home-manager/          # Home Manager state

/nix/store/                # Package store (immutable)
/etc/nix/                  # System Nix config
/opt/homebrew/             # Homebrew packages
```

## 🔍 Technical Implementation Details

### User Configuration Validation

The system validates user configuration to prevent common errors:

```nix
validateConfig = config: let
  # Check required attributes
  requiredAttrs = [ "username" "hostname" "fullName" "githubUsername" ];
  missingAttrs = builtins.filter (attr: !(builtins.hasAttr attr config)) requiredAttrs;
  
  # Validate hostname format
  validFormat = builtins.match "[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*" hostname != null;
  
  # Validate directory paths
  validatePath = path: 
    if builtins.match ".*[;&|$`\"'\\\\].*" path != null
    then throw "Invalid characters in directory path: ${path}"
    else true;
in
  # Return validated config or throw descriptive error
```

### Performance Optimizations

**Nix Settings**:

```nix
nix.settings = {
  max-jobs = "auto";              # Optimal CPU utilization
  cores = 0;                      # Use all cores per job
  keep-derivations = true;        # Faster rebuilds
  keep-outputs = true;            # Avoid rebuilds
  eval-cache = true;              # Cache evaluations
  builders-use-substitutes = true; # Use binary caches
};
```

**Binary Caches**:

- `cache.nixos.org` - Official Nix cache
- `nix-community.cachix.org` - Community packages
- `nixpkgs-unfree.cachix.org` - Unfree packages

### Modular Design

Each component is designed to be modular and reusable:

```nix
# Example module structure
{ config, pkgs, lib, ... }: {
  options = {
    # Module-specific options
  };
  
  config = lib.mkIf config.module.enable {
    # Module implementation
  };
}
```

## 🔒 Security Architecture

### Sandbox Isolation

- All builds run in isolated environments
- Network access restricted during builds
- No global state modification during builds

### User Permissions

- System changes require `sudo` for activation
- User environment managed without elevated privileges
- Clear separation between system and user configuration

### Secrets Management

- GPG integration for commit signing
- SSH key management for authentication
- Placeholder for SOPS/Age integration (future enhancement)

## 🎯 Design Principles

### Reproducibility

**Goal**: Same configuration always produces same result

**Implementation**:

- Pinned input versions in `flake.lock`
- Deterministic build processes
- Immutable package store

### Modularity

**Goal**: Easy to maintain and extend

**Implementation**:

- Separated concerns (system vs user)
- Modular component design
- Clear interfaces between modules

### Declarative Configuration

**Goal**: Describe desired state, not procedures

**Implementation**:

- Configuration as code
- Idempotent operations
- State managed by Nix, not scripts

### Rollback Safety

**Goal**: Always recoverable from changes

**Implementation**:

- Generation-based system
- Atomic updates
- Previous generations always available

## 📈 Extensibility

The architecture supports easy extension:

1. **New Applications**: Add modules to `home-manager/modules/`
2. **System Settings**: Extend darwin configuration modules
3. **Package Sources**: Add new binary caches or overlays
4. **Development Environments**: Create project-specific templates

This architecture ensures that the system remains maintainable, secure, and performant while providing the flexibility needed for a modern development
 environment.
