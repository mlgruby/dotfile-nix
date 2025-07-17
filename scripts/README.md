# Scripts Directory

Organized scripts for the Nix Darwin configuration system.

## Directory Structure

```text
scripts/
├── install/          # Installation and removal scripts
├── setup/           # Configuration and setup utilities  
├── monitoring/      # System monitoring and maintenance
└── utils/          # General utility scripts
```

## 📦 Installation Scripts

### `install/pre-nix-installation.sh`

**Purpose**: Complete system installation and initial setup

- Installs Xcode Command Line Tools, Homebrew, and Nix
- Sets up nix-darwin and home-manager
- Creates initial configuration from template
- **Usage**: `./scripts/install/pre-nix-installation.sh`

### `install/uninstall.sh`

**Purpose**: Safe removal of Nix and related configurations

- Supports dry-run mode for safety
- Creates backups before removal
- Comprehensive cleanup of all components
- **Usage**: `./scripts/install/uninstall.sh [--dry-run]`

## ⚙️ Setup Scripts

### `setup/dev-env.sh`

**Purpose**: Initialize development environments with direnv templates

- Auto-detects project types
- Interactive template selection
- Supports Python, Node.js, Rust, Go, Java, Docker
- **Usage**: `./scripts/setup/dev-env.sh [project-type] [directory]`

### `setup/gpg-github.sh`

**Purpose**: Automated GPG key setup for GitHub

- Generates GPG keys if needed
- Uploads public key to GitHub via gh CLI
- Updates configuration files
- **Usage**: `./scripts/setup/gpg-github.sh`

### `setup/aws-sso.sh`

**Purpose**: AWS SSO configuration for cross-shell compatibility

- Sets up AWS SSO profiles
- Creates convenient aliases
- Supports both Bash and Zsh
- **Usage**: `./scripts/setup/aws-sso.sh`

### `setup/validate-ssh.sh`

**Purpose**: SSH configuration validation and troubleshooting

- Checks SSH key existence and types
- Validates GitHub connectivity
- Provides troubleshooting guidance
- **Usage**: `./scripts/setup/validate-ssh.sh`

## 📊 Monitoring Scripts

### `monitoring/system-health-monitor.sh`

**Purpose**: System health monitoring and maintenance

- CPU, memory, disk, and network monitoring
- Nix store health checks
- Automated maintenance tasks
- **Usage**: `./scripts/monitoring/system-health-monitor.sh [--check|--maintain|--report]`

### `monitoring/analyze-build-performance.sh`

**Purpose**: Build performance analysis and optimization

- Analyzes rebuild times and bottlenecks
- Binary cache utilization metrics
- Performance optimization suggestions
- **Usage**: `./scripts/monitoring/analyze-build-performance.sh [--profile|--fix|--report]`

## 🔧 Utility Scripts

### `utils/generate-commit-message.sh`

**Purpose**: AI-powered Git commit message generation

- Uses OpenAI API to generate commit messages
- Analyzes git diff for context
- **Prerequisites**: Set `OPENAI_API_KEY` environment variable
- **Usage**: `./scripts/utils/generate-commit-message.sh`

## Quick Access

From the repository root, you can run any script using:

```bash
# Installation
./scripts/install/pre-nix-installation.sh

# Setup utilities
./scripts/setup/dev-env.sh python ./my-project
./scripts/setup/gpg-github.sh
./scripts/setup/validate-ssh.sh

# Monitoring
./scripts/monitoring/system-health-monitor.sh --check

# Utilities
./scripts/utils/generate-commit-message.sh
```

## Integration with Main Setup

The main `setup.sh` in the repository root automatically downloads and runs the pre-nix-installation script for easy initial setup:

```bash
# One-command setup
./setup.sh
```
