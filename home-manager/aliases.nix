# home/aliases.nix
#
# Shell alias configuration and helper functions
#
# Purpose:
# - Provides consistent command shortcuts across systems
# - Enhances common tools with better alternatives
# - Streamlines development workflows
#
# Features:
# - Platform-specific aliases (macOS/Linux)
# - Enhanced file operations
# - Development tool shortcuts
# - System maintenance commands
# - FZF-enhanced searching
#
# Categories:
# 1. Core Utilities:
#    - File operations (ls, cp, mv, mkdir)
#    - Modern replacements (bat, eza, fd)
#    - Directory navigation
#
# 2. Development Tools:
#    - Git operations
#    - Docker commands
#    - Terraform management
#    - VS Code shortcuts
#
# 3. System Management:
#    - System monitoring (btop, duf)
#    - Cleanup operations
#    - Update commands
#
# 4. FZF Integrations:
#    - File searching
#    - Git operations
#    - Process management
#    - Docker containers
#
# Integration:
# - Works with ZSH configuration
# - Supports Home Manager paths
# - Platform-aware functionality
#
# Note:
# - Some aliases require external tools
# - Platform-specific features are guarded
# - Uses Home Manager config paths

{ pkgs, config, ... }:

let
  # System Detection
  # Determine operating system for conditional aliases
  isMacOS = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  # Path Configuration
  # Get paths from Home Manager config
  homeDir = config.home.homeDirectory;
  dotfileDir = "${homeDir}/Documents/dotfile";

  # Common aliases for both platforms
  commonAliases = {
    # Editor and IDE
    # Quick VS Code commands
    c = "code .";                    # Open current directory
    ce = "code . && exit";          # Open and close terminal
    cdf = "cd $(ls -d */ | fzf)";   # Fuzzy find directories

    # Shell Management
    # Commands for managing shell state
    reload = "source ${homeDir}/.zshrc && clear";  # Reload shell configuration
    rl = "reload";                                 # Short for reload
    restart = "exec zsh";                          # Start a completely new shell
    re = "restart";                                # Short for restart

    # File Operations
    # Enhanced basic commands
    mkdir = "mkdir -p";             # Create parent directories
    rm = "rm -rf";                  # Recursive force remove
    cp = "cp -r";                   # Recursive copy
    mv = "mv -i";                   # Interactive move

    # Directory Navigation
    # Quick directory access
    dl = "cd ${homeDir}/Downloads";
    docs = "cd ${homeDir}/Documents";

    # Text Editors
    # Default editor aliases
    v = "nano";                     # Quick editor access
    vim = "nano";                   # Remap vim to nano

    # Modern Replacements
    # Enhanced alternatives to standard commands
    # eza (ls replacement)
    ls = "eza -l";                  # List in long format
    lsa = "eza -la";                # List all files including hidden
    lst = "eza -T";                 # Tree view
    lsta = "eza -Ta";               # Tree view with hidden files
    lsr = "eza -R";                 # Recursive list
    lsg = "eza -l --git";           # List with git status
    lsm = "eza -l --sort=modified"; # List sorted by modification date
    lss = "eza -l --sort=size";     # List sorted by size

    # Infrastructure Management
    # Terraform shortcuts and utilities
    tf = "terraform";               # Main command
    tfin = "terraform init";        # Initialize
    tfp = "terraform plan";         # Plan changes
    # Version Management
    tfi = "tfswitch -i";           # Install version
    tfu = "tfswitch -u";           # Use version
    tfl = "tfswitch -l";           # List versions
    # Workspace Management
    tfwst = "terraform workspace select";
    tfwsw = "terraform workspace show";
    tfwls = "terraform workspace list";

    # Container Management
    # Docker shortcuts and utilities
    d = "docker";                  # Quick docker command
    dc = "docker-compose";         # Docker Compose shortcut

    # Network Utilities
    # Quick network information
    ipp = "curl https://ipecho.net/plain; echo";  # Show public IP
    
    # System Monitoring
    # Performance and resource monitoring tools
    # btop - for detailed system analysis
    top = "btop";               # Full system monitor
    htop = "btop";              # Replace htop with btop
    
    # Disk Usage
    # Disk usage aliases (duf)
    df = "duf";                # Better df replacement
    dfa = "duf --all";         # Show all mountpoints including pseudo, duplicate, inaccessible
    dfh = "duf --hide-fs tmpfs,devtmpfs,efivarfs";  # Hide pseudo filesystems
    dfi = "duf --only local,network";  # Show only local and network drives
    
    # Resource Monitoring
    # bottom (btm) - for quick system checks
    bm = "btm --basic";         # Quick, lightweight system view
    bmp = "btm --process_command";      # Process focused view
    bmt = "btm --tree";         # Process tree view
    bmb = "btm --battery";      # Battery focused view (for laptops)
    # Resource Views
    cpu = "btm --basic --cpu_left_legend";   # Quick CPU view with legend
    mem = "btm --basic --memory_legend none";   # Quick memory view with legend
    net = "btm --basic --network_legend none";   # Quick network view with legend
    # System Information
    sys = "neofetch";           # Quick system info
    sysinfo = "neofetch";       # Detailed system info
    fetch = "neofetch";         # Another neofetch alias
    
    # Documentation and Help
    # TLDR aliases for quick reference
    h = "tldr";              # Quick help/cheatsheet
    help = "tldr";           # Alternative to man
    rtfm = "tldr";           # When someone says RTFM
    cheat = "tldr";          # Quick command cheatsheet
    # Documentation Updates
    tldr-update = "tldr --update";  # Update documentation database

    # Modern CLI Replacements
    # Better alternatives to traditional commands
    cat = "bat";                         # Modern cat with syntax highlighting
    find = "fd";                         # Faster and simpler find

    # File Search Utilities
    # Enhanced fd (find) commands
    fdh = "fd -H";                          # Include hidden files (fd hidden)
    fa = "fd -a";                           # Show absolute paths
    ft = "fd -tf --changed-within 1d";      # Files changed today
    # Type-specific searches
    fdir = "fd -td";                        # Only directories
    ff = "fd -tf";                          # Only files
    fsym = "fd -tl";                        # Only symlinks
    # Extension-specific searches
    fpy = "fd -e py";                       # Find Python files
    fjs = "fd -e js";                       # Find JavaScript files
    fnix = "fd -e nix";                     # Find Nix files
    fsh = "fd -e sh";                       # Find shell scripts
    fmd = "fd -e md";                       # Find markdown files
    fconf = "fd -e conf -e config";         # Find config files

    # Smart Navigation
    # Zoxide for intelligent directory jumping
    cd = "z";  # Use zoxide's smart directory jumping

    # Fuzzy Finding Enhancements
    # FZF-powered interactive commands
    # Git
    # Branch Management
    gcb = "git branch --all | grep -v HEAD | fzf --preview 'git log --oneline --graph --date=short --color=always --pretty=\"%C(auto)%cd %h%d %s\" {1}' | sed 's/.* //' | xargs git checkout";
    
    # Git UI
    # LazyGit aliases
    lg = "lazygit";                    # Quick lazygit
    lgc = "lazygit -w $(pwd)";         # LazyGit for current directory
    # Repository Selection
    lgf = "lazygit -f $(find . -type d -name '.git' -exec dirname {} \\; | fzf)";
    
    # Git History Navigation
    # Interactive commit browser with preview
    fshow = "git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr' | fzf --ansi --preview 'echo {} | grep -o \"[a-f0-9]\\{7\\}\" | head -1 | xargs -I % sh -c \"git show --color=always %\"'";
    # Stash Management
    # Interactive stash browser with preview and apply
    fstash = "git stash list | fzf --preview 'echo {} | cut -d: -f1 | xargs -I % sh -c \"git stash show --color=always %\"' | cut -d: -f1 | xargs -I % sh -c 'git stash apply %'";
    
    # File Navigation and Editing
    # FZF-enhanced file operations
    # Find and edit file
    fe = "fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' | xargs -r nano";
    # Find file with preview
    ffp = "fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'";
    # Find and cd into subdirectory
    fcd = "cd $(find . -type d -not -path '*/\.*' | fzf)";
    # Content Search
    # Search within files with preview
    fif = "rg --color=always --line-number --no-heading --smart-case \"\" | fzf --ansi --preview 'bat --color=always --style=numbers {1} --highlight-line {2}'";
    
    # System Process Management
    # Interactive process control
    # Kill process
    fkill = "ps -ef | sed 1d | fzf -m | awk '{print $2}' | xargs kill -9";
    # Memory usage browser
    fmem = "ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -20 | fzf --header-lines=1";
    
    # Command History
    # Interactive history search
    # Search command history with preview
    hist = "history 0 | fzf --ansi --preview 'echo {}' | sed 's/ *[0-9]* *//'";
    
    # Environment Management
    # Environment variable inspection
    # Browse and echo environment variables
    fenv = "env | fzf --preview 'echo {}' | cut -d= -f2";
    
    # Container Operations
    # Interactive Docker container management
    # Select docker container
    dsp = "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | fzf --header-lines=1 | awk '{print $1}' | xargs -r docker stop";
    # Select and remove docker container
    drm = "docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | fzf --header-lines=1 | awk '{print $1}' | xargs -r docker rm";

    # Documentation Preview
    # Terminal-based markdown viewing
    md = "glow";                # Preview markdown in terminal
    readme = "glow README.md";   # Quick readme preview
    changes = "glow CHANGELOG.md"; # View changelog

    # Tmux Session Management
    # Plugin Management
    # TPM (Tmux Plugin Manager) commands
    tpi = "tmux run-shell ${homeDir}/.tmux/plugins/tpm/bindings/install_plugins";    # Install plugins
    tpu = "tmux run-shell ${homeDir}/.tmux/plugins/tpm/bindings/update_plugins";     # Update plugins
    tpU = "tmux run-shell ${homeDir}/.tmux/plugins/tpm/bindings/clean_plugins";      # Uninstall removed plugins

    # Session Control
    # Basic session operations
    tn = "tmux new -s";              # New session with name
    ta = "tmux attach -t";           # Attach to session
    tl = "tmux list-sessions";       # List sessions
    tk = "tmux kill-session -t";     # Kill session

    # Quick Session
    # Default session management
    t = "tmux new-session -A -s main";  # Attach to 'main' or create it
  };

  # macOS specific aliases
  macAliases = if isMacOS then {
    # System Maintenance
    # Comprehensive system cleanup script
    cleanup = ''
      # Start cleanup process
      echo "🧹 Running system cleanup..." && \
      # Nix Garbage Collection
      echo "🗑️  Running Nix garbage collection..." && \
      if nix-collect-garbage -d --option max-jobs 6 --cores 2; then
        echo "✓ Nix garbage collection complete"
      else
        echo "⚠️  Warning: Nix garbage collection failed"
      fi && \
      
      # macOS File Cleanup
      echo "🧹 Cleaning .DS_Store files..." && \
      find ${homeDir} -type f -name '.DS_Store' -delete 2>/dev/null || true && \
      find ${homeDir} -type f -name '._*' -delete 2>/dev/null || true && \
      
      # System Log Cleanup
      echo "📝 Cleaning system logs..." && \
      # ASL Logs
      if [ -d "/private/var/log/asl" ]; then
        sudo rm -rf /private/var/log/asl/*.asl 2>/dev/null || true
      fi && \
      # System Diagnostic Reports
      if [ -d "/Library/Logs/DiagnosticReports" ]; then
        sudo rm -rf /Library/Logs/DiagnosticReports/* 2>/dev/null || true
      fi && \
      # User Diagnostic Reports
      if [ -d "${homeDir}/Library/Logs/DiagnosticReports" ]; then
        sudo rm -rf ${homeDir}/Library/Logs/DiagnosticReports/* 2>/dev/null || true
      fi && \
      
      # Temporary File Cleanup
      echo "🧹 Cleaning temporary files..." && \
      if [ -d "/private/var/tmp" ]; then
        sudo rm -rf /private/var/tmp/* 2>/dev/null || true
      fi && \
      
      # Package Manager Cache
      echo "🧹 Cleaning UV cache..." && \
      if command -v uv &> /dev/null; then
        ${homeDir}/.local/bin/uv cache clean 2>/dev/null || true
      fi && \
      
      # Nix Store Optimization
      echo "🧹 Optimizing Nix store..." && \
      if nix store optimise --option max-jobs 6 --cores 2; then
        echo "✓ Nix store optimization complete"
      else
        echo "⚠️  Warning: Nix store optimization failed"
      fi && \
      
      echo "✨ Cleanup complete!"
    '';
    
    # System Update Commands
    # Flake and system update management
    update = ''
      # Update Nix Flake
      echo "🔄 Updating Nix flake..." && \
      cd ${dotfileDir} && \
      nix --option max-jobs auto flake update && \
      # Rebuild System
      echo "🔄 Rebuilding system..." && \
      darwin-rebuild switch --flake .#ss-mbp --option max-jobs auto && \
      echo "✨ System update complete!"
    '';

    # Quick System Rebuild
    # Rebuild system without updating flake
    rebuild = "cd ${dotfileDir} && darwin-rebuild switch --flake .#ss-mbp --option max-jobs auto && cd -";
    
    # Finder Controls
    # Toggle visibility settings
    show = "defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder";
    hide = "defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder";
    # Desktop Management
    hidedesktop = "defaults write com.apple.finder CreateDesktop -bool false && killall Finder";
    showdesktop = "defaults write com.apple.finder CreateDesktop -bool true && killall Finder";

    # System Controls
    # Quick system actions
    stfu = "osascript -e 'set volume output muted true'";          # Mute audio
    pumpitup = "osascript -e 'set volume output volume 100'";      # Max volume
    afk = "osascript -e 'tell application \"System Events\" to keystroke \"q\" using {command down,control down}'";  # Lock screen

    # Development Shortcuts
    # Quick access to dotfiles
    codedot = "code ${dotfileDir}";     # Open dotfiles in VS Code
    dotfile = "cd ${dotfileDir}";       # Navigate to dotfiles
  } else {};

  # Linux specific aliases
  linuxAliases = if isLinux then {
    # System Update
    # Full system update command
    update = "sudo apt update && sudo apt -y --allow-downgrades full-upgrade && sudo apt -y autoremove && cs update";
    # Development Shortcuts
    dotfile = "cd ${dotfileDir}";       # Navigate to dotfiles
    codedot = "code ${dotfileDir}";     # Open dotfiles in VS Code
  } else {};

in
commonAliases // macAliases // linuxAliases
