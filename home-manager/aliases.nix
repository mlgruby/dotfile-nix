# home/aliases.nix - Optimized Shell Aliases & Functions
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
{
  pkgs,
  config,
  ...
} @ args: let
  inherit (pkgs.stdenv) isDarwin isLinux;
  isMacOS = isDarwin;
  homeDir = config.home.homeDirectory;
  dotfileDir = "${homeDir}/Documents/dotfile";

  # Helper function for creating similar aliases
  mkAliases = prefix: cmd: options:
    builtins.listToAttrs (
      map (opt: {
        name = "${prefix}${opt.suffix}";
        value = "${cmd} ${opt.args}";
      })
      options
    );

  # Common alias groups
  ezaAliases = mkAliases "ls" "eza" [
    {
      suffix = "a";
      args = "-la";
    }
    {
      suffix = "t";
      args = "-T";
    }
    {
      suffix = "ta";
      args = "-Ta";
    }
    {
      suffix = "r";
      args = "-R";
    }
    {
      suffix = "g";
      args = "-l --git";
    }
    {
      suffix = "m";
      args = "-l --sort=modified";
    }
    {
      suffix = "s";
      args = "-l --sort=size";
    }
  ];

  fdAliases = mkAliases "f" "fd" [
    {
      suffix = "dh";
      args = "-H";
    }
    {
      suffix = "a";
      args = "-a";
    }
    {
      suffix = "t";
      args = "-tf --changed-within 1d";
    }
    {
      suffix = "dir";
      args = "-td";
    }
    {
      suffix = "f";
      args = "-tf";
    }
    {
      suffix = "sym";
      args = "-tl";
    }
    {
      suffix = "py";
      args = "-e py";
    }
    {
      suffix = "js";
      args = "-e js";
    }
    {
      suffix = "nix";
      args = "-e nix";
    }
    {
      suffix = "sh";
      args = "-e sh";
    }
    {
      suffix = "md";
      args = "-e md";
    }
    {
      suffix = "conf";
      args = "-e conf -e config";
    }
  ];

  dufAliases = mkAliases "df" "duf" [
    {
      suffix = "a";
      args = "--all";
    }
    {
      suffix = "h";
      args = "--hide-fs tmpfs,devtmpfs,efivarfs";
    }
    {
      suffix = "i";
      args = "--only local,network";
    }
  ];

  btmAliases = mkAliases "bm" "btm" [
    {
      suffix = "";
      args = "--basic";
    }
    {
      suffix = "p";
      args = "--process_command";
    }
    {
      suffix = "t";
      args = "--tree";
    }
    {
      suffix = "b";
      args = "--battery";
    }
  ];

  tmuxAliases = {
    tn = "tmux new -s";
    ta = "tmux attach -t";
    tl = "tmux list-sessions";
    tk = "tmux kill-session -t";
    t = "tmux new-session -A -s main";
    tpi = "tmux run-shell ${homeDir}/.tmux/plugins/tpm/bindings/install_plugins";
    tpu = "tmux run-shell ${homeDir}/.tmux/plugins/tpm/bindings/update_plugins";
    tpU = "tmux run-shell ${homeDir}/.tmux/plugins/tpm/bindings/clean_plugins";
  };

  gitAliases = {
    gcb = "git branch --all | grep -v HEAD | fzf --preview 'git log --oneline --graph --date=short --color=always --pretty=\"%C(auto)%cd %h%d %s\" {1}' | sed 's/.* //' | xargs git checkout";
    lgc = "lazygit -w $(pwd)";
    lgf = "lazygit -f $(find . -type d -name '.git' -exec dirname {} \\; | fzf)";
    fshow = "git log --graph --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr' | fzf --ansi --preview 'echo {} | grep -o \"[a-f0-9]\\{7\\}\" | head -1 | xargs -I % sh -c \"git show --color=always %\"'";
    fstash = "git stash list | fzf --preview 'echo {} | cut -d: -f1 | xargs -I % sh -c \"git stash show --color=always %\"' | cut -d: -f1 | xargs -I % sh -c 'git stash apply %'";
  };

  fzfAliases = {
    fe = "fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' | xargs -r nano";
    ffp = "fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'";
    fcd = "cd $(find . -type d -not -path '*/\.*' | fzf)";
    fif = "rg --color=always --line-number --no-heading --smart-case \"\" | fzf --ansi --preview 'bat --color=always --style=numbers {1} --highlight-line {2}'";
    fkill = "ps -ef | sed 1d | fzf -m | awk '{print $2}' | xargs kill -9";
    fmem = "ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -20 | fzf --header-lines=1";
    hist = "history 0 | fzf --ansi --preview 'echo {}' | sed 's/ *[0-9]* *//'";
    fenv = "env | fzf --preview 'echo {}' | cut -d= -f2";
  };

  dockerAliases = {
    d = "docker";
    dc = "docker-compose";
    dsp = "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | fzf --header-lines=1 | awk '{print $1}' | xargs -r docker stop";
    drm = "docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | fzf --header-lines=1 | awk '{print $1}' | xargs -r docker rm";
  };

  terraformAliases = {
    tf = "terraform";
    tfin = "terraform init";
    tfp = "terraform plan";
    tfi = "tfswitch -i";
    tfu = "tfswitch -u";
    tfl = "tfswitch -l";
    tfwst = "terraform workspace select";
    tfwsw = "terraform workspace show";
    tfwls = "terraform workspace list";
  };

  commonAliases =
    {
      # System & Shell
      reload = "source ${homeDir}/.zshrc && clear";
      rl = "reload";
      restart = "exec zsh";
      re = "restart";

      # Navigation
      dotfile = "cd ${dotfileDir}";
      dl = "cd ${homeDir}/Downloads";
      docs = "cd ${homeDir}/Documents";
      cdf = "cd $(ls -d */ | fzf)";
      cd = "z";

      # Modern CLI replacements
      cat = "bat";
      ls = "eza -l";
      find = "fd";
      top = "btop";
      htop = "btop";
      df = "duf";

      # File operations
      mkdir = "mkdir -p";
      rm = "rm -rf";
      cp = "cp -r";
      mv = "mv -i";

      # Editors
      v = "nvim";
      vim = "nvim";
      c = "code .";
      ce = "code . && exit";

      # System monitoring
      cpu = "btm --basic --cpu_left_legend";
      mem = "btm --basic --memory_legend none";
      net = "btm --basic --network_legend none";
      sys = "neofetch";
      sysinfo = "neofetch";
      fetch = "neofetch";

      # Documentation
      h = "tldr";
      help = "tldr";
      rtfm = "tldr";
      cheat = "tldr";
      tldr-update = "tldr --update";
      md = "glow";
      readme = "glow README.md";
      changes = "glow CHANGELOG.md";

      # Network
      ipp = "curl https://ipecho.net/plain; echo";

      # Smart editor for dotfiles
      codedot = ''
        if command -v cursor &> /dev/null; then
          cursor "${dotfileDir}"
        else
          code "${dotfileDir}"
        fi
      '';
    }
    // ezaAliases
    // fdAliases
    // dufAliases
    // btmAliases
    // tmuxAliases
    // gitAliases
    // fzfAliases
    // dockerAliases
    // terraformAliases;

  macAliases =
    if isMacOS
    then {
      rebuild = "cd ${dotfileDir} && sudo darwin-rebuild switch --flake .#\"$(hostname)\" --option max-jobs auto && cd - && rl";

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

      update = ''
        echo "🔄 Updating Nix flake..." && \
        cd ${dotfileDir} && \
        nix --option max-jobs auto flake update && \
        echo "🔄 Rebuilding system..." && rebuild && \
        echo "✨ System update complete!"
      '';

      cleanup = ''
        echo "🧹 Running system cleanup..." && \
        echo "🗑️  Running Nix garbage collection..." && \
        nix-collect-garbage -d --option max-jobs 6 --cores 2 && \
        echo "✓ Nix garbage collection complete" && \
        echo "🧹 Cleaning .DS_Store files..." && \
        find ${homeDir} -type f -name '.DS_Store' -delete 2>/dev/null || true && \
        find ${homeDir} -type f -name '._*' -delete 2>/dev/null || true && \
        echo "🧹 Cleaning npm cache..." && \
        command -v npm &> /dev/null && npm cache clean --force 2>/dev/null || true && \
        echo "🧹 Cleaning Homebrew cache..." && \
        command -v brew &> /dev/null && brew cleanup 2>/dev/null || true && \
        echo "🧹 Cleaning UV cache..." && \
        command -v uv &> /dev/null && ${homeDir}/.local/bin/uv cache clean 2>/dev/null || true && \
        echo "🧹 Optimizing Nix store..." && \
        nix store optimise --option max-jobs 6 --cores 2 && \
        echo "✨ Cleanup complete!"
      '';

      # Finder & macOS specific
      showhidden = "defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder";
      hidehidden = "defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder";
      showdesktop = "defaults write com.apple.finder CreateDesktop -bool true && killall Finder";
      hidedesktop = "defaults write com.apple.finder CreateDesktop -bool false && killall Finder";
    }
    else {};

  linuxAliases =
    if isLinux
    then {
      rebuild = "sudo nixos-rebuild switch --flake ${dotfileDir}#$(hostname)";
      update = ''
        echo "🔄 Updating Nix flake..." && \
        cd ${dotfileDir} && \
        sudo nix flake update && \
        echo "🔄 Rebuilding system..." && rebuild && \
        echo "✨ System update complete!"
      '';

      # Package management
      install = "nix-env -iA";
      search = "nix search nixpkgs";
    }
    else {};
in
  commonAliases // macAliases // linuxAliases
