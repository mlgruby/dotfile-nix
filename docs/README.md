# Documentation Guide

Welcome to the **Nix Darwin Dotfiles** documentation! This guide is organized
to help you get started quickly and then dive deeper into specific topics as
needed.

## 🚀 Quick Start (New Users Start Here!)

**Goal**: Get your system up and running in 30 minutes

1. **[Installation Guide](getting-started/installation.md)** - Step-by-step setup
2. **[First Steps](getting-started/first-steps.md)** - Essential configuration
3. **[Quick Reference](getting-started/quick-reference.md)** - Common commands

## 📖 Learning Path

Follow this sequence to master your dotfiles configuration:

### Level 1: Basics

- **[System Overview](guides/system-overview.md)** - Understanding the architecture
- **[Configuration Basics](guides/configuration-basics.md)** - How to modify settings
- **[Package Management](guides/package-management.md)** - Adding/removing software
- **[Toolchain Ownership](guides/toolchain-ownership.md)** - Runtime and build-tool ownership policy

### Level 2: Customization

- **[Personalizing Your Setup](guides/personalization.md)** - Themes, fonts, shortcuts
- **[Development Environment](development/environment-templates.md)** - Programming tools
- **[Terminal Mastery](guides/terminal-setup.md)** - Shell, aliases, productivity

### Level 3: Advanced Topics

- **[Performance Optimization](performance/rebuild-optimization.md)** - Speed up your system
- **[System Monitoring](monitoring/system-health.md)** - Health checks and maintenance
- **[Alias System](../home-manager/aliases/README.md)** - Complete alias reference (~220 total)

## 🎯 By Use Case

Choose your path based on what you want to accomplish:

### 👨‍💻 I'm a Developer

```text
Start Here → Development Environment → Terminal Setup → Performance
```

- [Development Environment Templates](development/environment-templates.md)
- [Toolchain Ownership](guides/toolchain-ownership.md)
- [Git & GitHub Setup](guides/git-setup.md)
- [AWS SSO Setup](guides/aws-sso-setup.md)
- [Lazywarden Recovery](guides/lazywarden-recovery.md)
- [Python Development](development/python-setup.md)
- [Cloud Tools (AWS, GCP)](development/cloud-setup.md)

### 🎨 I Want Customization

```text
Start Here → Personalization → Themes → Advanced Customization
```

- [Themes & Styling](customization/themes.md)
- [Custom Paths & Directories](customization/paths.md)
- [Alias System](../home-manager/aliases/README.md) - Shell shortcuts and workflows
- [Scripts](../home-manager/scripts/README.md) - Helper scripts

### ⚡ I Want Performance

```text
Start Here → System Overview → Performance → Monitoring
```

- [Rebuild Optimization](performance/rebuild-optimization.md)
- [System Health Monitoring](monitoring/system-health.md)
- [Refactoring Analysis](../REFACTORING_ANALYSIS.md) - Code optimization opportunities

### 🔧 I Want to Understand How It Works

```text
Start Here → Architecture → Configuration → Advanced Topics
```

- [System Architecture](technical/architecture.md)
- [Troubleshooting](technical/troubleshooting.md)
- [Alias System Improvements](../home-manager/aliases/IMPROVEMENTS.md) - How aliases evolved

## 📚 Reference Documentation

### Quick Access

- **[Alias System](../home-manager/aliases/README.md)** - Complete alias reference (~220 total)
- **[Scripts Guide](../home-manager/scripts/README.md)** - Helper scripts documentation
- **[Lazywarden Recovery](guides/lazywarden-recovery.md)** - Decrypt Lazywarden backup archives
- **[Toolchain Ownership](guides/toolchain-ownership.md)** - Runtime and build-tool ownership policy
- **[Quick Start](../SCRIPTS_QUICKSTART.md)** - Get started with aliases in 5 minutes
- **[Refactoring Analysis](../REFACTORING_ANALYSIS.md)** - Code improvement opportunities

### Configuration Files

