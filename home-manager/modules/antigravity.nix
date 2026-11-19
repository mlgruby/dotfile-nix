# home-manager/modules/antigravity.nix
#
# Antigravity (Google) custom statusline configuration, and hooks that
# report the agent state to herdr-core (Herdr.app Agents list).
#
{
  config,
  lib,
  pkgs,
  ...
}:
let
  settingsFile = "${config.home.homeDirectory}/.gemini/antigravity-cli/settings.json";
  statuslinePath = "${config.home.homeDirectory}/.gemini/antigravity-cli/statusline.sh";
  hooksFile = "${config.home.homeDirectory}/.gemini/config/hooks.json";
  hcStatusPath = "${config.home.homeDirectory}/.gemini/config/hooks/hc-status.sh";
in
{
  programs.antigravity-cli.enable = true;

  home.file.".gemini/antigravity-cli/statusline.sh" = {
    source = ./antigravity/statusline.sh;
    executable = true;
  };

  home.file.".gemini/config/hooks/hc-status.sh" = {
    source = ./antigravity/hc-status.sh;
    executable = true;
  };

  home.activation.configureAntigravityStatusline = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$(dirname "${settingsFile}")"
    if [ ! -s "${settingsFile}" ]; then
      printf '%s\n' '{}' > "${settingsFile}"
    fi

    tmp="$(mktemp)"
    ${pkgs.jq}/bin/jq '
      .statusLine = {
        "type": "command",
        "command": "${statuslinePath}",
        "enabled": true
      }
    ' "${settingsFile}" > "$tmp"
    install -m 600 "$tmp" "${settingsFile}"
    rm -f "$tmp"
  '';

  # `herdr integration install` also writes hooks.json, so merge one named
  # group into it and keep the other groups.
  home.activation.configureAntigravityHcStatus = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$(dirname "${hooksFile}")"
    if [ ! -s "${hooksFile}" ]; then
      printf '%s\n' '{}' > "${hooksFile}"
    fi

    tmp="$(mktemp)"
    ${pkgs.jq}/bin/jq --arg h "${hcStatusPath}" '
      def hook(s): [{ type: "command", command: "sh \u0027\($h)\u0027 \(s)", timeout: 5 }];
      .["herdr-app"] = {
        SessionStart: hook("idle"),
        PreInvocation: hook("working"),
        PostInvocation: hook("idle")
      }
    ' "${hooksFile}" > "$tmp"
    install -m 644 "$tmp" "${hooksFile}"
    rm -f "$tmp"
  '';
}
