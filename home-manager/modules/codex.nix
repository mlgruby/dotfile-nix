# home-manager/modules/codex.nix
#
# Codex (OpenAI) Configuration
#
# Purpose:
# - Configures Codex CLI native status line
# - Scopes configuration to ~/.codex/config.toml
#
{
  config,
  lib,
  pkgs,
  ...
}:
let
  codexConfig = "${config.home.homeDirectory}/.codex/config.toml";
in
{
  home.activation.configureCodexStatusline = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$(dirname "${codexConfig}")"
    if [ ! -s "${codexConfig}" ]; then
      printf '%s\n' "" > "${codexConfig}"
    fi

    # We use a simple Python script to update the [tui] status_line key in config.toml
    # python3 is guaranteed to be present and has the built-in libraries.
    ${pkgs.python3}/bin/python3 -c '
import re
import os

path = os.path.expanduser("${codexConfig}")
with open(path, "r") as f:
    content = f.read()

# Check if [tui] block exists
if "[tui]" in content:
    # Check if status_line is already defined inside [tui]
    parts = content.split("[tui]")
    tui_part = re.split(r"\n\s*\[", parts[1])[0]
    if "status_line" in tui_part:
        new_tui_part = re.sub(
            r"status_line\s*=.*",
            "status_line = [\"model\", \"token-usage\", \"branch\", \"current-dir\"]",
            tui_part
        )
        content = content.replace(tui_part, new_tui_part)
    else:
        content = content.replace("[tui]", "[tui]\nstatus_line = [\"model\", \"token-usage\", \"branch\", \"current-dir\"]")
else:
    content += "\n[tui]\nstatus_line = [\"model\", \"token-usage\", \"branch\", \"current-dir\"]\n"

with open(path, "w") as f:
    f.write(content)
'
  '';
}
