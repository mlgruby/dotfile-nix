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

### Level 2: Customization  

- **[Personalizing Your Setup](guides/personalization.md)** - Themes, fonts, shortcuts
- **[Development Environment](guides/development-setup.md)** - Programming tools
- **[Terminal Mastery](guides/terminal-setup.md)** - Shell, aliases, productivity

### Level 3: Advanced Topics

- **[Performance Optimization](guides/performance.md)** - Speed up your system
- **[System Monitoring](guides/monitoring.md)** - Health checks and maintenance
- **[Security & Secrets](guides/security.md)** - Managing sensitive data

## 🎯 By Use Case

Choose your path based on what you want to accomplish:

### 👨‍💻 I'm a Developer

```text
Start Here → Development Environment → Terminal Setup → Performance
```

- [Development Environment Templates](development/environment-templates.md)
- [Git & GitHub Setup](guides/git-setup.md)
- [AWS SSO Setup](guides/aws-sso-setup.md)
- [Python Development](development/python-setup.md)
- [Cloud Tools (AWS, GCP)](development/cloud-setup.md)

### 🎨 I Want Customization

```text
Start Here → Personalization → Themes → Advanced Customization
```

- [Themes & Styling](customization/themes.md)
- [Custom Paths & Directories](customization/paths.md)
- [Keyboard Shortcuts](customization/shortcuts.md)
- [Window Management](customization/window-management.md)

### ⚡ I Want Performance

```text
Start Here → System Overview → Performance → Monitoring
```

- [Rebuild Optimization](performance/rebuild-optimization.md)
- [System Health Monitoring](monitoring/system-health.md)
- [Resource Management](performance/resource-management.md)

### 🔧 I Want to Understand How It Works

```text
Start Here → Architecture → Configuration → Advanced Topics
```

- [System Architecture](technical/architecture.md)
- [Nix Darwin Concepts](technical/nix-concepts.md)
- [Home Manager Deep Dive](technical/home-manager.md)
- [Troubleshooting](technical/troubleshooting.md)

## 📚 Reference Documentation

### Configuration Files

- **[flake.nix](reference/flake-structure.md)** - Main system definition
- **[user-config.nix](reference/user-config.md)** - Personal settings
- **[Darwin Modules](reference/darwin-modules.md)** - System-level config
- **[Home Manager Modules](reference/home-manager-modules.md)** - User config

### Tools & Commands  

- **[Aliases Reference](reference/aliases.md)** - All available shortcuts
- **[Scripts Reference](reference/scripts.md)** - Automation tools
- **[Health Commands](reference/health-commands.md)** - System monitoring

### Advanced Topics

- **[Impermanence Evaluation](advanced/impermanence-evaluation.md)**
- **[NUR Integration Analysis](advanced/nur-integration-analysis.md)**
- **[Secrets Management](advanced/secrets-management-analysis.md)**

## 🆘 Need Help?

### Common Issues

- **[Troubleshooting Guide](help/troubleshooting.md)** - Fix common problems
- **[FAQ](help/faq.md)** - Frequently asked questions
- **[Error Messages](help/error-messages.md)** - Decode error messages

### Getting Support

- **[Community Resources](help/community.md)** - Where to get help
- **[Contributing](help/contributing.md)** - How to improve this configuration
- **[Reporting Issues](help/issues.md)** - Bug reports and features

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
