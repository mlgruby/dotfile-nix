# home-manager/modules/lazygit.nix
#
# LazyGit Configuration (Declarative)
#
# Purpose:
# - Sets up LazyGit defaults using programs.lazygit
# - Configures keybindings
#
# Integration:
# - Works with git.nix
# - Used by shell aliases

{ config, pkgs, ... }:

{
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        showFileTree = true;
        mouseEvents = true;
        showRandomTip = false;
        theme = {
          lightTheme = false;
          activeBorderColor = [ "green" "bold" ];
          inactiveBorderColor = [ "white" ];
          selectedLineBgColor = [ "blue" ];
        };
      };
      git = {
        autoFetch = true;
        autoRefresh = true;
        commitLength = {
          show = true;
        };
      };
      keybinding = {
        universal = {
          commitChanges = "C";
          pushFiles = "P";
          pullFiles = "p";
          refresh = "R";
          quit = "q";
        };
        commits = {
          copyCommitHash = "y";
        };
      };
    };
  };
}
