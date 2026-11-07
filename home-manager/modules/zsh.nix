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
  profile = config.homelab.profile;
  bitwardenAgent = config.programs.ssh.custom.bitwardenAgent;
  # Bitwarden binds the env var value verbatim, so expand a leading "~" to $HOME.
  bitwardenSocketEnv =
    if lib.hasPrefix "~/" bitwardenAgent.socketPath then
      "$HOME/${lib.removePrefix "~/" bitwardenAgent.socketPath}"
    else
      bitwardenAgent.socketPath;
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
        UV_PYTHON_PREFERENCE = "managed";
        CARGO_HOME = "$HOME/.cargo";
        RUSTUP_HOME = "$HOME/.rustup";
      }
      // lib.optionalAttrs bitwardenAgent.enable {
        DOTFILES_BITWARDEN_SSH_AGENT = "1";
        BITWARDEN_SSH_AUTH_SOCK = bitwardenSocketEnv;
      };

      initContent = ''
        # Deduplicate PATH entries automatically in Zsh
        typeset -U path PATH

        # Ensure complete PATH including Nix profiles and standard macOS system bins
        export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.docker/bin:$HOME/.cargo/bin:$HOME/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

        ${lib.optionalString bitwardenAgent.enable ''
          export DOTFILES_BITWARDEN_SSH_AGENT="1"
          export BITWARDEN_SSH_AUTH_SOCK="${bitwardenSocketEnv}"
        ''}

        source "${../scripts/zsh-integration.zsh}"

        ${lib.optionalString profile.isWork ''
          # Optional devcontainer-auto integration for the Work profile. The
          # hook is installed outside this repository and should not make shell
          # startup fail when absent.
          if [ -r "$HOME/.config/devcontainer-auto/zsh-hook" ]; then
            source "$HOME/.config/devcontainer-auto/zsh-hook"
          fi
        ''}

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
          DOTFILE_DIR="${config.home.homeDirectory}/${userConfig.directories.dotfiles}" \
          CURRENT_CONFIG_HOST="${userConfig.hostname}" \
          bash "${../scripts/update-system.sh}" "$@"
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
