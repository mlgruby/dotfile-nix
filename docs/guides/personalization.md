# Personalization Guide

Make your Nix Darwin configuration truly yours with comprehensive customization options.

## 🎨 Theme and Visual Customization

### Stylix System-Wide Theming

Your system uses Stylix for consistent theming across all applications:

```nix
# Current theme: Gruvbox Dark Hard
stylix = {
  enable = true;
  base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  image = config.lib.stylix.pixel "base00";
};
```

**Available Themes**:
- `gruvbox-dark-hard` (current)
- `gruvbox-dark-medium`
- `gruvbox-light-hard`
- `tokyo-night-dark`
- `tokyo-night-light`
- `catppuccin-mocha`
- `nord`
- `solarized-dark`
- `solarized-light`

**To Change Theme**:
1. Edit `darwin/configuration.nix`
2. Update the `base16Scheme` path
3. Run `rebuild`

### Terminal Customization

**Alacritty Configuration**:
```toml
# In home-manager/modules/alacritty/config.toml
[colors.primary]
background = "#1d2021"  # Gruvbox dark background
foreground = "#ebdbb2"  # Gruvbox light foreground

[font]
size = 14.0
normal = { family = "JetBrainsMono Nerd Font", style = "Regular" }
```

**Starship Prompt**:
```toml
# Customize your shell prompt
format = """
$username\
$hostname\
$directory\
$git_branch\
$git_status\
$nodejs\
$python\
$aws\
$line_break\
$character"""
```

## 🗂️ Directory and Path Customization

### Custom Directory Structure

Customize your directory layout in `user-config.nix`:

```nix
directories = {
  dotfiles = "config/dotfiles";     # Instead of Documents/dotfile
  workspace = "projects";           # Instead of Development
  downloads = "Downloads";
  documents = "Documents";
  
  # Add custom directories
  personal = "projects/personal";
  work = "projects/work";
  learning = "projects/learning";
  scripts = "tools/scripts";
};
```

**Benefits**:
- Auto-generated shell aliases (`personal`, `work`, `learning`)
- Consistent navigation commands
- Easy to reorganize your workspace

### Shell Aliases and Functions

**Current Aliases**:
```bash
# Navigation
dotfile    # → ~/Documents/dotfile
ws / dev   # → ~/Development
dl         # → ~/Downloads

# System Management
rebuild    # → sudo darwin-rebuild switch --flake .
update     # → nix flake update && rebuild
cleanup    # → nix-collect-garbage -d

# Development
awsp       # → AWS profile switcher
health-check # → system health monitoring
```

**Adding Custom Aliases**:
```nix
# In home-manager/aliases.nix
programs.zsh.shellAliases = {
  # Your custom aliases
  myproject = "cd ~/Development/my-important-project";
  deploy = "cd ~/Development/my-app && ./deploy.sh";
  logs = "tail -f /var/log/system.log";
};
```

## ⌨️ Keyboard and Input Customization

### Karabiner Elements Configuration

The system includes powerful keyboard customization:

```nix
# Current mappings
programs.karabiner-elements = {
  enable = true;
  profiles = [{
    name = "Default";
    rules = [
      # Caps Lock → Escape/Control
      # Right Command → Control
      # Function keys optimized for development
    ];
  }];
};
```

**Common Customizations**:
- Caps Lock as Escape (Vim users)
- Right Command as Control 
- Function keys for IDE shortcuts
- Media key remapping

### Rectangle Window Management

Customize window snapping and management:

```nix
# Enhanced window management
homebrew.casks = [ "rectangle" ];

# Custom shortcuts in Rectangle preferences:
# Cmd+Option+Arrow keys for window positioning
# Cmd+Option+Enter for maximize
# Cmd+Option+C for center
```

## 🛠️ Development Environment Customization

### Editor Configuration

**Neovim Setup**:
```nix
# In home-manager/neovim.nix
programs.neovim = {
  enable = true;
  defaultEditor = true;
  viAlias = true;
  vimAlias = true;
  
  plugins = with pkgs.vimPlugins; [
    # Your preferred plugins
    gruvbox-nvim
    telescope-nvim
    nvim-treesitter
    # Add more as needed
  ];
};
```

### Git Personalization

```nix
# In home-manager/modules/git.nix
programs.git = {
  userName = userConfig.fullName;
  userEmail = userConfig.email;
  
  # Custom Git aliases
  aliases = {
    st = "status";
    co = "checkout";
    br = "branch";
    cm = "commit -m";
    lg = "log --oneline --graph --decorate";
  };
  
  # Delta for better diffs
  delta = {
    enable = true;
    options = {
      syntax-theme = "gruvbox-dark";
      line-numbers = true;
    };
  };
};
```

## 📱 Application Preferences

### Adding Your Favorite Apps

