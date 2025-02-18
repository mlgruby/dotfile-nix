# Module Management

Guide to understanding, customizing, and creating modules in your Nix Darwin configuration.

## Understanding Modules

### Module Structure

```nix
# Basic module structure
{ config, pkgs, lib, ... }: {
  # Options declaration
  options = {
    # Module-specific options
  };

  # Configuration
  config = {
    # Module implementation
  };
}
```

### Module Types

1. **System Modules** (`darwin/`)

   ```nix
   # System-level configuration
   { config, pkgs, ... }: {
     system.defaults = {
       dock = {
         autohide = true;
       };
     };
   }
   ```

2. **Home Manager Modules** (`home-manager/modules/`)

   ```nix
   # User-level configuration
   { config, pkgs, ... }: {
     programs.alacritty = {
       enable = true;
       settings = {
         # Configuration
       };
     };
   }
   ```

## Customizing Existing Modules

### Basic Customization

1. **Enable/Disable Features**

   ```nix
   { config, pkgs, ... }: {
     programs.git = {
       enable = true;           # Enable the module
       enableAliases = false;   # Disable built-in aliases
     };
   }
   ```

2. **Modify Settings**

   ```nix
   programs.alacritty = {
     settings = {
       window.opacity = 0.95;
       font.size = 14;
     };
   };
   ```

### Advanced Customization

1. **Conditional Configuration**

   ```nix
   { config, pkgs, lib, ... }: {
     config = lib.mkIf pkgs.stdenv.isDarwin {
       # Darwin-specific settings
     };
   }
   ```

2. **Override Defaults**

   ```nix
   { config, pkgs, lib, ... }: {
     programs.tmux = {
       shortcut = lib.mkForce "C-a";  # Override default
     };
   }
   ```

## Creating New Modules

### Basic Module

```nix
# home-manager/modules/custom.nix
{ config, pkgs, lib, ... }:

let
  cfg = config.programs.custom;
in {
  options.programs.custom = {
    enable = lib.mkEnableOption "custom program";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.custom;
      description = "Custom package to use.";
    };
    
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Custom settings.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    
    xdg.configFile."custom/config.json".text = 
      builtins.toJSON cfg.settings;
  };
}
```

### Module with Dependencies

```nix
{ config, pkgs, lib, ... }:

{
  imports = [
    # Other required modules
  ];

  options = {
    # Module options
  };

  config = {
    # Ensure dependencies
    home.packages = with pkgs; [
      dependency1
      dependency2
    ];

    # Configure dependencies
    programs.dependency1 = {
      enable = true;
      # Settings
    };
  };
}
```

## Best Practices

1. **Module Organization**
   - Keep related functionality together
   - Use clear, descriptive names
   - Document module purpose and options

2. **Configuration Management**
   - Use `mkIf` for conditional settings
   - Provide sensible defaults
   - Document required dependencies

3. **Testing**
   - Test modules in isolation
   - Verify dependencies
   - Check for conflicts

## Common Patterns

### File Management

```nix
{ config, pkgs, ... }: {
  # Copy files
  home.file.".config/custom".source = ./files/custom;

  # Generate files
  xdg.configFile."custom/settings.json".text = 
    builtins.toJSON config.custom.settings;
}
```

### Program Configuration

```nix
{ config, pkgs, ... }: {
  programs.custom = {
    enable = true;
    package = pkgs.custom;
    configFile = pkgs.writeText "config" ''
      # Configuration content
    '';
  };
}
```
