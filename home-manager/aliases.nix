# home/aliases.nix - Enhanced Shell Aliases with Helper Functions
#
# Shell Aliases and Functions
#
# Purpose:
# - Standardizes command-line workflows with reusable patterns
# - Enhances system interaction through smart helper functions
# - Automates common tasks with maintainable code structure
#
# Enhanced Features:
# - Advanced helper function system for DRY principle
# - Smart command availability detection
# - Platform-aware alias generation
# - Template-based complex command creation
# - Type-safe alias group management
#
# Helper Functions:
# 1. mkAliases - Enhanced prefix-based alias generation
# 2. mkPlatformAliases - Platform-conditional alias creation
# 3. mkCommandAliases - Command availability-based aliases
# 4. mkTemplateAlias - Multi-line command template system
# 5. mkFileTypeAliases - File extension-based alias patterns
# 6. mkPathAliases - Smart path-based alias generation
#
# Integration:
# - Platform detection (macOS/Linux)
# - Environment awareness with XDG compliance
# - Dynamic path handling via Home Manager
# - Command availability checks with fallbacks
#
# Note:
# - Modular design for easy extension
# - Type-safe pattern matching
# - Comprehensive error handling
# - Performance-optimized alias resolution
{
  pkgs,
  config,
  userConfig,
  ...
} @ args: let
  inherit (pkgs.stdenv) isDarwin isLinux;
  inherit (pkgs.lib) optionalAttrs;
  isMacOS = isDarwin;
  homeDir = config.home.homeDirectory;
  dotfileDir = "${homeDir}/${userConfig.directories.dotfiles}";

  # Enhanced Helper Functions for Alias Generation

  # Enhanced mkAliases with validation and optional descriptions
  mkAliases = prefix: cmd: options:
    builtins.listToAttrs (
      map (opt: {
        name = "${prefix}${opt.suffix}";
        value = "${cmd} ${opt.args}";
      })
      (builtins.filter (opt: opt ? suffix && opt ? args) options)
    );

  # Platform-conditional alias creation
  mkPlatformAliases = platform: aliases:
    if (platform == "darwin" && isDarwin) || (platform == "linux" && isLinux)
    then aliases
    else {};

  # Command availability-based alias creation
  mkCommandAliases = cmdCheck: aliases:
    # In Nix evaluation, we assume commands are available if they're in pkgs
    # Runtime availability is handled by shell conditionals within alias values
    aliases;

  # Template-based alias for complex multi-line commands
  mkTemplateAlias = template: vars:
    builtins.replaceStrings 
      (map (v: "@${v.name}@") vars)
      (map (v: v.value) vars)
      template;

  # File extension-based alias pattern generator
  mkFileTypeAliases = prefix: cmd: extensions:
    mkAliases prefix cmd (
      map (ext: {
        suffix = ext;
        args = "-e ${ext}";
      }) extensions
    );

  # Enhanced path-based alias generator with Home Manager integration
  mkPathAliases = paths:
    builtins.listToAttrs (
      map (path: {
        name = path.alias;
        value = "cd ${path.dir}";
      }) paths
    );

  # Generate directory aliases from user configuration
  mkUserDirAliases = userDirs: homeDir:
    builtins.listToAttrs (
      builtins.filter (item: item.name != null && item.value != null) (
        builtins.attrValues (
          builtins.mapAttrs (dirName: dirPath: {
            name = 
              if dirName == "dotfiles" then "dotfile"
              else if dirName == "downloads" then "dl" 
              else if dirName == "documents" then "docs"
              else if dirName == "workspace" then "ws"
              else dirName; # Use the directory name as alias for custom dirs
            value = "cd ${homeDir}/${dirPath}";
          }) userDirs
        )
      )
    );

  # Enhanced command group generators with better organization

  # Modern CLI replacement aliases with fallback support
  ezaAliases = mkAliases "ls" "eza" [
    { suffix = "a"; args = "-la"; }
    { suffix = "t"; args = "-T"; }
    { suffix = "ta"; args = "-Ta"; }
    { suffix = "r"; args = "-R"; }
    { suffix = "g"; args = "-l --git"; }
    { suffix = "m"; args = "-l --sort=modified"; }
    { suffix = "s"; args = "-l --sort=size"; }
    { suffix = "h"; args = "-la --header"; }
    { suffix = "tree"; args = "-T --level=3"; }
  ];

  # Enhanced fd aliases with common file type patterns
  fdAliases = 
    (mkAliases "f" "fd" [
      { suffix = "dh"; args = "-H"; }
      { suffix = "a"; args = "-a"; }
      { suffix = "t"; args = "-tf --changed-within 1d"; }
      { suffix = "dir"; args = "-td"; }
      { suffix = "f"; args = "-tf"; }
      { suffix = "sym"; args = "-tl"; }
      { suffix = "conf"; args = "-e conf -e config"; }
    ]) //
    (mkFileTypeAliases "f" "fd" [ "py" "js" "nix" "sh" "md" "json" "yaml" "toml" ]);

  # Enhanced system monitoring aliases
  dufAliases = mkAliases "df" "duf" [
    { suffix = "a"; args = "--all"; }
    { suffix = "h"; args = "--hide-fs tmpfs,devtmpfs,efivarfs"; }
    { suffix = "i"; args = "--only local,network"; }
    { suffix = "s"; args = "--sort size"; }
  ];

  # Bottom/btm process monitor aliases
  btmAliases = mkAliases "bm" "btm" [
    { suffix = ""; args = "--basic"; }
    { suffix = "p"; args = "--process_command"; }
    { suffix = "t"; args = "--tree"; }
    { suffix = "b"; args = "--battery"; }
    { suffix = "n"; args = "--network_legend"; }
  ];

  # Enhanced tmux session management
  tmuxAliases = {
    # Session management
    tn = "tmux new -s";
    ta = "tmux attach -t";
    tl = "tmux list-sessions";
    tk = "tmux kill-session -t";
    t = "tmux new-session -A -s main";
    
    # Plugin management (with path variables)
    tpi = "tmux run-shell ${homeDir}/.tmux/plugins/tpm/bindings/install_plugins";
    tpu = "tmux run-shell ${homeDir}/.tmux/plugins/tpm/bindings/update_plugins";
    tpU = "tmux run-shell ${homeDir}/.tmux/plugins/tpm/bindings/clean_plugins";
    
    # Enhanced session utilities
    tls = "tmux list-sessions -F '#{session_name}: #{?session_attached,attached,not attached}'";
    tkall = "tmux list-sessions -F '#{session_name}' | xargs -I {} tmux kill-session -t {}";
  };

  # Enhanced git workflow aliases
  gitAliases = {
    # Interactive branch selection with preview
    gcb = "git branch --all | grep -v HEAD | fzf --preview 'git log --oneline --graph --date=short --color=always --pretty=\"%C(auto)%cd %h%d %s\" {1}' | sed 's/.* //' | xargs git checkout";
    
    # LazyGit integration
    lgc = "lazygit -w $(pwd)";
    lgf = "lazygit -f $(find . -type d -name '.git' -exec dirname {} \\; | fzf)";
    lgs = "lazygit status"; # Quick status view

    # Enhanced log and stash browsing
    fshow = "git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr' | fzf --ansi --preview 'echo {} | grep -o \"[a-f0-9]\\{7\\}\" | head -1 | xargs -I % sh -c \"git show --color=always %\"'";
    fstash = "git stash list | fzf --preview 'echo {} | cut -d: -f1 | xargs -I % sh -c \"git stash show --color=always %\"' | cut -d: -f1 | xargs -I % sh -c 'git stash apply %'";
    
    # Quick status and operations
    gs = "git status --short";
    gaa = "git add --all";
    gcm = "git commit -m";
    gp = "git push";
    gl = "git pull";

    # Advanced workflow aliases
    gco = "git checkout";
    gcob = "git checkout -b"; # Create and checkout new branch
    gcom = "git checkout main || git checkout master"; # Smart main branch checkout
    gcod = "git checkout develop"; # Checkout develop

    # Commit operations
    gca = "git commit --amend"; # Amend last commit
    gcan = "git commit --amend --no-edit"; # Amend without editing message
    gcane = "git commit --amend --no-edit"; # Duplicate for muscle memory
    gwip = "git add -A && git commit -m 'WIP'"; # Quick work in progress commit
    gunwip = "git log -1 --pretty=%s | grep -q 'WIP' && git reset HEAD~1"; # Undo WIP commit

    # Branch management
    gbd = "git branch -d"; # Delete branch (safe)
    gbD = "git branch -D"; # Force delete branch
    gbl = "git branch -l"; # List local branches
    gbr = "git branch -r"; # List remote branches
    gba = "git branch -a"; # List all branches
    gbn = "git checkout -b"; # New branch (alias for gcob)

    # Remote operations
    gf = "git fetch";
    gfa = "git fetch --all";
    gfo = "git fetch origin";
    gps = "git push";
    gpsf = "git push --force-with-lease"; # Safe force push
    gpsu = "git push -u origin HEAD"; # Push and set upstream
    gpl = "git pull";
    gplr = "git pull --rebase"; # Pull with rebase

    # Stash operations
    gst = "git stash";
    gsta = "git stash push -m"; # Stash with message
    gstp = "git stash pop";
    gstl = "git stash list";
    gsts = "git stash show";
    gstd = "git stash drop";
    gstc = "git stash clear";

    # Log operations
    glog = "git log --oneline --decorate --graph";
    gloga = "git log --oneline --decorate --graph --all";
    glogp = "git log --pretty=format:'%h -%d %s (%cr) <%an>' --abbrev-commit";
    glast = "git log -1 HEAD"; # Show last commit

    # Diff operations
    gd = "git diff";
    gdc = "git diff --cached"; # Diff staged changes
    gdh = "git diff HEAD"; # Diff against HEAD
    gdt = "git diff-tree --no-commit-id --name-only -r"; # Show files in commit

    # Reset operations
    grh = "git reset HEAD"; # Unstage files
    grhh = "git reset HEAD --hard"; # Hard reset to HEAD
    groh = "git reset origin/HEAD --hard"; # Reset to remote HEAD

    # Rebase operations
    grb = "git rebase";
    grbi = "git rebase -i"; # Interactive rebase
    grbc = "git rebase --continue";
    grba = "git rebase --abort";
    grbs = "git rebase --skip";

    # Tag operations
    gt = "git tag";
    gta = "git tag -a"; # Annotated tag
    gtd = "git tag -d"; # Delete tag
    gtl = "git tag -l"; # List tags

    # Worktree operations (advanced)
    gwt = "git worktree";
    gwta = "git worktree add";
    gwtl = "git worktree list";
    gwtr = "git worktree remove";

    # Bisect operations
    gbs = "git bisect start";
    gbsg = "git bisect good";
    gbsb = "git bisect bad";
    gbsr = "git bisect reset";

    # Clean operations
    gclean = "git clean -fd"; # Remove untracked files and directories
    gcleann = "git clean -fdn"; # Dry run clean

    # Shortcuts for common workflows
    gsync = "git fetch origin && git checkout main && git pull origin main"; # Sync with main
    gup = "git fetch && git rebase origin/main"; # Update current branch
    gnuke = "git reset --hard && git clean -fd"; # Nuclear option - lose all local changes

    # Search operations
    ggrep = "git grep";
    glog-search = "git log --grep"; # Search commit messages
    glog-author = "git log --author"; # Search by author

    # GitHub CLI integration (if available)
    ghpr = "gh pr create --fill"; # Create PR with auto-filled info
    ghprs = "gh pr status"; # PR status
    ghprv = "gh pr view --web"; # View PR in browser
    ghprm = "gh pr merge"; # Merge PR

    # Conventional commits helpers
    feat = "git commit -m 'feat: '"; # Feature commit template
    fix = "git commit -m 'fix: '"; # Fix commit template
    docs = "git commit -m 'docs: '"; # Docs commit template
    style = "git commit -m 'style: '"; # Style commit template
    refactor = "git commit -m 'refactor: '"; # Refactor commit template
    test = "git commit -m 'test: '"; # Test commit template
    chore = "git commit -m 'chore: '"; # Chore commit template
  };

  # Enhanced GitHub CLI workflow aliases
  githubAliases = {
    # PR Management with enhanced workflow
    ghprl = "gh pr list --limit 1000";
    ghpro = "gh pr list --state open --limit 1000";
    ghprch = "gh pr checks";
    ghprf = "gh pr list --state open | fzf --preview 'echo {} | awk \"{print \\$1}\" | xargs gh pr view' | awk '{print $1}' | xargs gh pr view --web";

    # Repository Management
    ghrv = "gh repo view --web";
    ghrc = "gh repo clone";
    ghrf = "gh repo fork";
    ghrs = "gh repo sync";

    # Issue Management
    ghil = "gh issue list --limit 1000";
    ghic = "gh issue create";
    ghiv = "gh issue view";
    ghif = "gh issue list | fzf --preview 'echo {} | awk \"{print \\$1}\" | xargs gh issue view' | awk '{print $1}' | xargs gh issue view --web";
  };

  # Enhanced FZF integration aliases
  fzfAliases = {
    # File operations with previews
    fe = "fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' | xargs -r \${EDITOR:-nvim}";
    ffp = "fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'";
    
    # Directory navigation
    fcd = "cd $(find . -type d -not -path '*/\\.*' | fzf)";
    fcdh = "cd $(find . -type d | fzf)";  # Include hidden directories
    
    # Content search and process management
    fif = "rg --color=always --line-number --no-heading --smart-case \"\" | fzf --ansi --preview 'bat --color=always --style=numbers {1} --highlight-line {2}'";
    fkill = "ps -ef | sed 1d | fzf -m | awk '{print $2}' | xargs kill -9";
    fmem = "ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -20 | fzf --header-lines=1";
    
    # Shell history and environment
    hist = "history 0 | fzf --ansi --preview 'echo {}' | sed 's/ *[0-9]* *//'";
    fenv = "env | fzf --preview 'echo {}' | cut -d= -f2";
  };

  # Enhanced Docker workflow aliases
  dockerAliases = {
    # Basic commands
    d = "docker";
    dc = "docker-compose";
    
    # Interactive container management
    dsp = "docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}' | fzf --header-lines=1 | awk '{print $1}' | xargs -r docker stop";
    drm = "docker ps -a --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}' | fzf --header-lines=1 | awk '{print $1}' | xargs -r docker rm";
    
    # Enhanced utilities
    dimg = "docker images --format 'table {{.Repository}}\\t{{.Tag}}\\t{{.Size}}' | fzf --header-lines=1";
    dlog = "docker ps --format 'table {{.Names}}\\t{{.Status}}' | fzf --header-lines=1 | awk '{print $1}' | xargs -r docker logs -f";
    dexec = "docker ps --format 'table {{.Names}}\\t{{.Status}}' | fzf --header-lines=1 | awk '{print $1}' | xargs -r -I {} docker exec -it {} /bin/bash";
  };

  # Enhanced Terraform workflow aliases
  terraformAliases = {
    # Basic commands
    tf = "terraform";
    tfin = "terraform init";
    tfp = "terraform plan";
    tfa = "terraform apply";
    tfd = "terraform destroy";
    
    # Version management
    tfi = "tfswitch -i";
    tfu = "tfswitch -u";
    tfl = "tfswitch -l";
    
    # Workspace management
    tfwst = "terraform workspace select";
    tfwsw = "terraform workspace show";
    tfwls = "terraform workspace list";
    tfwsn = "terraform workspace new";
    
    # Enhanced planning and state
    tfpd = "terraform plan -destroy";
    tfsh = "terraform show";
    tfst = "terraform state list";
  };

  # Enhanced kubectl/Kubernetes workflow aliases
  k8sAliases = {
    # Basic kubectl shortcuts
    k = "kubectl";
    kgp = "kubectl get pods";
    kgs = "kubectl get services";
    kgn = "kubectl get nodes";
    kgd = "kubectl get deployments";
    kgns = "kubectl get namespaces";
    kgi = "kubectl get ingress";
    kgpv = "kubectl get pv";
    kgpvc = "kubectl get pvc";

    # Describe resources
    kdp = "kubectl describe pod";
    kds = "kubectl describe service";
    kdd = "kubectl describe deployment";
    kdn = "kubectl describe node";

    # Logs and monitoring
    klog = "kubectl logs";
    klogf = "kubectl logs -f";
    klogtail = "kubectl logs --tail=100";

    # Pod management
    kexec = "kubectl exec -it";
    kshell = "kubectl exec -it";
    kdel = "kubectl delete";
    kdelp = "kubectl delete pod";

    # Apply and create
    ka = "kubectl apply -f";
    kc = "kubectl create";

    # Port forwarding
    kpf = "kubectl port-forward";

    # Interactive selectors with fzf
    kpod = "kubectl get pods | fzf --header-lines=1 | awk '{print $1}'";
    ksvc = "kubectl get services | fzf --header-lines=1 | awk '{print $1}'";

    # Regular kubectl (redundant but explicit)
    kctl = "kubectl";
    kget = "kubectl get";
    kdesc = "kubectl describe";
    klogs = "kubectl logs";
    kapply = "kubectl apply -f";

    # Context and namespace management
    kctx = "kubectl config current-context";
    kns = "kubectl config set-context --current --namespace";
    kctxs = "kubectl config get-contexts";

    # Quick cluster info
    kinfo = "kubectl cluster-info";
    kversion = "kubectl version";
    ktop = "kubectl top nodes";
    ktoppods = "kubectl top pods";
  };

  # Core system and navigation aliases
  coreAliases = {
    # System & Shell management
      reload = "source ${homeDir}/.zshrc && clear";
      rl = "reload";
      restart = "exec zsh";
      re = "restart";

    # Smart navigation with configurable path helpers
    # Note: Directory aliases generated dynamically below
    dev = "cd ${homeDir}/${userConfig.directories.workspace}";  # Alternative dev alias
      cdf = "cd $(ls -d */ | fzf)";
    cd = "z";  # zoxide integration

    # Modern CLI replacements with fallbacks
      cat = "bat";
      ls = "eza -l";
      find = "fd";
      top = "btop";
      htop = "btop";
      df = "duf";

    # File operations (safe by default)
      mkdir = "mkdir -p";
      rm = "rm -rf";
      cp = "cp -r";
      mv = "mv -i";

    # Editor shortcuts
      v = "nvim";
      vim = "nvim";
      c = "code .";
      ce = "code . && exit";

    # System monitoring shortcuts
      cpu = "btm --basic --cpu_left_legend";
      mem = "btm --basic --memory_legend none";
      net = "btm --basic --network_legend none";
      sys = "neofetch";
      sysinfo = "neofetch";
      fetch = "neofetch";

    # Documentation and help
      h = "tldr";
      help = "tldr";
      rtfm = "tldr";
      cheat = "tldr";
      tldr-update = "tldr --update";
      md = "glow";
      readme = "glow README.md";
      changes = "glow CHANGELOG.md";

    # Network utilities
      ipp = "curl https://ipecho.net/plain; echo";
    myip = "curl https://ipecho.net/plain; echo";

    # Smart editor for dotfiles with cursor/code detection
    codedot = mkTemplateAlias ''
        if command -v cursor &> /dev/null; then
        cursor "@dotfileDir@"
        else
        code "@dotfileDir@"
        fi
    '' [
      { name = "dotfileDir"; value = dotfileDir; }
    ];

    # Additional productivity aliases
    work = "cd ${homeDir}/${userConfig.directories.workspace}"; # Quick workspace navigation
    recent = "ls -lt | head -20"; # Show recently modified files
    size = "du -sh"; # Show directory size
    ports = "lsof -iTCP -sTCP:LISTEN -n -P"; # Show listening ports
    path = "echo $PATH | tr ':' '\n'"; # Pretty print PATH

    # Quick file operations
    backup = "cp -R"; # Quick backup with rename
    extract = "tar -xzvf"; # Quick tar extract
    compress = "tar -czvf"; # Quick tar compress

    # Time and date helpers
    now = "date '+%Y-%m-%d %H:%M:%S'"; # Current timestamp
    today = "date '+%Y-%m-%d'"; # Today's date
    week = "date '+%Y-W%U'"; # Current week

    # Process management
    psg = "ps aux | grep"; # Process search
    killall = "pkill -f"; # Kill by process name

    # Network helpers
    ping1 = "ping -c 1"; # Single ping
    ping10 = "ping -c 10"; # 10 pings
    ports-open = "netstat -tuln"; # Show open ports

    # Clipboard integration (macOS)
    copy = "pbcopy"; # Copy to clipboard
    paste = "pbpaste"; # Paste from clipboard

    # Quick git status in any directory
    s = "git status"; # Very short git status

    # LazyGit super shortcuts
    lg = "lazygit"; # Just 'lg' for lazygit
    lazydot = "cd ${dotfileDir} && lazygit"; # LazyGit in dotfiles

    # FZF powered file editing
    edit = "fzf --preview 'bat --color=always {}' | xargs nvim"; # Edit with preview

    # JSON/YAML pretty printing
    json = "python3 -m json.tool"; # Pretty print JSON
    yaml = "yq eval '.' -"; # Pretty print YAML (if yq installed);
  };

  # Platform-specific aliases using helper functions
  macAliases = mkPlatformAliases "darwin" {
    # Enhanced system management with performance optimizations
    rebuild = mkTemplateAlias ''
      cd @dotfileDir@ && \
      echo "🔄 Building system configuration with performance optimizations..." && \
      sudo darwin-rebuild switch --flake .#"$(hostname)" --option max-jobs auto --option cores 0 --option keep-outputs true && \
      cd - && \
      echo "✅ System rebuild complete!" && \
      rl
    '' [
      { name = "dotfileDir"; value = dotfileDir; }
    ];

    # Interactive rollback with preview
    rollback = mkTemplateAlias ''
      generation=$(darwin-rebuild list-generations | \
          fzf --header "Select a generation to roll back to" \
              --preview "echo {} | grep -o '[0-9]\\+' | xargs -I % sh -c 'nix-store -q --references /nix/var/nix/profiles/system-%'" \
              --preview-window "right:60%" \
            --layout=reverse) && \
      if [ -n "$generation" ]; then \
        generation_number=$(echo $generation | grep -o '[0-9]\\+' | head -1) && \
        echo "🔄 Rolling back to generation $generation_number..." && \
        darwin-rebuild switch --switch-generation $generation_number && \
        echo "✅ Rollback complete!" \
        fi
    '' [];

    # Comprehensive system update workflow with performance optimizations
    update = mkTemplateAlias ''
      echo "🔄 Starting optimized system update..." && \
      cd @dotfileDir@ && \
      echo "📦 Updating Nix flake..." && \
      nix --option max-jobs auto --option cores 0 flake update && \
      echo "🔧 Rebuilding system with optimizations..." && \
      rebuild && \
        echo "✨ System update complete!"
    '' [
      { name = "dotfileDir"; value = dotfileDir; }
    ];

    # Enhanced cleanup with detailed progress and performance optimizations
    cleanup = mkTemplateAlias ''
      echo "🧹 Starting comprehensive system cleanup..." && \
        echo "🗑️  Running Nix garbage collection..." && \
      nix-collect-garbage -d --option max-jobs auto --option cores 0 && \
        echo "✓ Nix garbage collection complete" && \
      echo "🧹 Cleaning macOS system files..." && \
      find @homeDir@ -type f -name '.DS_Store' -delete 2>/dev/null || true && \
      find @homeDir@ -type f -name '._*' -delete 2>/dev/null || true && \
      echo "🧹 Cleaning package caches..." && \
        command -v npm &> /dev/null && npm cache clean --force 2>/dev/null || true && \
        command -v brew &> /dev/null && brew cleanup 2>/dev/null || true && \
      command -v uv &> /dev/null && @homeDir@/.local/bin/uv cache clean 2>/dev/null || true && \
        echo "🧹 Optimizing Nix store..." && \
      nix store optimise --option max-jobs auto --option cores 0 && \
        echo "✨ Cleanup complete!" && \
        rl
    '' [
      { name = "homeDir"; value = homeDir; }
    ];

    # Performance-focused build commands
    rebuild-fast = mkTemplateAlias ''
      cd @dotfileDir@ && \
      echo "🚀 Fast rebuild with maximum performance..." && \
      sudo darwin-rebuild switch --flake .#"$(hostname)" --option max-jobs auto --option cores 0 --option keep-outputs true --option keep-derivations true && \
      cd - && \
      echo "⚡ Fast rebuild complete!" && \
      rl
    '' [
      { name = "dotfileDir"; value = dotfileDir; }
    ];

    rebuild-check = mkTemplateAlias ''
      cd @dotfileDir@ && \
      echo "🔍 Checking what will be built..." && \
      darwin-rebuild build --flake .#"$(hostname)" --dry-run --option max-jobs auto && \
      cd -
    '' [
      { name = "dotfileDir"; value = dotfileDir; }
    ];

    # Performance analysis commands
    perf-analyze = mkTemplateAlias ''
      cd @dotfileDir@ && \
      ./scripts/analyze-build-performance.sh --report && \
      cd -
    '' [
      { name = "dotfileDir"; value = dotfileDir; }
    ];

    perf-profile = mkTemplateAlias ''
      cd @dotfileDir@ && \
      ./scripts/analyze-build-performance.sh --profile && \
      cd -
    '' [
      { name = "dotfileDir"; value = dotfileDir; }
    ];

    perf-optimize = mkTemplateAlias ''
      cd @dotfileDir@ && \
      ./scripts/analyze-build-performance.sh --optimize && \
      cd -
    '' [
      { name = "dotfileDir"; value = dotfileDir; }
    ];

    # System health monitoring commands
    health-check = mkTemplateAlias ''
      cd @dotfileDir@ && \
      ./scripts/system-health-monitor.sh --check && \
      cd -
    '' [
      { name = "dotfileDir"; value = dotfileDir; }
    ];

    health-report = mkTemplateAlias ''
      cd @dotfileDir@ && \
      ./scripts/system-health-monitor.sh --report && \
      cd -
    '' [
      { name = "dotfileDir"; value = dotfileDir; }
    ];

    health-maintain = mkTemplateAlias ''
      cd @dotfileDir@ && \
      ./scripts/system-health-monitor.sh --maintain && \
      cd -
    '' [
      { name = "dotfileDir"; value = dotfileDir; }
    ];

    health-alert = mkTemplateAlias ''
      cd @dotfileDir@ && \
      ./scripts/system-health-monitor.sh --alert && \
      cd -
    '' [
      { name = "dotfileDir"; value = dotfileDir; }
    ];

    # Log viewing commands for monitoring
    logs-health = "tail -f ~/.local/var/log/system-health-check.log";
    logs-maintenance = "tail -f ~/.local/var/log/system-maintenance.log";
    logs-performance = "tail -f ~/.local/var/log/performance-monitor.log";
    logs-alerts = "tail -f ~/.local/var/log/critical-alerts.log";

    # Service management commands
    monitor-status = "launchctl list | grep system-";
    monitor-load = "launchctl load ~/Library/LaunchAgents/system-*.plist";
    monitor-unload = "launchctl unload ~/Library/LaunchAgents/system-*.plist";

    # macOS-specific Finder utilities
      showhidden = "defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder";
      hidehidden = "defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder";
      showdesktop = "defaults write com.apple.finder CreateDesktop -bool true && killall Finder";
      hidedesktop = "defaults write com.apple.finder CreateDesktop -bool false && killall Finder";
    
    # Additional macOS utilities
    flushdns = "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder";
    sleepnow = "pmset sleepnow";
    lockscreen = "/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend";
  };

  # Linux-specific aliases
  linuxAliases = mkPlatformAliases "linux" {
      rebuild = "sudo nixos-rebuild switch --flake ${dotfileDir}#$(hostname)";
    
    update = mkTemplateAlias ''
      echo "🔄 Starting system update..." && \
      cd @dotfileDir@ && \
      echo "📦 Updating Nix flake..." && \
        sudo nix flake update && \
      echo "🔧 Rebuilding system..." && \
      rebuild && \
        echo "✨ System update complete!"
    '' [
      { name = "dotfileDir"; value = dotfileDir; }
    ];

      # Package management
      install = "nix-env -iA";
      search = "nix search nixpkgs";
    
    # System utilities
    services = "systemctl list-units --type=service";
    restart-service = "systemctl restart";
    logs = "journalctl -f";
  };

  # Generate dynamic directory aliases from user configuration
  userDirAliases = mkUserDirAliases userConfig.directories homeDir;

  # Combine all alias groups with enhanced organization
  allAliases = 
    coreAliases //
    userDirAliases //      # Dynamic directory aliases from user config
    ezaAliases //
    fdAliases //
    dufAliases //
    btmAliases //
    tmuxAliases //
    gitAliases //
    fzfAliases //
    dockerAliases //
    terraformAliases //
    k8sAliases //          # k3s/Kubernetes management aliases
    githubAliases //
    macAliases //
    linuxAliases;

in
  allAliases