**GUI Applications via Homebrew**:
```nix
# In darwin/homebrew.nix
homebrew.casks = [
  # Existing apps
  "brave-browser"
  "visual-studio-code"
  "docker-desktop"
  
  # Add your preferences
  "spotify"
  "discord"
  "notion"
  "figma"
  "postman"
];
```

**CLI Tools via Nix**:
```nix
# In home-manager/default.nix
home.packages = with pkgs; [
  # Existing tools
  ripgrep fd bat eza
  
  # Add your preferences
  htop
  tree
  curl
  wget
  jq
  yq
];
```

### macOS System Preferences

Customize macOS defaults declaratively:

```nix
# In darwin/macos-defaults.nix
system.defaults = {
  dock = {
    autohide = true;
    orientation = "left";  # or "bottom", "right"
    tilesize = 48;
    show-recents = false;
  };
  
  finder = {
    AppleShowAllFiles = true;
    ShowPathbar = true;
    ShowStatusBar = true;
    FXDefaultSearchScope = "SCcf"; # Current folder
  };
  
  NSGlobalDomain = {
    KeyRepeat = 2;
    InitialKeyRepeat = 15;
    AppleShowAllExtensions = true;
    AppleInterfaceStyle = "Dark";
  };
};
```

## 🔧 Advanced Customization

### Custom Modules

Create your own Home Manager modules:

```nix
# Create home-manager/modules/my-custom-app.nix
{ config, pkgs, lib, ... }: {
  options.my-custom-app = {
    enable = lib.mkEnableOption "my custom app";
  };
  
  config = lib.mkIf config.my-custom-app.enable {
    home.packages = [ pkgs.my-app ];
    
    home.file.".config/my-app/config.yaml".text = ''
      theme: gruvbox
      font_size: 14
    '';
  };
}
```

### Environment Variables

Set custom environment variables:

```nix
# In home-manager/modules/zsh.nix
programs.zsh.sessionVariables = {
  EDITOR = "nvim";
  BROWSER = "brave";
  TERMINAL = "alacritty";
  
  # Custom variables
  MY_PROJECT_DIR = "$HOME/Development/my-project";
  API_BASE_URL = "https://api.mycompany.com";
};
```

### Fonts and Typography

**Adding Custom Fonts**:
```nix
# In home-manager/modules/fonts.nix
fonts.fontconfig.enable = true;
home.packages = with pkgs; [
  # Nerd Fonts
  (nerdfonts.override { fonts = [ 
    "JetBrainsMono" 
    "FiraCode" 
    "Hack"
    "SourceCodePro"
  ]; })
  
  # Other fonts
  inter
  source-serif
];
```

## 📋 Personalization Checklist

### Essential Customizations

- [ ] **Choose your theme** (Gruvbox, Tokyo Night, Catppuccin, etc.)
- [ ] **Set up custom directories** in `user-config.nix`
- [ ] **Add your favorite GUI apps** to Homebrew casks
- [ ] **Configure Git identity** and signing key
- [ ] **Customize shell aliases** for your workflow
- [ ] **Set up development environment** templates
- [ ] **Configure keyboard shortcuts** in Karabiner
- [ ] **Adjust window management** preferences

### Optional Enhancements

- [ ] **Custom Neovim configuration** with your plugins
- [ ] **Starship prompt customization** 
- [ ] **Terminal color scheme** tweaks
- [ ] **macOS dock and finder** preferences
- [ ] **Custom environment variables**
- [ ] **Font preferences** and sizes
- [ ] **AWS/Cloud tools** configuration
- [ ] **Development-specific aliases**

## 🚀 Quick Customization Examples

### 1. Switch to Tokyo Night Theme

```nix
# darwin/configuration.nix
stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
```

### 2. Add Personal Project Shortcuts

```nix
# user-config.nix
directories = {
  # ... existing directories
  blog = "Development/my-blog";
  portfolio = "Development/portfolio";
  dotfiles = "config/dotfiles";
};
```

### 3. Customize Dock Position

```nix
# darwin/macos-defaults.nix
system.defaults.dock = {
  orientation = "left";
  autohide = true;
  tilesize = 36;
};
```

## 🎯 Next Steps

1. **Start Small**: Pick one area to customize (theme, directories, or aliases)
2. **Test Changes**: Use `rebuild` to apply and test each change
3. **Iterate**: Gradually add more customizations as you identify needs
4. **Document**: Keep notes on what works well for your workflow

**Ready to dive deeper?**
- [Stylix Documentation](../customization/stylix-optimization.md)
- [Directory Configuration](../customization/paths.md)
- [Development Templates](../development/environment-templates.md)
- [System Configuration](../guides/configuration-basics.md)

Remember: Your dotfiles should reflect YOUR workflow. Start with the basics and evolve your configuration over time based on your actual usage patterns. 