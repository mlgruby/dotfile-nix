# Package Management Guide

Master the hybrid package management approach used in your Nix Darwin configuration.

## 🏗️ Package Management Strategy

Your system uses a **three-tier approach** for optimal compatibility and performance:

```text
📦 Package Sources
├── Nix Packages (Primary) - CLI tools, development utilities
├── Homebrew (Compatibility) - GUI apps, fonts, macOS-specific tools
└── Development Templates (Isolated) - Project-specific environments
```

## 🔵 Nix Package Management

### System-Level Packages

**Location**: `darwin/configuration.nix`

```nix
environment.systemPackages = with pkgs; [
  # Core Development Tools
  git curl wget jq yq
  python3 nodejs
  
  # System Utilities  
  coreutils gnused gawk
  openssh openssl
  
  # Build Dependencies
  cmake pkg-config
  readline sqlite zlib
];
```

**Best for**:

- CLI development tools
- System utilities
- Language runtimes
- Build dependencies

### User-Level Packages

**Location**: `home-manager/default.nix` and `home-manager/modules/packages/*.nix`

See
[`home-manager/modules/packages/README.md`](../../home-manager/modules/packages/README.md)
for package group ownership rules.

```nix
home.packages = with pkgs; [
  # Enhanced CLI Tools
  ripgrep   # Better grep
  fd        # Better find
  eza       # Better ls
  bat       # Better cat
  btop      # Better top

  # Development Tools
  direnv    # Environment management
  pipx      # Python tool isolation
  sbt       # Scala build tool

  # Language Servers (for Claude Code and IDEs)
  rust-analyzer           # Rust LSP server
  kotlin-language-server  # Kotlin LSP server

  # Documentation
  markdownlint-cli
];
```

Package-only Home Manager modules are split by purpose:

```text
home-manager/modules/packages/
├── cloud.nix        # AWS, Kubernetes, Terraform helpers
├── development.nix  # linters, benchmarking, analysis tools
├── languages.nix    # language servers and global language tooling
├── security.nix     # sops, age
├── system.nix       # fd, duf, dust, fastfetch, network/system tools
└── text.nix         # pandoc, poppler-utils, glow, yq-go, JSON/YAML tools
```

**Best for**:

- Personal productivity tools
- User-specific utilities
- Development environments
- Documentation tools

### Finding Nix Packages

```bash
# Search for packages
nix search nixpkgs python
nix search nixpkgs nodejs

# Get package information
nix-env -qa | grep python
nix show-config
```

**Popular Package Categories**:

| Category | Examples | Command |
|----------|----------|---------|
| **Languages** | `python3`, `nodejs`, `rustc` | `nix search nixpkgs language` |
| **Editors** | `neovim`, `emacs`, `vscode` | `nix search nixpkgs editor` |
| **Shell Tools** | `ripgrep`, `fd`, `fzf` | `nix search nixpkgs cli` |
| **Development** | `git`, `cmake`, `docker` | `nix search nixpkgs dev` |

## 🍺 Homebrew Package Management

### Selected CLI Formulae (Brews)

**Locations**:

- `darwin/homebrew.nix` - Homebrew activation and profile composition
- `darwin/homebrew-packages/brews/` - Shared formulae by ownership type
- `darwin/profiles/*.nix` - Profile-specific additions and removals

```nix
homebrew = {
  enable = true;
  onActivation = {
    autoUpdate = true;
    cleanup = "uninstall";
  };
  
  brews = [
    # macOS-Specific Tools
    "mas"              # Mac App Store CLI

    # Language runtimes and build chains intentionally kept global
    "node"
    "go"
    "python@3.12"
    "gnu-getopt"       # GNU implementation of getopt
  ];
};
```

### GUI Applications (Casks)

Shared casks live under `darwin/homebrew-packages/casks/`.

