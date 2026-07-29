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
  # ZSH setup and environment
  programs.zsh = {
    enable = true; # Ensures zsh is available system-wide
    enableCompletion = true; # System-wide completion (HM also manages this)
    promptInit = ""; # Avoid conflicting with Starship/HM prompt
  };

  # User Account Setup (System-level shell assignment)
  users.users.${userConfig.username} = {
    home = "/Users/${userConfig.username}"; # Standard home dir
    shell = "${pkgs.zsh}/bin/zsh"; # Set default shell to Nix Zsh
  };
}
