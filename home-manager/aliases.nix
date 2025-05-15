# home/aliases.nix
#
# Shell Aliases and Functions
#
# Purpose:
# - Standardizes command-line workflows
# - Enhances system interaction
# - Automates common tasks
#
# Command Categories:
# 1. System Operations:
#    - System maintenance
#    - Package management
#    - Service control
#    - Configuration reload
#
# 2. File Management:
#    - Enhanced navigation
#    - Bulk operations
#    - Search and filtering
#    - Archive handling
#
# 3. Development:
#    - Version control
#    - Container management
#    - Infrastructure as code
#    - IDE integration
#
# 4. Cloud & DevOps:
#    - Cloud platform tools
#    - Deployment helpers
#    - Credential management
#    - Environment switching
#
# 5. Productivity:
#    - Quick shortcuts
#    - Fuzzy finding
#    - Batch processing
#    - Task automation
#
# Integration:
# - Platform detection (macOS/Linux)
# - Environment awareness
# - Dynamic path handling
# - Command availability checks
#
# Note:
# - Some features need external tools
# - OS-specific features are guarded
# - Paths are managed by Home Manager
# - Commands check for dependencies

{ pkgs, config, ... }@args: let
  inherit (args.userConfig) username hostname;
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
    # Core System Commands
    # System state management
    rollback = ''
      generation=$(darwin-rebuild list-generations | 
        fzf --header "Select a generation to roll back to" \
            --preview "echo {} | grep -o '[0-9]\\+' | xargs -I % sh -c 'nix-store -q --references /nix/var/nix/profiles/system-%'" \
            --preview-window "right:60%" \
            --layout=reverse) &&
      if [ -n "$generation" ]; then
        generation_number=$(echo $generation | grep -o '[0-9]\+' | head -1) &&
        echo "Rolling back to generation $generation_number..." &&
        darwin-rebuild switch --switch-generation $generation_number
      fi
    '';

    # Shell Management
    reload = "source ${homeDir}/.zshrc && clear";  # Reload shell configuration
    rl = "reload";                                 # Short for reload
    restart = "exec zsh";                          # Start a completely new shell
    re = "restart";                                # Short for restart

    # Navigation and File Management
    dotfile = "cd ${dotfileDir}";                 # Navigate to dotfiles
    dl = "cd ${homeDir}/Downloads";               # Quick downloads access
    docs = "cd ${homeDir}/Documents";             # Quick documents access
    cdf = "cd $(ls -d */ | fzf)";                 # Fuzzy find directories

    # Modern CLI Tools
    cat = "bat";                                  # Better cat
    ls = "eza -l";                                # Better ls
    find = "fd";                                  # Better find
    top = "btop";                                 # Better top

    # Editor and IDE
    # Quick VS Code commands
    c = "code .";                    # Open current directory
    ce = "code . && exit";           # Open and close terminal

    # File Operations
    # Enhanced basic commands
    mkdir = "mkdir -p";             # Create parent directories
    rm = "rm -rf";                  # Recursive force remove
    cp = "cp -r";                   # Recursive copy
    mv = "mv -i";                   # Interactive move

    # Text Editors
    # Default editor aliases
    v = "nvim";                     # Quick editor access
    vim = "nvim";                   # Remap vim to nvim

    # Modern Replacements
    # Enhanced alternatives to standard commands
    # eza (ls replacement)
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
    tfi = "tfswitch -i";            # Install version
    tfu = "tfswitch -u";            # Use version
    tfl = "tfswitch -l";            # List versions
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

    # Development Shortcuts
    # Quick access to dotfiles
    codedot = ''
      if command -v cursor &> /dev/null; then
        cursor "${dotfileDir}"    # Open in Cursor if available
      else
        code "${dotfileDir}"      # Fall back to VS Code
      fi
    '';   # Smart editor selection for dotfiles
  };

  # macOS specific aliases
  macAliases = if isMacOS then {
    # System Update Commands
    # Quick System Rebuild
    # Rebuild system without updating flake
    rebuild = "cd ${dotfileDir} && darwin-rebuild switch --flake .#\"$(hostname)\" --option max-jobs auto && cd -";

    # Flake and system update management
    update = ''
      # Update Nix Flake
      echo "🔄 Updating Nix flake..." && \
      cd ${dotfileDir} && \
      nix --option max-jobs auto flake update && \
      echo "🔄 Rebuilding system..." && rebuild && \
      echo "✨ System update complete!"
    '';
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
      
      # Node.js Cleanup
      echo "🧹 Cleaning npm cache..." && \
      if command -v npm &> /dev/null; then
        npm cache clean --force 2>/dev/null || true
        echo "✓ npm cache cleaned"
      fi && \
      
      # Clear global npm packages that aren't needed
      echo "🧹 Cleaning unused global npm packages..." && \
      if command -v npm &> /dev/null; then
        unused_packages=$(npm list -g --depth=0 2>/dev/null | grep -v "npm@" | awk -F@ '/^[^ ]/ {print $1}' | tr -d ' ') && \
        if [ -n "$unused_packages" ]; then
          npm uninstall -g $unused_packages 2>/dev/null
          echo "✓ Unused global npm packages removed"
        else
          echo "No unused global npm packages found"
        fi
      fi && \
      
      # Homebrew Cleanup
      echo "🧹 Cleaning Homebrew cache and old versions..." && \
      if command -v brew &> /dev/null; then
        brew cleanup 2>/dev/null || true
        echo "✓ Homebrew cleanup complete"
      fi && \
      
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
    codedot = ''
      if command -v cursor &> /dev/null; then
        cursor "${dotfileDir}"    # Open in Cursor if available
      else
        code "${dotfileDir}"      # Fall back to VS Code
      fi
    '';   # Smart editor selection for dotfiles
  } else {};

  # Linux specific aliases
  linuxAliases = if isLinux then {
    # System Update
    # Full system update command
    update = "sudo apt update && sudo apt -y --allow-downgrades full-upgrade && sudo apt -y autoremove && cs update";
    # Development Shortcuts
    dotfile = "cd ${dotfileDir}";       # Navigate to dotfiles
    codedot = ''
      if command -v code &> /dev/null; then
        code "${dotfileDir}"      # Use VS Code on Linux
      else
        nano "${dotfileDir}"      # Fall back to nano
      fi
    '';   # Smart editor selection for dotfiles
  } else {};

  # Git Aliases (Moved from git.nix)
  gitAliases = {
    # Basic Operations
    gp = "git push";                     # Push to remote
    gl = "git pull";                     # Pull from remote
    gs = "git status";                   # Check status
    gd = "git diff";                     # View changes

    # Advanced Operations
    gpush = "git add . && git commit -m";            # Stage and commit
    gpushf = "git add . && git commit --amend --no-edit && git push -f";  # Amend and force push
    gpushnew = "git push -u origin HEAD";            # Push new branch

    # Remote Management
    gare = "git remote add upstream";               # Add upstream
    gre = "git remote -v";                          # List remotes
    gcan = "git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit -v -a --no-edit --amend";  # Amend changes
    gfa = "git fetch --all";                        # Fetch all remotes
    gfap = "git fetch --all --prune";               # Fetch and clean
    gfu = "git fetch upstream";                     # Fetch upstream
    gud = "git fetch upstream develop && git push origin refs/remotes/upstream/develop:refs/heads/develop"; # Update develop from upstream and push to origin without checkout
    gum = "git fetch upstream main && git push origin refs/remotes/upstream/main:refs/heads/main";       # Update main from upstream and push to origin without checkout
    grbd = "git rebase develop";                    # Rebase current branch onto develop
    grbud = "git fetch upstream develop && git push origin refs/remotes/upstream/develop:refs/heads/develop && git rebase develop"; # Fetch upstream develop, update local and origin develop, then rebase current branch

    # Alias for LazyGit
    lg = "lazygit"; # Preferred alias for lazygit
  };

  # GitHub Aliases (Moved from github.nix)
  githubAliases = {
    # Pull Request Workflow
    ghprcr = "gh pr create --web";      # Create PR in web browser
    ghprv = "ghopr";                    # Interactive select and view PR in browser
    ghprl = "ghprall";                  # List all PRs with fzf
    ghpro = "ghpropen";                 # List open PRs with fzf
    ghprc = "ghprco";                   # Interactive checkout PR using the function
    ghprch = "ghprcheck";               # Check PR status
    
    # Repository Operations
    ghrv = "gh repo view --web";        # View repo in browser
    ghrc = "gh repo clone";             # Clone repo
    ghrf = "gh repo fork";              # Fork repo
    
    # Issue Tracking
    ghil = "gh issue list";             # List issues
    ghic = "gh issue create --web";     # Create issue in browser
    ghiv = "gh issue view --web";       # View issue in browser
    
    # CI/CD Monitoring
    ghrl = "gh run list";               # List workflow runs
    ghrw = "gh run watch";              # Watch workflow run
    
    # Search Operations
    ghrs = "gh repo search";            # Search repositories
    ghis = "gh issue search";           # Search issues
    ghps = "gh pr search";              # Search PRs
  };

in
commonAliases // macAliases // linuxAliases // gitAliases // githubAliases