- **[flake.nix](../flake.nix)** - Main system definition
- **[hosts.nix](../hosts.nix)** - Host configurations (work/personal)
- **[hosts.example.nix](../hosts.example.nix)** - Host configuration template
- **[Darwin Configuration](../darwin/configuration.nix)** - System-level config
- **[Home Manager](../home-manager/default.nix)** - User environment config

### Tools & Commands

- **[Alias Discovery](#alias-discovery)** - Find and learn aliases
- **[Interactive Scripts](#interactive-scripts)** - FZF-powered helpers
- **[Workflow Shortcuts](#workflow-shortcuts)** - Quick git/docker/k8s operations

### Advanced Topics

- **[Impermanence Evaluation](advanced/impermanence-evaluation.md)**
- **[NUR Integration Analysis](advanced/nur-integration-analysis.md)**
- **[Secrets Management](advanced/secrets-management-analysis.md)**
- **[Onboarding Test Plan](testing/onboarding-test-plan.md)**

### Alias Discovery

Learn your aliases interactively:

```bash
alias-quick         # Quick reference (most-used)
alias-find          # Interactive fuzzy search
alias-help git      # Git aliases only
alias-search docker # Search by keyword
```

See: [Alias System README](../home-manager/aliases/README.md) | [Quick Start](../SCRIPTS_QUICKSTART.md)

### Interactive Scripts

FZF-powered helpers:

```bash
gcb                 # Checkout branch with preview
fshow               # Browse commits with diffs
fstash              # Apply stash interactively
rollback            # System rollback
```

See: [Scripts README](../home-manager/scripts/README.md)

### Workflow Shortcuts

Multi-step operations in one command:

```bash
quickcommit "msg"   # Stage + commit
quickpush "msg"     # Stage + commit + push
quickamend          # Stage + amend
```

See: [Workflow Aliases](../home-manager/aliases/README.md#workflow-shortcuts)

## 🆘 Need Help?

### Common Issues

- **[Troubleshooting Guide](help/troubleshooting.md)** - Fix common problems
- **[FAQ](help/faq.md)** - Frequently asked questions
- **[Technical Troubleshooting](technical/troubleshooting.md)** - Deep technical issues

## 📋 Documentation Map

```text
docs/
├── README.md                    ← You are here!
├── getting-started/             ← New users start here
│   ├── installation.md
│   ├── first-steps.md
│   └── quick-reference.md
├── guides/                      ← Step-by-step guides
│   ├── system-overview.md
│   ├── configuration-basics.md
│   ├── lazywarden-recovery.md
│   ├── toolchain-ownership.md
│   ├── personalization.md
│   ├── development-setup.md
│   ├── terminal-setup.md
│   ├── performance.md
│   ├── monitoring.md
│   └── security.md
├── development/                 ← Developer-focused docs
│   ├── environment-templates.md
│   ├── python-setup.md
│   └── cloud-setup.md
├── customization/              ← Customization guides
│   ├── themes.md
│   ├── paths.md
│   └── shortcuts.md
├── performance/                ← Performance optimization
│   └── rebuild-optimization.md
├── monitoring/                 ← System monitoring
│   └── system-health.md
├── reference/                  ← Reference materials
│   ├── aliases.md
│   ├── scripts.md
│   └── configuration-files.md
├── technical/                  ← Deep technical docs
│   ├── architecture.md
│   ├── troubleshooting.md
│   └── nix-concepts.md
├── advanced/                   ← Advanced topics
│   ├── impermanence-evaluation.md
│   ├── secrets-management-analysis.md
│   └── nur-integration-analysis.md
└── help/                       ← Support and help
    ├── faq.md
    ├── troubleshooting.md
    └── community.md
```

## 🏃‍♂️ Too Busy? Quick Links

**Just want it working?** → [Installation Guide](getting-started/installation.md)

**Want to customize?** → [Personalization Guide](guides/personalization.md)

**Something broken?** → [Troubleshooting](help/troubleshooting.md)

**Developer setup?** → [Development Environment](development/environment-templates.md)

**Performance issues?** → [Performance Guide](performance/rebuild-optimization.md)

---

💡 **Tip**: Bookmark this page! It's your roadmap to mastering your dotfiles.

📖 **Next**: Ready to get started? Head to the [Installation Guide](getting-started/installation.md)!
