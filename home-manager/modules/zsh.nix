# home-manager/modules/zsh.nix
#
# Zsh shell configuration. Interactive shell helpers live in
# ../scripts/zsh-integration.zsh so this module stays focused on Home Manager
# options.
{
  config,
  lib,
  userConfig,
  ...
}:
{
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      # Explicitly set dotDir to lock in current behavior (home directory).
      dotDir = "/Users/${config.home.username}";

      sessionVariables = {
        NIX_PATH = "$HOME/.nix-defexpr/channels:$NIX_PATH";
        FPATH = "$HOME/.zsh/completion:$FPATH";
        PYTHON_CONFIGURE_OPTS = "--enable-framework";
        UV_PYTHON_PREFERENCE = "system";
        CARGO_HOME = "$HOME/.cargo";
        RUSTUP_HOME = "$HOME/.rustup";
        PATH = "$HOME/.local/bin:$HOME/.docker/bin:$HOME/.cargo/bin:/Library/TeX/texbin:/opt/homebrew/opt/gnu-getopt/bin:/opt/homebrew/opt/python@3.12/libexec/bin:$HOME/bin:$PATH";
      };

      initContent = ''
        source "${../scripts/zsh-integration.zsh}"
      ''
      + lib.optionalString (userConfig.profile == "work") ''
        source "${../scripts/work.zsh}"
      '';

      history = {
        size = 50000;
        save = 50000;
        share = true;
        ignoreDups = true;
        ignoreSpace = true;
        expireDuplicatesFirst = true;
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  home = {
    enableNixpkgsReleaseCheck = false;
  };
}
