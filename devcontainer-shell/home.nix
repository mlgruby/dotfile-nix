{ pkgs, ... }: {
  # Lightweight, Dev Container-optimized package set
  home.packages = with pkgs; [
    eza          # Modern replacements for ls
    bat          # Modern replacement for cat
    fzf          # Fuzzy command-line finder
    zoxide       # Smart cd command (z/zi)
    ripgrep      # Blazing fast grep replacement
    jq           # JSON processor
    tmux         # Terminal multiplexer
    direnv       # Load/unload env variables based on directory
    starship     # Minimal, blazing-fast prompt
    fastfetch    # System informational fetch tool
    glow         # Terminal Markdown renderer
    tldr         # Quick command summaries (RTFM)
  ];

  programs = {
    # Main Zsh Configuration
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      sessionVariables = {
        CARGO_HOME = "$HOME/.cargo";
        RUSTUP_HOME = "$HOME/.rustup";
        LANG = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
      };

      # Essential, highly-efficient aliases imported directly from host config
      shellAliases = {
        # Shell basics
        c = "clear";
        x = "exit";
        h = "history";
        r = "source ~/.zshrc";
        rl = "exec zsh";
        q = "exit";

        # Navigation
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";
        "~" = "cd ~";
        "-" = "cd -";

        # Modern directory listings (eza)
        l = "eza -la --icons";
        ll = "eza -l --icons";
        la = "eza -la --icons";
        ls = "eza --icons";

        # Safe file operations
        cp = "cp -i";
        mv = "mv -i";
        rm = "rm -i";
        mkdir = "mkdir -pv";
        backup = "cp -R";
        xtract = "tar -xzvf";
        compress = "tar -czvf";

        # Modern file viewers (bat)
        cat = "bat";
        less = "bat --paging=always";

        # Tool shortcuts
        rtfm = "tldr";
        cheat = "tldr";
        md = "glow";
        sys = "fastfetch";

        # Fuzzy searching shortcuts
        alias-find = "alias | fzf --preview 'echo {}' --preview-window=right:50% | cut -d'=' -f1";
        alias-search = "alias | grep -i";

        # Git core aliases
        s = "git status";
        gs = "git status --short";
        gaa = "git add --all";
        gcm = "git commit -m";
        gp = "git push";
        gl = "git pull";
        gco = "git checkout";
        gcob = "git checkout -b";
        gcom = "git checkout main || git checkout master";
        gcod = "git checkout develop";
        gca = "git commit --amend";
        gcan = "git commit --amend --no-edit";
        gwip = "git add -A && git commit -m 'WIP'";
        glog = "git log --oneline --decorate --graph";
        gloga = "git log --oneline --decorate --graph --all";
        gd = "git diff";
        gdc = "git diff --cached";
        gdh = "git diff HEAD";
        grh = "git reset HEAD";
        grhh = "git reset HEAD --hard";
        grb = "git rebase";
        grbc = "git rebase --continue";
        grba = "git rebase --abort";
        gnuke = "git reset --hard && git clean -fd";
        quickcommit = "gaa && gcm";
        quickpush = "gaa && gcm && gp";

        # Git conventional commit shortcuts
        feat = "git commit -m 'feat: '";
        fix = "git commit -m 'fix: '";
        docs = "git commit -m 'docs: '";
        style = "git commit -m 'style: '";
        refactor = "git commit -m 'refactor: '";
        test = "git commit -m 'test: '";
        chore = "git commit -m 'chore: '";
      };

      initContent = ''
        # Sourced interactive Zsh helper extensions
        ${builtins.readFile ./zsh-integration.zsh}
      '';

      history = {
        size = 50000;
        save = 50000;
        share = true;
        ignoreDups = true;
        ignoreSpace = true;
      };
    };

    # Beautiful Gruvbox-themed Starship Prompt (identical to host config)
    starship = {
      enable = true;
      settings = {
        "$schema" = "https://starship.rs/config-schema.json";
        format = "[](color_orange)$os$username[](bg:color_yellow fg:color_orange)$directory[](fg:color_yellow bg:color_aqua)$git_branch$git_status[](fg:color_aqua bg:color_blue)$c$rust$golang$nodejs$php$java$kotlin$haskell$python[](fg:color_blue bg:color_bg3)$docker_context$conda$cmd_duration[](fg:color_bg3 bg:color_bg1)[ ](fg:color_bg1)$line_break$character";
        palette = "gruvbox_dark";

        palettes = {
          gruvbox_dark = {
            color_fg0 = "#fbf1c7";
            color_bg1 = "#3c3836";
            color_bg3 = "#665c54";
            color_blue = "#458588";
            color_aqua = "#689d6a";
            color_green = "#98971a";
            color_orange = "#d65d0e";
            color_purple = "#b16286";
            color_red = "#cc241d";
            color_yellow = "#d79921";
          };
        };

        os = {
          disabled = false;
          style = "bg:color_orange fg:color_fg0";
          symbols = {
            Windows = "󰍲";
            Ubuntu = "󰕈";
            SUSE = "";
            Raspbian = "󰐿";
            Mint = "󰣭";
            Macos = "󰀵";
            Manjaro = "";
            Linux = "󰌽";
            Gentoo = "󰣨";
            Fedora = "󰣛";
            Alpine = "";
            Amazon = "";
            Android = "";
            Arch = "󰣇";
            Artix = "󰣇";
            EndeavourOS = "";
            CentOS = "";
            Debian = "󰣚";
            Redhat = "󱄛";
            RedHatEnterprise = "󱄛";
            Pop = "";
          };
        };

        username = {
          show_always = true;
          style_user = "bg:color_orange fg:color_fg0";
          style_root = "bg:color_orange fg:color_fg0";
          format = "[ $user ]($style)";
        };

        directory = {
          style = "fg:color_fg0 bg:color_yellow";
          format = "[ $path ]($style)";
          truncation_length = 3;
          truncation_symbol = "…/";
          substitutions = {
            "Documents" = "󰈙 ";
            "Downloads" = " ";
            "Music" = "󰝚 ";
            "Pictures" = " ";
            "Developer" = "󰲋 ";
          };
        };

        git_branch = {
          symbol = "";
          style = "bg:color_aqua";
          format = "[[ $symbol $branch ](fg:color_fg0 bg:color_aqua)]($style)";
        };

        git_status = {
          style = "bg:color_aqua";
          format = "[[($all_status$ahead_behind )](fg:color_fg0 bg:color_aqua)]($style)";
        };

        nodejs = {
          symbol = "";
          style = "bg:color_blue";
          format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
        };

        c = {
          symbol = "";
          style = "bg:color_blue";
          format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
        };

        rust = {
          symbol = "";
          style = "bg:color_blue";
          format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
        };

        golang = {
          symbol = "";
          style = "bg:color_blue";
          format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
        };

        php = {
          symbol = "";
          style = "bg:color_blue";
          format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
        };

        java = {
          symbol = "";
          style = "bg:color_blue";
          format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
        };

        kotlin = {
          symbol = "";
          style = "bg:color_blue";
          format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
        };

        haskell = {
          symbol = "";
          style = "bg:color_blue";
          format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
        };

        python = {
          symbol = "";
          style = "bg:color_blue";
          format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_blue)]($style)";
        };

        docker_context = {
          symbol = "";
          style = "bg:color_bg3";
          format = "[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)";
        };

        conda = {
          style = "bg:color_bg3";
          format = "[[ $symbol( $environment) ](fg:#83a598 bg:color_bg3)]($style)";
        };

        cmd_duration = {
          min_time = 1000;
          style = "bg:color_bg3";
          format = "[[ took $duration ](fg:color_yellow bg:color_bg3)]($style)";
        };

        time = {
          disabled = false;
          time_format = "%R";
          style = "bg:color_bg1";
          format = "[[  $time ](fg:color_fg0 bg:color_bg1)]($style)";
        };

        line_break = {
          disabled = false;
        };

        character = {
          disabled = false;
          success_symbol = "[](bold fg:color_green)";
          error_symbol = "[](bold fg:color_red)";
          vimcmd_symbol = "[](bold fg:color_green)";
          vimcmd_replace_one_symbol = "[](bold fg:color_purple)";
          vimcmd_replace_symbol = "[](bold fg:color_purple)";
          vimcmd_visual_symbol = "[](bold fg:color_yellow)";
        };
      };
    };

    # Integrations
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Disable manual page generation to keep the container lightweight and avoid man-db symlink conflicts
    man.enable = false;
  };
}
