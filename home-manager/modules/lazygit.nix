# home-manager/modules/lazygit.nix
#
# LazyGit Configuration (Enhanced)
#
# Purpose:
# - Sets up LazyGit with power-user defaults
# - Optimized keybindings for efficient workflow
# - Enhanced UI and git integration
#
# Integration:
# - Works with git.nix
# - Used by shell aliases
{...}: {
  programs.lazygit = {
    enable = true;
    # package = pkgs.lazygit; # Use default package (uncomment to customize)
    # Alternative packages you could use:
    # package = pkgs.lazygit;                    # Latest stable
    # package = pkgs.lazygit-unstable;           # Development version (if available)
    # package = pkgs.lazygit.overrideAttrs {...} # Custom build
    settings = {
      gui = {
        showFileTree = true;
        mouseEvents = true;
        showRandomTip = false;
        showBranchCommitHash = true;
        showBottomLine = true;
        showCommandLog = false;
        showIcons = true;
        nerdFontsVersion = "3";
        theme = {
          lightTheme = false;
          activeBorderColor = ["green" "bold"];
          inactiveBorderColor = ["white"];
          selectedLineBgColor = ["blue"];
          selectedRangeBgColor = ["blue"];
          cherryPickedCommitBgColor = ["cyan"];
          cherryPickedCommitFgColor = ["blue"];
          unstagedChangesColor = ["red"];
          defaultFgColor = ["default"];
        };
        commitLength = {
          show = true;
        };
        skipDiscardChangeWarning = false;
        skipStashWarning = false;
        sidePanelWidth = 0.3333;
        expandFocusedSidePanel = false;
        mainPanelSplitMode = "flexible";
        enlargedSideViewLocation = "left";
      };
      
      git = {
        autoFetch = true;
        autoRefresh = true;
        fetchAll = true;
        branchLogCmd = "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium {{branchName}} --";
        allBranchesLogCmds = ["git log --graph --all --color=always --abbrev-commit --decorate --date=relative  --pretty=medium"];
        overrideGpg = false;
        disableForcePushing = false;
        # commitPrefixes = {
        #   "feat" = {
        #     pattern = "^feat(\\(.+\\))?!?:.+";
        #     replace = [""];
        #   };
        #   "fix" = {
        #     pattern = "^fix(\\(.+\\))?!?:.+"; 
        #     replace = [""];
        #   };
        # };
        parseEmoji = false;
        log = {
          order = "topo-order";
          showGraph = "when-maximised";
          showWholeGraph = false;
        };
        skipHookPrefix = "WIP";
        mainBranches = ["master" "main" "develop"];
      };
      
      keybinding = {
        universal = {
          quit = "q";
          quitWithoutChangingDirectory = "Q";
          return = "<esc>";
          scrollUpMain = "<pgup>";
          scrollDownMain = "<pgdown>";
          scrollUpMainHalfPage = "u";
          scrollDownMainHalfPage = "d";
          edit = "e";
          openFile = "o";
          refresh = "R";
          optionMenu = "x";
          optionMenuAlt1 = "?";
          select = "<space>";
          goInto = "<enter>";
          remove = "D";
          new = "n";
          copyToClipboard = "y";
          submitEditorText = "<enter>";
          appendNewline = "<a-enter>";
          extrasMenu = "@";
          toggleWhitespaceInDiffView = "<tab>";
          increaseContextInDiffView = "}";
          decreaseContextInDiffView = "{";
        };
        
        status = {
          checkForUpdate = "u";
          recentRepos = "<enter>";
          allBranchesLogGraph = "a";
        };
        
        files = {
          commitChanges = "c";
          commitChangesWithoutHook = "w";
          amendLastCommit = "A";
          commitChangesWithEditor = "C";
          ignoreFile = "i";
          refreshFiles = "r";
          stashAllChanges = "s";
          viewStashOptions = "S";
          toggleStagedAll = "a";
          viewResetOptions = "D";
          fetch = "f";
          toggleTreeView = "`";
          openMergeTool = "M";
          openStatusFilter = "<c-b>";
        };
        
        branches = {
          createPullRequest = "o";
          viewPullRequestOptions = "O";
          checkoutBranchByName = "c";
          forceCheckoutBranch = "F";
          rebaseBranch = "r";
          renameBranch = "R";
          mergeIntoCurrentBranch = "M";
          viewGitFlowOptions = "i";
          fastForward = "f";
          createTag = "T";
          pushTag = "P";
          setUpstream = "u";
          fetchRemote = "f";
        };
        
        commits = {
          squashDown = "s";
          renameCommit = "r";
          renameCommitWithEditor = "R";
          viewResetOptions = "g";
          markCommitAsFixup = "f";
          createFixupCommit = "F";
          squashAboveCommits = "S";
          moveDownCommit = "<c-j>";
          moveUpCommit = "<c-k>";
          amendToCommit = "A";
          pickCommit = "p";
          revertCommit = "t";
          cherryPickCopy = "c";
          cherryPickCopyRange = "C";
          pasteCommits = "v";
          tagCommit = "T";
          checkoutCommit = "<space>";
          resetCherryPick = "<c-R>";
          copyCommitHash = "y";
          openLogMenu = "<c-l>";
        };
        
        stash = {
          popStash = "g";
          renameStash = "r";
        };
        
        commitFiles = {
          checkoutCommitFile = "c";
        };
        
        main = {
          toggleSelectHunk = "a";
          pickBothHunks = "b";
        };
        
        submodules = {
          init = "i";
          update = "u";
          bulkMenu = "b";
        };
      };
      
      # Enhanced refresh settings
      refresher = {
        refreshInterval = 10;
        fetchInterval = 60;
      };
      
      # Update settings
      update = {
        method = "prompt";
        days = 14;
      };
      
      # Reporting and analytics
      reporting = "undetermined";
      
      # Disable update prompts in work environment
      disableStartupPopups = false;
      
      # Custom commands for workflow automation
      customCommands = [
        {
          key = "C";
          command = "git cz";
          description = "commit with commitizen";
          context = "files";
          loadingText = "opening commitizen commit tool";
          output = "terminal";
        }
        {
          key = "P";
          command = "git push --force-with-lease";
          description = "safe force push";
          context = "global";
          loadingText = "force pushing...";
        }
        {
          key = "<c-r>";
          command = "gh pr create --fill";
          description = "create PR";
          context = "global";
          loadingText = "creating PR...";
          output = "terminal";
        }
        {
          key = "<c-o>";
          command = "gh pr view --web";
          description = "open PR in browser";
          context = "global";
          loadingText = "opening PR...";
          output = "terminal";
        }
      ];
      
      # OS-specific settings
      os = {
        editPreset = "nvim";
        edit = "nvim {{filename}}";
        editAtLine = "nvim +{{line}} {{filename}}";
        editAtLineAndWait = "nvim +{{line}} {{filename}}";
        open = "open {{filename}}";
        openLink = "open {{link}}";
      };
    };
  };
}
