{
  pkgs,
  userConfig,
  self,
  ...
}:
{
  # Miscellaneous System Settings extracted from flake.nix inline module

  # System revision metadata. The compatibility state version is owned by
  # darwin/configuration.nix.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Security Settings (Placeholder if needed later)

  # Shell Configuration (System-level ZSH enablement)
  # Disable nix-darwin's system-wide compinit/bashcompinit in /etc/zshrc because
  # Home Manager already initializes cached Zsh completions (~/.zcompdump) via
  # home-manager/scripts/zsh-completion-init.zsh. Running compinit twice adds
  # ~150ms of uncached startup latency to every interactive Zsh session.
  programs.zsh = {
    enable = true; # Ensures zsh is available system-wide
    enableCompletion = false; # Managed by Home Manager with ~/.zcompdump caching
    enableBashCompletion = false;
    promptInit = ""; # Avoid conflicting with Starship/HM prompt
  };

  # User Account Setup (System-level shell assignment)
  users.users.${userConfig.username} = {
    home = "/Users/${userConfig.username}"; # Standard home dir
    shell = "${pkgs.zsh}/bin/zsh"; # Set default shell to Nix Zsh
  };
}
