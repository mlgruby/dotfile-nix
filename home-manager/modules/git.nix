{ config, pkgs, ... }: {
  programs.git = {
    enable = true;
    
    # Your identity
    userName = "Satyasheel";
    userEmail = "satyasheel@lightricks.com";

    # Default settings
    extraConfig = {
      init.defaultBranch = "develop";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core = {
        editor = "vim";
        autocrlf = "input";
      };
      color.ui = true;
    };

    # Git aliases
    aliases = {
      st = "status";
      ci = "commit";
      br = "branch";
      co = "checkout";
      df = "diff";
      lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };

    # Git ignores
    ignores = [
      ".DS_Store"
      "*.swp"
      ".env"
      ".direnv"
      "node_modules"
      ".vscode"
    ];
  };

  # Git-specific aliases
  programs.zsh.shellAliases = {
    # Basic git operations
    gp = "git push";
    gl = "git pull";
    gs = "git status";
    gd = "git diff";
    
    # Quick add and push operations
    gpush = "git add . && git commit -m";  # Usage: gpush "commit message"
    gpushf = "git add . && git commit --amend --no-edit && git push -f";  # Force push (careful!)
    gpushnew = "git push -u origin HEAD";  # Push new branch to origin
    
    # Advanced git operations
    gare = "git remote add upstream";    # Add upstream remote
    gre = "git remote -v";               # List remotes
    gcan = "git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit -v -a --no-edit --amend";
    gfa = "git fetch --all";             # Fetch all
    gfap = "git fetch --all --prune";    # Fetch all and prune
    
    # Tools
    lg = "lazygit";                      # LazyGit
  };

  # Git functions
  programs.zsh.initExtra = ''
    # Get the default branch (main/master) of the repository
    function gitdefaultbranch() {
      git remote show origin | grep 'HEAD' | cut -d':' -f2 | sed -e 's/^ *//g' -e 's/ *$//g'
    }
  '';
} 