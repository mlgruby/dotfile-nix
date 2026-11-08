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
sys     # System information (fastfetch)

# Homelab recovery
lwdec backup.zip       # Decrypt Lazywarden backup
lw-restore backup.zip  # Decrypt to ~/Secure/lazywarden-restore

# Process Management
bm      # Basic monitoring
bmp     # Process view
bmt     # Tree view
```

## Terminal Emulators (Ghostty & Alacritty)

### Ghostty (Primary Terminal)

Ghostty (`home-manager/modules/ghostty.nix`) is the primary terminal emulator, configured with Gruvbox Dark Hard colors, background blur, and automatic attachment to the `main` Tmux + Herdr session (`home-manager/modules/herdr.nix`).

### Project Workspace Launcher (`p`)

Run `p` in any interactive Zsh session to fuzzy-select a repository under `~/Development` and create/switch to a profile-aware Tmux window layout:

- **Work profile (`satya-wmbp`)**: 3 tabs — `dev` (`$EDITOR` + shell split), `cc` (`claude --continue || claude`), and `git` (`lazygit` + open GitHub PR list).
- **Personal profile (`satya-pmbp`)**: 4 tabs — `dev` (`$EDITOR` + shell split), `agy` (`agy .`), `cxr` (`codex resume`), and `lg` (`lazygit`).

### Alacritty (Secondary Terminal)

```nix
# Configuration in home-manager/modules/alacritty/default.nix
programs.alacritty = {
  enable = true;
  settings = {
    window.opacity = 0.85;
    font.size = 12.0;
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
