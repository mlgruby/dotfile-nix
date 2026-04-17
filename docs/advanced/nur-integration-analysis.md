# NUR Integration Analysis

This document analyzes the potential for integrating NUR (Nix User Repository)
to reduce Homebrew dependencies in our dotfiles configuration.

## Overview

**NUR (Nix User Repository)** is a community-driven repository for Nix packages
that aren't available in the main nixpkgs repository. It allows users to share
packages that are:

- Too niche for nixpkgs
- Proprietary software
- Experimental packages
- Personal customizations

## Current Ownership Analysis

### Packages Analyzed for NUR Migration

Based on the current package ownership model, NUR is only worth considering for
tools that are not already cleanly owned by Home Manager, Homebrew, or
project-local tooling.

#### CLI Tools

| Category | Package | NUR Available | Ownership |
|----------|------------------|---------------|------------------|
| **Core System** | coreutils | ❌ | Homebrew core formula |
| | duf | ❌ | Home Manager package |
| | dust | ❌ | Home Manager package |
| | fd | ❌ | Home Manager package |
| | mas | ❌ | Homebrew macOS integration |
| | zoxide | ❌ | Home Manager `programs.zoxide` |
| **Global Toolchains** | uv | ❌ | Homebrew shared toolchain |
| | python@3.12 | ❌ | Homebrew shared toolchain |
| | go | ❌ | Homebrew shared toolchain |
| | node | ❌ | Homebrew shared toolchain |
| | maven | ❌ | Homebrew shared toolchain |
| **Development** | cmake | ❌ | Homebrew build-chain formula |
| | neovim | ❌ | Homebrew formula |
| | pkg-config | ❌ | Homebrew build-chain formula |
| | git-lfs | ❌ | Home Manager `programs.git.lfs` |
| | shellcheck | ❌ | Home Manager package |
| **Text Processing** | fzf | ❌ | Home Manager `programs.fzf` |
| | yq | ❌ | Home Manager package (`yq-go`) |
| **Terminal Utils** | glow | ❌ | Home Manager package |
| | fastfetch | ✅ | Home Manager package |
| | tldr | ❌ | Home Manager `programs.tealdeer` |
| **Security** | gnupg | ❌ | Homebrew formula |
| | sops | ❌ | Home Manager package |
| | age | ❌ | Home Manager package |
| **Cloud Tools** | awscli | ❌ | Home Manager package (`awscli2`) |
| | terraform-docs | ❌ | Home Manager package |
| | tflint | ❌ | Home Manager package |

#### GUI Applications

| Category | Homebrew Cask | NUR Available | Migration Status |
|----------|---------------|---------------|------------------|
| **Development JDKs** | temurin@11/17 | ❌ | Homebrew cask |
| **Development Tools** | cursor | ❌ | Homebrew cask |
| | docker-desktop | ❌ | Homebrew cask, macOS integration |
| | jetbrains-toolbox | ❌ | Homebrew cask |
| | postman | ❌ | Homebrew cask |
| | visual-studio-code | ❌ | Homebrew cask |
| **Browsers** | brave-browser | ❌ | Homebrew cask |
| | google-chrome | ❌ | Homebrew cask |
| **System Tools** | alacritty | ❌ | Homebrew cask; Home Manager manages config only |
| | karabiner-elements | ❌ | Homebrew cask, macOS integration |
| | rectangle | ❌ | Homebrew cask, macOS integration |
| **Productivity** | bitwarden | ❌ | Homebrew cask |
| | obsidian | ❌ | Homebrew cask |

### NUR Packages Found

After extensive research, very few packages in NUR are relevant for our macOS development setup:

#### Available in NUR (Limited Relevance)

| NUR Package | Repository | Usefulness | Recommendation |
|-------------|------------|------------|----------------|
| android-platform-tools | shamilton | Medium | Consider if Android dev needed |
| kotlin-language-server | zachcoyle | Low | Only if Kotlin development |
| vim plugins | Various | Low | Already handled by Home Manager |

## Migration Assessment

### Why NUR Migration is Limited

1. **macOS Focus**: NUR is primarily Linux-focused
2. **GUI Applications**: NUR rarely packages macOS-native GUI apps
3. **System Integration**: Homebrew provides better macOS system integration
4. **Maintenance**: NUR packages may be less maintained than Homebrew equivalents
5. **Binary Availability**: Homebrew has better binary caching for macOS

### Recommendations

#### Option 1: Minimal NUR Integration (Recommended)

```nix
# flake.nix
inputs = {
  nur.url = "github:nix-community/nur";
  # ... existing inputs
};

# home-manager/default.nix
{
  imports = [
    nur.homeManagerModules.nur
    # ... existing imports
  ];
  
  home.packages = with pkgs; [
    # Only add specific NUR packages if needed for development
    # Example: nur.repos.zachcoyle.kotlin-language-server
  ];
}
```

#### Option 2: No NUR Integration (Also Valid)

- Keep current Homebrew-based approach
- Focus on nixpkgs and Home Manager for CLI tools
- Use Homebrew for GUI applications and macOS-specific tools

## Alternative Strategies

### 1. Maximize nixpkgs Usage

Instead of NUR, focus on using more packages from nixpkgs:

```nix
home.packages = with pkgs; [
  # Many tools are available in nixpkgs
  coreutils      # GNU coreutils
  fd             # find alternative
  fzf            # fuzzy finder
  fastfetch      # system info
  # ... many more
];
```

### 2. Custom Package Overlays

For truly custom needs, create local overlays:

```nix
# overlays/default.nix
final: prev: {
  myCustomTool = prev.callPackage ./my-custom-tool.nix {};
}
```

### 3. Development Environment Focus

Use direnv and development templates instead of global packages:

```nix
# .envrc
use flake .#python-dev
```

## Conclusion

**NUR integration provides minimal value for this macOS-focused dotfiles setup.**

### Key Findings

- **0-2 packages** could realistically be migrated from Homebrew to NUR
- **No significant reduction** in Homebrew dependencies achievable
- **Better alternatives exist**: nixpkgs packages, Home Manager modules,
  development templates

### Recommended Action

1. **Skip NUR integration** for now
2. **Prefer Home Manager/nixpkgs** for user-level CLI tools
3. **Keep Homebrew ownership** for GUI applications, fonts, vendor apps, and
   global toolchains intentionally shared with IDEs
4. **Use development templates** for project-specific tooling
5. **Revisit NUR** only if specific niche packages are needed

### Alternative Improvements

- Keep package ownership guardrails current
- Enhance development environment templates
- Improve Home Manager module usage
- Focus on backup strategy or secrets management next

This analysis shows that NUR integration would not meaningfully reduce
Homebrew dependencies in our current setup, making it a lower-priority
enhancement compared to the current ownership and guardrail work.
