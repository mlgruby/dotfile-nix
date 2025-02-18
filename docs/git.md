# Git & GitHub Configuration

Comprehensive Git and GitHub CLI setup with custom workflows and aliases.

## Git Configuration

### Core Settings

```nix
programs.git = {
  userName = "Your Name";
  userEmail = "your.email@example.com";
  extraConfig = {
    init.defaultBranch = "develop";
    pull.rebase = true;
    push.autoSetupRemote = true;
  };
};
```

### Quick Commands

```bash
# Basic Operations
gs      # Git status
gp      # Git push
gl      # Git pull
gd      # Git diff
gre     # List remotes

# Advanced Operations
gpush   # Stage and commit with message
gpushf  # Force push (use carefully!)
gpushnew # Push new branch and set upstream
gcan    # Amend commit without editing

# Git Utilities
lg      # Open LazyGit TUI
```

## GitHub CLI

### Pull Request Workflow

```bash
# PR Management
ghprc   # Checkout PR interactively
ghprl   # List all PRs
ghpro   # List open PRs
ghprch  # Check PR status
ghprcr  # Create new PR

# Repository Management
ghrv    # View repo in browser
ghrc    # Clone repository
ghrf    # Fork repository
```

### Issue Management

```bash
ghil    # List issues
ghic    # Create issue
ghiv    # View issue
```

## LazyGit Configuration

Terminal UI for Git operations (`lg` command):

- Branch management
- Commit history
- Stash operations
- Remote management
