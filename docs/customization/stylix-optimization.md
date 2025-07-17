# Stylix Target Optimization

This document explains the optimized Stylix target configuration, the reasoning behind each decision, and how to customize theming for your specific needs.

## Overview

Stylix provides system-wide theming using base16 color schemes. Our configuration uses **Gruvbox Dark Hard** as the primary theme with carefully selected targets to ensure consistency while avoiding conflicts with existing custom configurations.

## Current Configuration

### Enabled Targets (✅)

| Target | Status | Reasoning |
|--------|--------|-----------|
| `neovim` | ✅ Enabled | Well-supported by Stylix, integrates perfectly with LazyVim installation |
| `btop` | ✅ Enabled | Native Stylix support, module already designed for theming integration |
| `starship` | ✅ Enabled | Excellent base16 integration, manual Gruvbox palette removed |
| `bat` | ✅ Enabled | Native Stylix support, theme setting removed from module |
| `lazygit` | ✅ Enabled | Good Stylix integration for consistent Git interface theming |
| `tmux` | ✅ Enabled | Native support while preserving custom key bindings and plugins |

### Disabled Targets (❌)

| Target | Status | Reasoning |
|--------|--------|-----------|
| `alacritty` | ❌ Disabled | Complex custom config in `config.toml` with manual Gruvbox theme import, opacity settings, and window management would conflict |
| `vim` | ❌ Disabled | Using Neovim instead of Vim |
| `firefox` | ❌ Disabled | Not our primary browser, prefer manual theming for Homebrew apps |

### Configuration Details

```nix
# home-manager/default.nix
stylix.targets = {
  # Terminal Applications
  alacritty.enable = false;        # Complex custom config conflicts
  
  # Development Tools  
  neovim = {
    enable = true;                 # Well-supported by Stylix
    plugin = "mini.base16";        # Recommended plugin
    transparentBackground = {
      main = false;                # Solid backgrounds for readability
      signColumn = false;
      numberLine = false;
    };
  };
  
  # Core Applications
  btop.enable = true;              # Native Stylix support
  starship.enable = true;          # Base16 integration
  bat.enable = true;               # Native support
  lazygit.enable = true;           # Git interface consistency
  tmux.enable = true;              # Terminal multiplexer theming
  
  # Disabled Applications
  vim.enable = false;              # Using Neovim instead
  firefox.enable = false;          # Not primary browser
};
```

## Integration Strategy

### 1. **Automatic Theming** (Stylix Managed)

Applications with `enable = true` receive automatic color scheme updates:

- **Neovim**: Base16 colors via mini.base16 plugin
- **btop**: System monitor with consistent colors
- **Starship**: Prompt theming via base16 variables
- **bat**: Syntax highlighting theme
- **LazyGit**: Git TUI colors
- **tmux**: Status bar and pane colors

### 2. **Manual Theming** (Custom Managed)

Applications with `enable = false` use manual configurations:

- **Alacritty**: Custom Gruvbox theme import in `config.toml`
- **Bottom**: Colors managed through Home Manager module settings
- **Directory Tools**: broot uses custom Gruvbox configuration

### 3. **Inherited Theming** (Shell Integration)

Tools without direct Stylix targets inherit colors through shell:

- **eza**: Colors through dircolors and shell variables
- **ripgrep**: Output colors via environment variables  
- **jq**: Syntax highlighting through shell integration

## Customization Guide

### Adding New Targets

To enable Stylix for a new application:

1. **Check target availability:**

   ```bash
   # Search Stylix documentation for supported targets
   nix eval --impure --expr 'builtins.attrNames (import <stylix>).targets'
   ```

2. **Add target to configuration:**

   ```nix
   stylix.targets = {
     # existing targets...
     new-app.enable = true;
   };
   ```

3. **Test the integration:**

   ```bash
   sudo darwin-rebuild switch --flake .
   ```

### Disabling Existing Targets

To disable a currently enabled target:

```nix
stylix.targets = {
  target-name.enable = false;  # Disable automatic theming
};
```

Then configure manual theming in the application's module.

### Advanced Neovim Configuration

```nix
stylix.targets.neovim = {
  enable = true;
  plugin = "mini.base16";              # or "base16-nvim"
  transparentBackground = {
    main = true;                       # Enable for transparency
    signColumn = true;                 # Transparent sign column
    numberLine = true;                 # Transparent number line
  };
};
```

## Color Scheme Management

### Current Scheme: Gruvbox Dark Hard

```nix
# darwin/configuration.nix
stylix = {
  enable = true;
  base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  # ... font and image configuration
};
```

### Changing Color Schemes

Available base16 schemes:

```bash
# List all available schemes
ls $(nix-build '<nixpkgs>' -A base16-schemes)/share/themes/
```

Popular alternatives:

- `gruvbox-dark-medium.yaml`
- `gruvbox-light-medium.yaml`
- `nord.yaml`
- `dracula.yaml`
- `tokyo-night-dark.yaml`
- `catppuccin-mocha.yaml`

To change the scheme:

```nix
stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
```

## Troubleshooting

### Common Issues

1. **Application not picking up colors**
   - Check if target is enabled in `stylix.targets`
   - Verify application has native Stylix support
   - Restart application after rebuild

2. **Conflicts with existing themes**
   - Disable Stylix target: `app.enable = false`
   - Use manual theming in application module
   - Remove conflicting color configurations

3. **Starship colors not working**
   - Ensure manual color palette is removed
   - Check that `starship.enable = true` in targets
   - Verify base16 color variables are available

### Validation Commands

```bash
# Check Stylix configuration
nix eval .#darwinConfigurations.$(hostname).config.stylix.targets

# Test color variables
echo $BASE16_COLOR_00_HEX  # Should show base color

# Verify application configs
bat --list-themes | grep base16
lazygit --version
```

## Performance Considerations

### Optimized Settings

1. **Neovim Plugin Choice**
   - `mini.base16`: Lightweight, fast startup
   - `base16-nvim`: More features, slightly slower

2. **Selective Target Enabling**
   - Only enable targets for applications you actively use
   - Disable targets for applications with complex custom configs

3. **Transparent Backgrounds**
   - Keep disabled for better readability
   - Enable only if you prefer the aesthetic

## Future Enhancements

### Potential Additions

Applications that could benefit from Stylix integration:

- **VSCode**: If moved from Homebrew to Nix
- **Firefox**: If adopted as primary browser
- **Discord**: If using Nix-managed version

### Conditional Theming

Future enhancement for environment-specific theming:

```nix
stylix.targets = {
  neovim.enable = true;
  
  # Conditional based on environment
  alacritty.enable = userConfig.preferences.terminal.stylix or false;
};
```

## Best Practices

1. **Test Incrementally**
   - Enable one target at a time
   - Verify integration before adding more

2. **Document Reasoning**
   - Comment why targets are enabled/disabled
   - Note conflicts or special considerations

3. **Backup Configurations**
   - Keep manual theme configs as fallback
   - Document migration from manual to Stylix

4. **Monitor Updates**
   - Stylix targets may change between versions
   - Review and update configuration regularly

This optimized approach provides consistent theming while preserving the flexibility and customization that makes our development environment unique.
