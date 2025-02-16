# home-manager/modules/lazygit.nix
#
# LazyGit Terminal UI Configuration
#
# Purpose:
# - Configures LazyGit, a simple terminal UI for git commands
# - Provides custom keybindings for common git operations
# - Sets up theme and UI preferences
#
# Features:
# - File Tree: Visual directory structure
# - Auto Operations:
#   - Auto fetch for remote updates
#   - Auto refresh for real-time status
# - Custom Keybindings:
#   - C: Quick commit
#   - P: Push changes
#   - p: Pull changes
#   - R: Refresh view
#   - q: Quit
#   - y: Copy commit hash
#
# Theme:
# - Dark theme optimized for terminal use
# - Color-coded borders for active/inactive panels
# - Blue highlighting for selected items
#
# Integration:
# - Works with aliases defined in aliases.nix
# - Complements git configuration in git.nix

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