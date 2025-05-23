{
  pkgs,
  userConfig,
  nixpkgsConfig,
  self,
  ...
}: {
  # Miscellaneous System Settings extracted from flake.nix inline module

  # System Version Management
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = 5; # Sets the state version

  # Nixpkgs Override (already partially defined in flake let block)
  # Consider merging this logic fully if needed.
  nixpkgs =
    nixpkgsConfig
    // {
      hostPlatform = "aarch64-darwin";
    };

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
