# Terminal Tools & Utilities

Configuration for terminal environment and utilities.

## Shell Configuration

### ZSH Setup

```nix
# Configuration in home-manager/modules/zsh.nix
programs.zsh = {
  enable = true;
  enableAutosuggestions = true;
  enableSyntaxHighlighting = true;
};
```

## File Operations

### Modern Alternatives

```bash
# Directory Listing (eza)
ls      # List files in long format
lsa     # List all files including hidden
lst     # Tree view
lsg     # List with git status
lss     # List sorted by size

# File Search (fd)
fd      # Find files
fdh     # Find hidden files
fdir    # Find directories

# Content Search (ripgrep)
rg      # Search file contents
rgf     # Search with filename
```

## Terminal Multiplexer (tmux)

### Session Management

```bash
# Session Commands
tn      # New session with name
ta      # Attach to session
tl      # List sessions
tk      # Kill session
t       # Attach to main or create it

# Plugin Management
tpi     # Install plugins
tpu     # Update plugins
tpU     # Uninstall removed plugins
```

## System Monitoring

### Resource Monitoring

```bash
# System Information
top     # System monitor (btop)
df      # Disk usage (duf)
sys     # System information (neofetch)

# Process Management
bm      # Basic monitoring
bmp     # Process view
bmt     # Tree view
```

## Terminal Emulator (Alacritty)

### Configuration

```nix
# Configuration in home-manager/modules/alacritty/default.nix
programs.alacritty = {
  enable = true;
  settings = {
    window.opacity = 0.95;
    font.size = 14;
  };
};
```

## Keyboard Customization (Karabiner)

### Key Mappings

```nix
# Configuration in home-manager/modules/karabiner/default.nix
programs.karabiner = {
  enable = true;
  # Complex modifications
  # Key mappings
};
```
