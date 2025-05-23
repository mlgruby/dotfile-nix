# home-manager/modules/github.nix
#
# GitHub CLI Configuration
#
# Purpose:
# - Sets up GitHub CLI aliases
# - Configures common workflows
#
# Aliases:
# - Pull Requests
# - Issues
# - Repositories
# - Workflows
#
# Integration:
# - Works with git.nix
# - Uses GitHub username from config
#
# Note:
# - Auth via 'gh auth login'
# - Additional git config in git.nix
{...}: {
  programs.gh = {
    enable = true;
    settings = {
      # Use SSH for better security and no password prompts
      git_protocol = "ssh";
      # Default editor for PR/Issue descriptions
      editor = "vim";
    };
  };

  # Custom GitHub Workflow Functions moved to zsh.nix

  # GitHub Command Aliases moved to aliases.nix
}
