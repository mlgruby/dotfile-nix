# 🚀 Scripts Quick Start Guide

## Step 1: Rebuild Your System

```bash
rebuild
```

This wires all helper scripts in `~/dotfile/home-manager/scripts/` into your shell aliases (and installs `rebuild`, `rebuild-work`, and `rebuild-personal` to `~/bin/`).

---

## Step 2: Try Them Out!

### ✅ **Most Common - Just Use the Aliases**

```bash
# Interactive Git Operations (use these every day!)
gcb          # Checkout branch with fuzzy search
fshow        # Browse commit history
fstash       # Apply a stash

# Quick Workflows
quickcommit "feat: add feature"    # Stage + commit
quickpush "fix: bug fix"           # Stage + commit + push

# System Management
rollback     # Rollback to previous system generation

# Get Help
alias-quick  # Show most-used aliases
alias-find   # Interactive alias search
alias-help git  # Show git aliases
```

That's it! 90% of the time, you'll just use the aliases above.

---

## Detailed Examples

### 🎯 Example 1: Git Workflow

```bash
# 1. Check status
gs

# 2. Interactive branch selection (uses script behind the scenes)
gcb
#    ↓
#    Shows all branches with commit preview
#    Type to filter, arrow keys to navigate
#    Press ENTER to checkout
#    ↓
#    Switched to branch 'feature/new-stuff'

# 3. Make your changes...

# 4. Quick commit and push
quickpush "feat: add new feature"
#    ↓
#    Stages all changes
#    Commits with message
#    Pushes to remote
```

### 📚 Example 2: Browse Commit History

```bash
fshow
#    ↓
#    Shows git log with graph
#    Right panel shows diff for selected commit
#    Type to search, arrow keys to navigate
#    Press ENTER to view full commit
#    Press ESC to exit
```

### 💾 Example 3: Work with Stashes

```bash
# Stash your work
gst

# Do something else...

# Interactive stash selection
fstash
#    ↓
#    Shows all stashes
#    Right panel shows stash contents
#    Select one and it gets applied
```

### 🔧 Example 4: System Rollback

```bash
# After a bad rebuild
rollback
#    ↓
#    Lists all system generations
#    Shows what's in each generation
#    Select one to rollback
#    ↓
#    System rolled back!
```

### 📖 Example 5: Learn Aliases

```bash
# Quick reference (most-used aliases)
alias-quick
#    ↓
#    ╔═══════════════════════════════════════╗
#    ║  Quick Alias Reference (Most Used)    ║
#    ╚═══════════════════════════════════════╝
#
#    📁 Navigation
#      ..         Go up one directory
#      work       Go to workspace
#
#    📝 Git Basics
#      gs         Git status (short)
#      gaa        Stage all changes
#      ...

# Interactive search
alias-find
#    ↓
#    Fuzzy search all aliases
#    Type to filter
#    Press ENTER to copy alias name

# Search by keyword
alias-search docker
#    ↓
#    d=docker
#    dc=docker-compose
#    dsp=docker ps... (fuzzy stop)
#    ...

# Category-specific help
alias-help git
#    ↓
#    Shows only git-related aliases
```

---

## 🎓 Learning Path

### Day 1: Learn the Basics
```bash
alias-quick   # See most-used commands
gcb           # Try interactive git checkout
fshow         # Browse your commits
```

### Week 1: Discover More
```bash
alias-find    # Explore all aliases interactively
alias-search docker  # Find docker aliases
```

### Month 1: Master Workflows
```bash
quickcommit "message"  # Fast commits
quickpush "message"    # Even faster
alias-help <category>  # Deep dive into categories
```

---

## 🔍 Where Are the Scripts?

The source scripts live in your repository at:
```
~/dotfile/home-manager/scripts/
├── git-fuzzy-checkout.sh
├── git-fuzzy-log.sh
├── git-fuzzy-stash.sh
├── rebuild-system.sh
├── system-rollback.sh
├── cleanup-system.sh
├── update-system.sh
├── agent-usage.py
└── alias-cheatsheet.sh
```

**But you don't need to remember these paths!** Just use the aliases:
- `gcb` → git-fuzzy-checkout.sh
- `fshow` → git-fuzzy-log.sh
- `fstash` → git-fuzzy-stash.sh
- `rebuild` → rebuild-system.sh
- `rollback` → system-rollback.sh
- `cleanup` → cleanup-system.sh
- `update` → update-system.sh
- `alias-help` → alias-cheatsheet.sh

---

## 💡 Pro Tips

1. **Start with aliases** - They're easier to remember
2. **Use tab completion** - Most aliases support it
3. **Interactive is safer** - FZF-powered scripts show previews
4. **Check `alias-quick` daily** - Discover new shortcuts
5. **Customize scripts** - They're in your dotfiles, edit freely!

---

## 🐛 Troubleshooting

### Problem: Scripts not found after rebuild
```bash
# Check if they exist in your repository
ls -la ~/dotfile/home-manager/scripts/

# Rebuild to update Nix store symlinks
rebuild
```

### Problem: Alias not working
```bash
# Reload your shell
rl

# Or check if alias exists
alias | grep gcb
```

### Problem: "fzf not found"
```bash
# Check if fzf is installed
which fzf

# If missing, it should be in your config
# Try rebuilding
rebuild
```

### Problem: Git script says "not a git repository"
```bash
# Make sure you're in a git repo
cd /path/to/your/git/repo
gcb  # Now it will work
```

---

## 📚 Complete Documentation

- **This file**: Quick start guide
- `home-manager/scripts/README.md`: Detailed script documentation
- `home-manager/aliases/README.md`: Complete alias reference
- `home-manager/aliases/IMPROVEMENTS.md`: Development history

---

## 🎯 Next Steps

1. **Run `rebuild`** to install everything
2. **Try `alias-quick`** to see the quick reference
3. **Use `gcb`** in a git repo to try interactive checkout
4. **Run `alias-find`** to explore all aliases

**That's it!** You're ready to use the enhanced alias system. 🎉

---

## 📞 Need Help?

```bash
alias-help          # Full documentation
alias-help quick    # Quick reference
alias-help git      # Git aliases
alias-help docker   # Docker aliases
alias-help k8s      # Kubernetes aliases
```

Or check the README files in the `home-manager/` directory.
