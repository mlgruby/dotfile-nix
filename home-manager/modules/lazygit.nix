# home-manager/modules/lazygit.nix
#
# LazyGit Configuration
#
# Purpose:
# - Sets up LazyGit defaults
# - Configures keybindings
#
# Integration:
# - Works with git.nix
# - Used by shell aliases

{ config, pkgs, ... }:

{
  home.file.".config/lazygit/config.yml".text = ''
    gui:
      # Show file tree
      showFileTree: true
      # Use mouse
      mouseEvents: true
      # Show commit hash in commits view
      showRandomTip: false
      # Theme
      theme:
        lightTheme: false
        activeBorderColor:
          - green
          - bold
        inactiveBorderColor:
          - white
        selectedLineBgColor:
          - blue
    git:
      # Auto fetch
      autoFetch: true
      # Auto refresh
      autoRefresh: true
      # Commit message length warning
      commitLength:
        show: true
    # Custom keybindings
    keybinding:
      universal:
        # Quick commit
        commitChanges: "C"
        # Quick push
        pushFiles: "P"
        # Quick pull
        pullFiles: "p"
        # Quick refresh
        refresh: "R"
        # Quick quit
        quit: "q"
      commits:
        # Copy commit hash
        copyCommitHash: "y"
  '';
} 