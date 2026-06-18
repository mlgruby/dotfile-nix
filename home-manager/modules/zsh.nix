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
let
  profile = import ../config/profile.nix { inherit userConfig; };
  sshDefaults = import ../config/ssh.nix;
  bitwardenAgent = sshDefaults.ssh.bitwardenAgent;
in
{
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      completionInit = ''
        source "${../scripts/zsh-completion-init.zsh}"
      '';
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
      }
      // lib.optionalAttrs bitwardenAgent.enable {
        DOTFILES_BITWARDEN_SSH_AGENT = "1";
        BITWARDEN_SSH_AUTH_SOCK = bitwardenAgent.socketPath;
      };

      initContent = ''
        ${lib.optionalString bitwardenAgent.enable ''
          export DOTFILES_BITWARDEN_SSH_AGENT="1"
          export BITWARDEN_SSH_AUTH_SOCK="${bitwardenAgent.socketPath}"
        ''}

        source "${../scripts/zsh-integration.zsh}"

        _dotfiles_run_rebuild() {
          DOTFILE_DIR="${config.home.homeDirectory}/${userConfig.directories.dotfiles}" \
          CURRENT_CONFIG_HOST="${userConfig.hostname}" \
          bash "${../scripts/rebuild-system.sh}" "$@" || return $?
        }

        rebuild() {
          _dotfiles_run_rebuild "$@"
        }

        rebuild-work() {
          rebuild --work "$@"
        }

        rebuild-personal() {
          rebuild --personal "$@"
        }

        update() {
          local dotfile_dir="${config.home.homeDirectory}/${userConfig.directories.dotfiles}"

          echo "Starting system update..."
          brew update || return $?
          brew upgrade || return $?

          cd "$dotfile_dir" || return $?
          nix flake update || return $?
          _dotfiles_run_rebuild "$@" || return $?

          echo "System update complete!"
        }
      ''
      + lib.optionalString profile.isWork ''
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
