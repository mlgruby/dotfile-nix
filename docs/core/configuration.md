# Configuration Guide

A comprehensive guide to configuring and customizing your Nix Darwin system. This guide will help you understand where to make changes and how to apply them effectively.

## Core Configuration Files

The configuration is split into two main levels: System (darwin) and User (home-manager). Understanding this separation is key to making the right changes in the right place.

### System Level (`darwin/`)

System-level configurations affect the entire macOS system and all users. These settings are managed through the following files:

1. **configuration.nix**

   This file manages core macOS settings, security configurations, and system-wide packages:

   ```nix
   # Core system settings
   {
     # System settings
     system.defaults = {
       dock = {
         autohide = true;
         orientation = "bottom";
       };
       finder = {
         AppleShowAllFiles = true;
         _FXShowPosixPathInTitle = true;
       };
     };

     # Security settings
     security.pam.services.sudo_local.touchIdAuth = true;
   }
   ```

2. **homebrew.nix**

   Manages Homebrew packages and casks. This is where you configure GUI applications and packages that work better through Homebrew:

   ```nix
   # Homebrew package management
   {
     homebrew = {
       enable = true;
       onActivation.autoUpdate = true;
       brews = [ "git" "starship" ];
       casks = [ "alacritty" "brave-browser" ];
     };
   }
   ```

### User Level (`home-manager/`)

User-level configurations are managed by Home Manager and affect only your user environment. These changes don't require administrator privileges:

1. **default.nix**

   This is your main user configuration file. It enables programs and installs user-specific packages:

   ```nix
   # User environment configuration
   {
     # Enable programs
     programs = {
       zsh.enable = true;
       git.enable = true;
       tmux.enable = true;
     };

     # Install packages
     home.packages = with pkgs; [
       ripgrep
       fd
       eza
     ];
   }
   ```

## Common Customizations

Here are the most frequent customizations you might want to make. Each section shows where to make the changes and provides examples.

### Adding New Packages

You have two main options for adding packages, depending on the type of software:

1. **Via Nix**

   Use this for CLI tools and development packages. These are managed by Nix and are more reliable for reproducibility:

   ```nix
   # In home-manager/default.nix
   home.packages = with pkgs; [
     your-package
   ];
   ```

2. **Via Homebrew**

   Prefer this for GUI applications and packages that need frequent updates:

   ```nix
   # In darwin/homebrew.nix
   homebrew.casks = [
     "your-app"
   ];
   ```

### Modifying Shell

ZSH is the default shell. You can customize it by adding initialization commands, aliases, and other settings:

```nix
# In home-manager/modules/zsh.nix
programs.zsh = {
  enable = true;
  initExtra = ''
    # Your custom shell initialization
  '';
  shellAliases = {
    # Your aliases
  };
};
```

### Adding Git Configuration

Git settings are managed through Home Manager. This ensures your Git configuration is consistent across rebuilds:

```nix
# In home-manager/modules/git.nix
programs.git = {
  enable = true;
  extraConfig = {
    core.editor = "vim";
    pull.rebase = true;
  };
};
```

## Applying Changes

After making changes, you'll need to rebuild your system. Here are the common commands you'll use:

```bash
# Rebuild the system
rebuild

# Update and rebuild
update

# Clean old generations
cleanup
```

## Best Practices

Follow these guidelines to maintain a stable and manageable configuration:

1. **Version Control**
   - Keep a backup of `user-config.nix`
   - Commit changes to your fork
   - Use branches for testing

2. **Testing Changes**
   - Make one change at a time
   - Test with `rebuild` before committing
   - Keep track of added packages

3. **Maintenance**
   - Regularly update flake
   - Clean old generations
   - Monitor disk usage
