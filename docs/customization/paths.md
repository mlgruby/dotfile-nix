# Dynamic Path Configuration

This document explains how to customize directory paths in your dotfile configuration to match your personal preferences and workflow.

## Overview

The dotfile system now supports dynamic path configuration through the `user-config.nix` file, eliminating hardcoded paths and making the configuration portable and customizable.

## Configuration Structure

### user-config.nix

```nix
{
  # Personal Information
  username = "your-username";
  fullName = "Your Full Name";
  email = "your.email@example.com";
  githubUsername = "your-github-username";
  hostname = "your-hostname";
  signingKey = "";
  
  # Directory Configuration
  directories = {
    # Dotfiles repository location (relative to home directory)
    dotfiles = "Documents/dotfile";
    
    # Development workspace (where you keep your projects)
    workspace = "Development";
    
    # Additional directories for shortcuts
    downloads = "Downloads";
    documents = "Documents";
  };
}
```

## Configurable Directories

### Core Directories

| Directory | Default | Purpose | Alias Generated |
|-----------|---------|---------|-----------------|
| `dotfiles` | `Documents/dotfile` | Location of this dotfile repository | `dotfile` |
| `workspace` | `Development` | Main development workspace | `ws`, `dev` |
| `downloads` | `Downloads` | Downloads folder | `dl` |
| `documents` | `Documents` | Documents folder | `docs` |

### Custom Directories

You can add custom directories to the configuration:

```nix
directories = {
  # Core directories (required)
  dotfiles = "Documents/dotfile";
  workspace = "Development";
  downloads = "Downloads";
  documents = "Documents";
  
  # Custom directories (optional)
  personal = "Development/Personal";
  work = "Development/Work";
  opensource = "Development/OpenSource";
  scripts = "Scripts";
};
```

Custom directories will automatically generate shell aliases using their names (e.g., `personal`, `work`, `opensource`, `scripts`).

## Generated Aliases

The system automatically generates navigation aliases for all configured directories:

```bash
# Core aliases
dotfile  # cd ~/Documents/dotfile
ws       # cd ~/Development
dev      # cd ~/Development (alternative)
dl       # cd ~/Downloads
docs     # cd ~/Documents

# Custom aliases (if configured)
personal    # cd ~/Development/Personal
work        # cd ~/Development/Work
opensource  # cd ~/Development/OpenSource
scripts     # cd ~/Scripts
```

## Template System Integration

The path configuration integrates with the template system used for complex commands:

- System management commands (`rebuild`, `update`, `cleanup`) automatically use the correct dotfile directory
- All template variables are dynamically substituted at build time
- No hardcoded paths remain in the generated configuration

## Path Validation

The system includes comprehensive path validation:

- **Character validation**: Prevents dangerous characters (`;`, `&`, `|`, `$`, backticks, quotes)
- **Format validation**: Ensures paths are safe for shell usage
- **Existence checking**: Validates required configuration attributes

## Migration Guide

### From Hardcoded Paths

If you're upgrading from a version with hardcoded paths:

1. **Update user-config.nix** with the new directory structure
2. **Customize paths** to match your current setup
3. **Rebuild system** to apply changes
4. **Test aliases** to ensure they point to correct locations

### Customization Examples

#### Developer with Different Structure

```nix
directories = {
  dotfiles = "dotfiles";  # Root-level dotfiles
  workspace = "code";     # ~/code instead of ~/Development
  downloads = "Downloads";
  documents = "docs";     # ~/docs instead of ~/Documents
};
```

#### Project-Specific Organization

```nix
directories = {
  dotfiles = "config/dotfiles";
  workspace = "projects";
  downloads = "Downloads";
  documents = "Documents";
  
  # Project-specific directories
  web = "projects/web";
  mobile = "projects/mobile";
  data = "projects/data-science";
  learning = "projects/learning";
};
```

## Troubleshooting

### Common Issues

1. **Build Fails with Path Validation Error**
   - Check for invalid characters in directory paths
   - Ensure all required directories are specified

2. **Aliases Point to Wrong Locations**
   - Verify directory paths in `user-config.nix`
   - Rebuild system after making changes

3. **Custom Directories Not Creating Aliases**
   - Ensure directory names are valid Nix attribute names
   - Check for naming conflicts with existing aliases

### Validation Commands

```bash
# Check current alias mappings
alias | grep "^(dotfile|ws|dl|docs)="

# Verify directory paths
echo $HOME/$(nix eval --raw .#userConfig.directories.dotfiles)

# Test navigation
dotfile && pwd  # Should show your dotfile directory
ws && pwd       # Should show your workspace directory
```

## Advanced Usage

### Conditional Directory Creation

The system can be extended to automatically create directories:

```nix
# This would be a future enhancement
directories = {
  workspace = "Development";
  createIfMissing = true;  # Auto-create directories
};
```

### Environment-Specific Paths

Different paths for different environments:

```nix
directories = {
  dotfiles = if builtins.getEnv "USER" == "work-user" 
             then "work/dotfiles" 
             else "personal/dotfiles";
  workspace = if isWorkEnvironment then "work" else "personal";
};
```

## Benefits

1. **Portability**: Easy to move configuration between machines
2. **Customization**: Adapt to personal directory preferences
3. **Maintainability**: No hardcoded paths to update
4. **Safety**: Built-in path validation prevents dangerous configurations
5. **Automation**: Automatic alias generation reduces manual configuration
6. **Consistency**: All path management centralized in one location
