# Impermanence Module Evaluation

This document evaluates the integration of the nix-community/impermanence
module for declarative persistence management in the dotfiles configuration.

## Overview

**Impermanence** is a NixOS/home-manager module that allows you to:

- Choose exactly what files/directories persist between reboots
- Keep your system clean by default (everything else gets wiped)
- Force declarative management of persistent state
- Enable experimentation without permanent system clutter

## Current System Analysis

### Existing Persistence Strategy

Our current dotfiles configuration uses **traditional persistent storage**:

- All user data persists by default in `~/`
- System state accumulates in `/var/`, `/etc/`, etc.
- Manual cleanup required via `cleanup` aliases
- No forced declaration of what should persist

### Current Cleanup Mechanisms

```bash
# Existing cleanup aliases
cleanup    # Nix garbage collection + system cleanup
health-maintain  # Automated maintenance tasks
```

## Impermanence Benefits for This Setup

### 1. Declarative Persistence Management

```nix
# Instead of manual cleanup, declare what persists
home.persistence."/persistent/home/${username}" = {
  directories = [
    "Documents"
    "Downloads" 
    ".ssh"
    ".aws"
    ".config/git"
  ];
  files = [
    ".zsh_history"
    ".gitconfig"
  ];
};
```

### 2. System Cleanliness

- Forces explicit decision about what to keep
- Prevents configuration drift and cruft accumulation
- Makes system state predictable and reproducible

### 3. Enhanced Security

- Sensitive files must be explicitly declared
- Temporary files automatically cleaned up
- Reduces attack surface (no persistent logs, caches, etc.)

### 4. Experimentation Safety

- Try new software without permanent impact
- System returns to known-good state on reboot
- Perfect for development environment testing

## Implementation Options

### Option 1: Full Impermanence (Recommended for Advanced Users)

#### Root on tmpfs + Persistent volumes

```nix
fileSystems."/" = {
  device = "none";
  fsType = "tmpfs";
  options = [ "defaults" "size=25%" "mode=755" ];
};

fileSystems."/persistent" = {
  device = "/dev/disk/by-uuid/...";
  neededForBoot = true;
  fsType = "apfs";  # or btrfs
};

fileSystems."/nix" = {
  device = "/persistent/nix";
  options = [ "bind" ];
};
```

**Pros:**

- Maximum cleanliness and security
- Forces complete declarative state management
- Excellent for development workstations

**Cons:**

- Requires careful planning of persistent state
- Risk of data loss if not properly configured
- More complex filesystem setup
- Large downloads/builds can exhaust tmpfs memory

### Option 2: Selective Impermanence (Recommended for This Setup)

#### Traditional root + Impermanence for user data

```nix
# Keep existing filesystem structure
# Add impermanence only for home-manager

home.persistence."/Users/${username}/persistent" = {
  directories = [
    "Documents/dotfile"     # This repository
    "Development"           # Workspace
    "Downloads"            # Downloads
    ".ssh"                 # SSH keys
    ".aws"                 # AWS credentials  
    ".config/git"          # Git config
    ".local/share/zsh"     # ZSH data
  ];
  files = [
    ".zsh_history"
    ".bash_history"
  ];
};
```

**Pros:**

- Easier to implement incrementally
- Lower risk of system breakage
- Still provides cleanliness benefits
- Compatible with current setup

**Cons:**

- System-level cruft still accumulates
- Less dramatic cleanliness improvement

### Option 3: Hybrid Approach (Conservative)

#### Selective directories with gradual expansion

Start with non-critical directories:

```nix
home.persistence."/Users/${username}/persistent" = {
  directories = [
    # Start with clearly owned application data
    ".config/gh"           # GitHub CLI
    ".config/lazygit"      # Lazygit
    ".local/share/nvim"    # Neovim data
  ];
  # Keep existing home structure for now
};
```

## macOS-Specific Considerations

### Filesystem Compatibility

- **APFS**: Native macOS filesystem, good for bind mounts
- **BTRFS**: Not natively supported on macOS
- **tmpfs**: Available but limited on macOS

### System Integration

- macOS System Integrity Protection (SIP) restrictions
- Application support expectations (many assume persistent ~/Library)
- TimeMachine backup integration considerations

