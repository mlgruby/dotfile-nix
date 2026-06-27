# home-manager/modules/antigravity.nix
#
# Antigravity (Google) custom statusline configuration.
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
in
{
  home.file.".gemini/antigravity-cli/statusline.sh" = {
    source = ./antigravity/statusline.sh;
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
}
