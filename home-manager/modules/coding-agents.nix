# home-manager/modules/coding-agents.nix
#
# Coding agent CLI installers.
#
# This module is the declaration for vendor-installed coding agents that are not
# owned by Homebrew or Nixpkgs. Each enabled agent is installed via its official
# install script/package manager. Guards avoid unnecessary reinstalls.
# Configuration for each agent lives in its own module (opencode.nix, pi.nix, etc).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  enabledAgents = import ../config/coding-agents.nix;
  enabledAgentsString = lib.concatStringsSep " " enabledAgents;
  npm = "/opt/homebrew/bin/npm";
  localBin = "${config.home.homeDirectory}/.local/bin";
  opencodeBin = "${config.home.homeDirectory}/.opencode/bin";
  stateFile = "${config.xdg.stateHome}/dotfiles/coding-agents";
  installerPath = lib.makeBinPath [
    pkgs.curl
    pkgs.gnutar
    pkgs.perl
    pkgs.unzip
  ];
in
{
  home.activation.installCodingAgents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    (
      # Keep the installer PATH scoped to this activation step. Leaking it can
      # make later Home Manager steps resolve incompatible macOS system tools.
      export PATH="${localBin}:${opencodeBin}:/opt/homebrew/bin:${installerPath}:$PATH"

      enabled_agents="${enabledAgentsString}"
      previous_agents=""
      if [ -f "${stateFile}" ]; then
        previous_agents="$(cat "${stateFile}")"
      fi

      agent_enabled() {
        case " $enabled_agents " in
          *" $1 "*) return 0 ;;
          *) return 1 ;;
        esac
      }

      agent_was_managed() {
        printf '%s\n' "$previous_agents" | grep -Fxq "$1"
      }

      # Remove only vendor-managed binaries for agents that were previously
      # declared here. User configuration and session data are preserved.
      for agent in claude opencode codex pi antigravity; do
        if ! agent_enabled "$agent" && agent_was_managed "$agent"; then
          case "$agent" in
            claude)
              rm -f "${localBin}/claude"
              rm -rf "$HOME/.local/share/claude"
              ;;
            opencode)
              rm -rf "$HOME/.opencode"
              ;;
            codex)
              rm -f "${localBin}/codex"
              rm -rf "$HOME/.codex/packages/standalone"
              ;;
            pi)
              ${npm} uninstall -g @earendil-works/pi-coding-agent || \
                echo "Warning: failed to uninstall Pi coding agent." >&2
              ;;
            antigravity)
              rm -f "${localBin}/agy"
              ;;
          esac
        fi
      done

      # Claude Code
      if agent_enabled claude && ! command -v claude >/dev/null 2>&1; then
        if ! ${pkgs.curl}/bin/curl -fsSL https://claude.ai/install.sh | bash; then
          echo "Warning: failed to install Claude Code." >&2
        fi
      fi

      # OpenCode
      if agent_enabled opencode && ! command -v opencode >/dev/null 2>&1; then
        if ! ${pkgs.curl}/bin/curl -fsSL https://opencode.ai/install | bash; then
          echo "Warning: failed to install OpenCode." >&2
        fi
      fi

      # Codex (OpenAI)
      if agent_enabled codex && ! command -v codex >/dev/null 2>&1; then
        if ! ${pkgs.curl}/bin/curl -fsSL https://chatgpt.com/codex/install.sh | sh; then
          echo "Warning: failed to install Codex." >&2
        fi
      fi

      # Pi coding agent (binary: pi)
      if agent_enabled pi && ! command -v pi >/dev/null 2>&1; then
        if ! ${npm} install -g --ignore-scripts @earendil-works/pi-coding-agent; then
          echo "Warning: failed to install Pi coding agent." >&2
        fi
      fi

      # Antigravity (Google) — binary is 'agy'
      if agent_enabled antigravity && ! command -v agy >/dev/null 2>&1; then
        if ! ${pkgs.curl}/bin/curl -fsSL https://antigravity.google/cli/install.sh | bash; then
          echo "Warning: failed to install Antigravity." >&2
        fi
      fi

      mkdir -p "$(dirname "${stateFile}")"
      printf '%s\n' ${lib.concatMapStringsSep " " lib.escapeShellArg enabledAgents} > "${stateFile}"
    )
  '';
}