### Performance Impact

- APFS snapshots could provide similar benefits
- tmpfs memory usage on systems with limited RAM
- Network filesystems performance for /nix

## Recommended Implementation Plan

### Phase 1: Evaluation Setup (Low Risk)

```nix
# Add impermanence module without changing filesystem
inputs.impermanence.url = "github:nix-community/impermanence";

# Test with non-critical directories
home.persistence."/Users/${username}/.local/impermanence-test" = {
  directories = [
    ".config/test-app"
  ];
  allowOther = true;
};
```

### Phase 2: Home Manager Integration (Medium Risk)

```nix
home.persistence."/Users/${username}/persistent" = {
  directories = [
    # Development
    "Documents/dotfile"
    "Development"
    
    # Configuration  
    ".ssh"
    ".aws"
    ".config/git"
    ".config/gh"
    ".config/lazygit"
    
    # Application data
    ".local/share/nvim"
    ".local/share/zsh"
    ".local/share/direnv"
  ];
  
  files = [
    ".zsh_history" 
    ".bash_history"
    ".gitconfig"
  ];
};
```

### Phase 3: System-Level (High Risk - Optional)

Only if Phase 2 works well and user wants maximum cleanliness:

```nix
# Requires careful filesystem restructuring
fileSystems."/" = {
  device = "none";
  fsType = "tmpfs";
  options = [ "defaults" "size=8G" "mode=755" ];
};
```

## Integration with Existing Features

### Compatibility with Current Tools

**✅ Compatible:**

- System health monitoring (can monitor persistence usage)
- Performance optimization (complements garbage collection)
- Development templates (enhanced by clean environment)
- Backup strategy (defines what needs backing up)

**⚠️ Requires Updates:**

- Directory aliases (need to point to persistent locations)
- Cleanup scripts (less needed but can manage tmpfs)
- Documentation (explain persistence model)

### Enhanced Monitoring

```bash
# Add persistence monitoring to health checks
check_persistence_usage() {
  du -sh "$HOME/persistent" 2>/dev/null || echo "Persistence not active"
  df -h / | grep -E "(tmpfs|overlay)"
}
```

## Decision Matrix

| Aspect | Traditional | Selective Impermanence | Full Impermanence |
|--------|-------------|------------------------|-------------------|
| **Setup Complexity** | Low | Medium | High |
| **Risk Level** | Low | Medium | High |
| **Cleanliness Benefit** | Low | Medium | High |
| **Learning Curve** | None | Medium | High |
| **Maintenance Overhead** | Low | Medium | Medium |
| **macOS Compatibility** | High | High | Medium |

## Recommendation

## Recommendation: Option 2 Selective Impermanence

For this dotfiles setup, I recommend **Option 2: Selective Impermanence**

### Rationale

1. **Risk Management**: Preserves current working system while adding benefits
2. **Incremental Adoption**: Can be implemented gradually and safely
3. **macOS Compatibility**: Works well with macOS filesystem expectations
4. **Maintenance Balance**: Provides cleanliness benefits without excessive complexity

### Implementation Timeline

1. **Week 1**: Add impermanence module and test with non-critical directories
2. **Week 2**: Migrate development workspace and configuration directories
3. **Week 3**: Add application data directories
4. **Week 4**: Evaluate results and decide on system-level implementation

## Getting Started

### 1. Add Impermanence Input

```nix
# flake.nix
inputs = {
  impermanence.url = "github:nix-community/impermanence";
  # ... existing inputs
};
```

### 2. Import Module

```nix
# home-manager/default.nix
imports = [
  inputs.impermanence.homeManagerModules.impermanence
  # ... existing imports
];
```

### 3. Start Small

```nix
# Test configuration
home.persistence."/Users/${username}/persistent-test" = {
  directories = [ ".config/test" ];
  files = [ ".test-file" ];
};
```

## Conclusion

The Impermanence module would provide significant benefits for system
cleanliness and declarative state management. For this mature dotfiles setup,
a gradual implementation focusing on home-manager integration offers the best
balance of benefits and risk management.

The module aligns well with the existing philosophy of declarative
configuration and would complement the current monitoring and maintenance
features effectively.
