# home-manager/modules/utility-packages.nix
#
# Utility Packages Collection
#
# Purpose:
# - Installs essential CLI tools and utilities via Nix
# - Provides tools that don't have Home Manager program modules
# - Complements Homebrew-installed tools with Nix alternatives
#
# Package Categories:
# - Development Tools: HTTP clients, code analysis, benchmarking
# - Text Processing: Document conversion, JSON/YAML tools
# - Network Tools: Network scanning, utilities
# - Archive Tools: Compression and extraction utilities
# - System Tools: Process monitoring, file utilities
# - Modern Replacements: Enhanced versions of classic tools
#
# Philosophy:
# - Install via Nix when not available via Homebrew
# - Prefer tools with programs.* modules (configured elsewhere)
# - Avoid duplicating Homebrew-installed packages
#
# Integration:
# - Works with shell aliases (aliases.nix)
# - Compatible with development workflow
# - Supports both Nix and Homebrew ecosystems

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Development Tools
    # HTTP and API development
    httpie                    # Modern HTTP client (alternative to curl)

    # Language Servers (for Claude Code LSP plugins)
    kotlin-language-server    # Kotlin LSP for code intelligence
    rust-analyzer             # Rust LSP for code intelligence

    # Rust Development
    rustc                     # Rust compiler
    cargo                     # Rust package manager and build tool
    rustfmt                   # Rust code formatter
    clippy                    # Rust linter
    
    # Text Processing and Documentation
    pandoc                    # Universal document converter
    
    # Network Tools
    nmap                      # Network scanner and security tool
    netcat                    # Network utility for reading/writing network connections
    
    # Archive and Compression Tools
    unzip                     # ZIP file extraction
    p7zip                     # 7-Zip compression tool
    
    # JSON and YAML Processing
    fx                        # Interactive JSON viewer and processor
    yj                        # Convert YAML to JSON and vice versa
    
    # Git Enhancement Tools
    git-extras                # Additional Git commands and utilities
    
    # Modern CLI Replacements
    procs                     # Modern replacement for ps (process viewer)
    
    # System Monitoring and Utilities
    watch                     # Execute commands periodically
    parallel                  # Execute commands in parallel
    rsync                     # File synchronization and transfer
    
    # Development and Analysis Tools
    tokei                     # Code statistics and line counting
    hyperfine                 # Command-line benchmarking tool
    choose                    # Human-friendly cut/awk alternative
    sd                        # Modern sed alternative (find and replace)
    grex                      # Generate regular expressions from examples
    
    # System Information and Utilities
    lsof                      # List open files and processes
    file                      # File type identification
    tree                      # Directory structure visualization (fallback)
    
    # Enhanced Text Processing
    ripgrep-all               # Extended ripgrep with more file type support
    
    # Terminal and Session Management
    screen                    # Terminal multiplexer (fallback to tmux)
    
    # Note: The following packages are intentionally excluded:
    # - Tools with Home Manager programs.* modules (git, gh, lazygit, tmux, etc.)
    # - Tools installed via Homebrew (neofetch, tldr, glow, fd, duf, etc.)
    # - Platform-specific tools that may not work on macOS
    # - Tools that require complex setup or migration (taskwarrior, etc.)
  ];
}