```nix
homebrew.casks = [
  # Browsers
  "brave-browser"
  "firefox"
  
  # Development
  "visual-studio-code"
  "docker-desktop"
  "postman"
  
  # Productivity
  "notion"
  "slack"
  "zoom"
  
  # Media
  "spotify"
  "vlc"
  
  # Utilities
  "rectangle"        # Window management
  "alt-tab"         # Better app switching
  "the-unarchiver"  # Archive extraction
];
```

### Homebrew Best Practices

**Use Homebrew for**:

- GUI applications
- Fonts and vendor apps
- macOS-specific utilities
- Proprietary software
- Tools not available or not appropriate in nixpkgs
- Global language/build toolchains only when deliberately shared across projects

**Managing Homebrew**:

```bash
# Update all packages
brew update && brew upgrade

# Search for packages
brew search docker
brew search --casks figma

# Remove unused dependencies
brew autoremove

# Check system health
brew doctor
```

## 🔧 Development Environment Templates

Toolchains have their own ownership policy because global runtimes can affect
IDEs and project builds. See [Toolchain Ownership](toolchain-ownership.md)
before moving packages such as `node`, `go`, `python@3.12`, `uv`, `poetry`,
`maven`, `cmake`, `pkg-config`, or `kafka`.

### Project-Specific Environments

**Using direnv + nix**:

```bash
# Create Python development environment
setup-dev-env python

# Create Node.js development environment  
setup-dev-env nodejs

# Create Rust development environment
setup-dev-env rust
```

**Generated `.envrc` example**:

```bash
# .envrc for Python project
use flake .#python-dev

# Available in project directory:
# - Python 3.11
# - pip, pipx, poetry
# - pytest, black, mypy
# - Project-specific dependencies
```

### Language-Specific Management

**Python**:

```bash
# System Python via Homebrew
python3 --version  # → Python 3.12.x

# Project Python via uv
uv python install 3.11
uv venv --python 3.11
uv pip install requirements.txt
```

**Node.js**:

```bash
# System Node via Homebrew
node --version  # → v20.x.x

# Project Node via nvm (if needed)
nvm use 18
npm install
```

**Rust**:

```bash
# Rust via Nix or rustup
rustc --version
cargo new my-project
```

## 📋 Package Management Workflows

### Adding New Software

#### 1. Determine the Right Source

**Decision Tree**:

```text
Is it a GUI app? → Homebrew Cask
    ↓ No
Is it macOS-specific? → Homebrew Brew
    ↓ No  
Is it for development? → Check if in nixpkgs
    ↓ Yes
Add to Nix packages
    ↓ No (not in nixpkgs)
Consider Homebrew or build from source
```

#### 2. Add to Configuration

**For Nix packages**:

```nix
# Add to home-manager/default.nix
home.packages = with pkgs; [
  # existing packages...
  new-package-name
];
```

**For Homebrew**:

```nix
# Shared formulae live under darwin/homebrew-packages/brews/.
[
  "new-cli-tool"
]

# Shared casks live under darwin/homebrew-packages/casks/.
[
  "new-gui-app"
]
```

#### 3. Apply Changes

```bash
# Rebuild system to apply changes
rebuild

# Or for faster testing (Homebrew only)
brew install new-package
```

### Removing Software

#### Nix Packages

```nix
# Remove from configuration file
# home.packages = with pkgs; [
#   unwanted-package  # Remove this line
# ];

# Rebuild to apply
rebuild

# Clean up unused packages
cleanup
```

#### Homebrew Packages

```nix
# Remove shared packages from darwin/homebrew-packages/.
#
# For one profile only, add the package to removeBrews or removeCasks in
# darwin/profiles/work.nix or darwin/profiles/personal.nix.

# Or remove manually
brew uninstall unwanted-package
brew uninstall --cask unwanted-app
```

### Updating Packages

#### Update All (Recommended)

```bash
# Update everything together
update  # → nix flake update && rebuild
```

#### Selective Updates

```bash
# Update only Nix packages
nix flake update && rebuild

# Update only Homebrew
brew update && brew upgrade

# Update specific Homebrew package
brew upgrade specific-package
```

## 🔍 Package Discovery and Research

### Finding the Right Package

