# Theme Customization

Guide to customizing the visual appearance of your system and applications.

## Terminal Appearance

### Alacritty Theme

```nix
# home-manager/modules/alacritty/default.nix
{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = 0.95;
        padding = {
          x = 10;
          y = 10;
        };
      };
      
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        size = 14.0;
      };
      
      colors = {
        primary = {
          background = "#282828";
          foreground = "#ebdbb2";
        };
        # Gruvbox Dark theme
        normal = {
          black = "#282828";
          red = "#cc241d";
          green = "#98971a";
          yellow = "#d79921";
          blue = "#458588";
          magenta = "#b16286";
          cyan = "#689d6a";
          white = "#a89984";
        };
      };
    };
  };
}
```

### Starship Prompt

```nix
# home-manager/modules/starship.nix
{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      
      git_branch = {
        style = "bold purple";
        symbol = " ";
      };
      
      directory = {
        style = "bold cyan";
        truncation_length = 3;
      };
    };
  };
}
```

## Shell Customization

### ZSH Theme

```nix
# home-manager/modules/zsh.nix
{
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    
    initExtra = ''
      # Shell appearance settings
      export TERM="xterm-256color"
      
      # History appearance
      export HISTSIZE=10000
      export SAVEHIST=10000
      
      # Directory colors
      eval "$(dircolors)"
    '';
  };
}
```

## Application Themes

### LazyGit Theme

```nix
# home-manager/modules/lazygit.nix
{
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          lightTheme = false;
          activeBorderColor = ["green" "bold"];
          inactiveBorderColor = ["white"];
          selectedLineBgColor = ["default"];
        };
      };
    };
  };
}
```

### VS Code Theme

```nix
# home-manager/modules/vscode.nix
{
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      dracula-theme.theme-dracula
    ];
    userSettings = {
      "workbench.colorTheme" = "Dracula";
      "workbench.iconTheme" = "material-icon-theme";
      "editor.fontFamily" = "'JetBrainsMono Nerd Font'";
      "editor.fontSize" = 14;
    };
  };
}
```

## System Appearance

### macOS Theme Settings

```nix
# darwin/configuration.nix
{
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";  # Dark mode
      AppleHighlightColor = "0.847059 0.847059 0.862745";
    };
    
    dock = {
      autohide = true;
      orientation = "bottom";
      tilesize = 48;
    };
    
    finder = {
      AppleShowAllFiles = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };
  };
}
```

## Font Configuration

### System Fonts

```nix
# darwin/configuration.nix
{
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      (nerdfonts.override {
        fonts = [
          "JetBrainsMono"
          "FiraCode"
          "Hack"
        ];
      })
    ];
  };
}
```

## Best Practices

1. **Color Schemes**
   - Use consistent colors across applications
   - Consider light/dark mode compatibility
   - Document color values for reference

2. **Font Management**
   - Use Nerd Fonts for icons support
   - Maintain consistent font sizes
   - Consider font fallbacks

3. **Theme Organization**
   - Group related theme settings
   - Use variables for common values
   - Document theme dependencies