**Search Commands**:

```bash
# Nix packages
nix search nixpkgs keyword
nix-env -qa | grep keyword

# Homebrew formulae
brew search keyword

# Homebrew casks
brew search --casks keyword
```

**Online Resources**:

- [Nix Package Search](https://search.nixos.org/packages)
- [Homebrew Formulae](https://formulae.brew.sh/)
- [Homebrew Casks](https://formulae.brew.sh/cask/)

### Package Information

```bash
# Nix package details
nix info nixpkgs#package-name

# Homebrew package info
brew info package-name
brew info --cask app-name

# Check what's installed
nix-env -q
brew list
brew list --cask
```

## ⚠️ Common Issues and Solutions

### Version Conflicts

**Problem**: Different tools need different versions

**Solutions**:

1. **Use development templates** for project isolation
2. **Pin specific versions** in Nix
3. **Use version managers** (nvm, pyenv, etc.)

```nix
# Pin specific versions
home.packages = with pkgs; [
  python311  # Instead of python3
  nodejs-18_x  # Instead of nodejs
];
```

### Nix vs Homebrew Conflicts

**Problem**: Same package installed via both

**Solutions**:

1. **Check your PATH**: `echo $PATH`
2. **Prefer Nix over Homebrew** for CLI tools
3. **Remove duplicates**:

```bash
# Remove Homebrew version if Nix version exists
brew uninstall conflicting-package

# Or remove from configuration
```

### Slow Updates

**Problem**: Updates take too long

**Solutions**:

1. **Use binary caches** (already configured)
2. **Update incrementally**:

```bash
# Update only flake inputs
nix flake update --commit-lock-file

# Build without switching (test first)
sudo darwin-rebuild build --flake .

# Switch only if build succeeds
sudo darwin-rebuild switch --flake .
```

## 📊 Package Management Best Practices

### Organization

1. **Group related packages** together in config files
2. **Comment non-obvious packages**
3. **Keep lists alphabetically sorted**
4. **Use consistent formatting**

### Performance

1. **Leverage binary caches** for faster installs
2. **Pin versions** only when necessary
3. **Clean up regularly** with `cleanup`
4. **Use development templates** for project isolation

### Maintenance

1. **Update regularly** but not obsessively
2. **Test updates** in a separate generation first
3. **Document package purposes** in comments
4. **Review installed packages** quarterly

### Example Organized Configuration

```nix
home.packages = with pkgs; [
  # Core System Tools
  coreutils gnused gawk
  
  # File Management
  fd ripgrep bat eza tree
  
  # Development Core
  git gh lazygit
  neovim tmux direnv
  
  # Language Runtimes
  python3 nodejs rustc
  
  # Cloud & Infrastructure  
  awscli2 terraform kubectl
  
  # Documentation & Productivity
  markdownlint-cli pandoc
  
  # System Monitoring
  btop htop duf dust
];
```

## 🚀 Quick Reference

### Essential Commands

```bash
# System Management
rebuild                    # Apply all changes
update                     # Update and rebuild
cleanup                    # Remove old generations

# Package Search
nix search nixpkgs python  # Find Nix packages
brew search docker         # Find Homebrew formulae  
brew search --casks vscode # Find Homebrew casks

# Package Information
nix info nixpkgs#git       # Nix package details
brew info terraform        # Homebrew package info

# Development Environments
setup-dev-env python       # Create Python environment
setup-dev-env nodejs       # Create Node.js environment
direnv allow               # Activate project environment
```

### File Locations

- **System packages**: `darwin/configuration.nix`
- **User packages**: `home-manager/default.nix`  
- **Homebrew config**: `darwin/homebrew.nix`
- **Shared Homebrew packages**: `darwin/homebrew-packages/`
- **Development templates**: `scripts/setup/dev-env.sh`

**Next Steps**:

- [Development Environment Templates](../development/environment-templates.md)
- [System Configuration Guide](configuration-basics.md)
- [Performance Optimization](../performance/rebuild-optimization.md)
