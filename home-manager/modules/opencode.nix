# home-manager/modules/opencode.nix
#
# OpenCode LM Studio provider configuration.
#
# OpenCode and LM Studio are installed through Homebrew. This module
# intentionally skips configuration until both are present so rebuilds stay safe
# on machines that have not installed those tools yet.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  opencodeConfig = "${config.home.homeDirectory}/.config/opencode/opencode.json";
in
{
  home.activation.configureOpenCodeLMStudio = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! command -v opencode >/dev/null 2>&1 || [ ! -d "/Applications/LM Studio.app" ]; then
      echo "OpenCode/LM Studio not installed; skipping OpenCode LM Studio config."
      exit 0
    fi

    mkdir -p "$(dirname "${opencodeConfig}")"
    if [ ! -s "${opencodeConfig}" ]; then
      printf '%s\n' '{}' > "${opencodeConfig}"
    fi

    tmp="$(mktemp)"
    ${pkgs.jq}/bin/jq '
      ."$schema" = (.["$schema"] // "https://opencode.ai/config.json")
      | .provider.lmstudio = {
          "npm": "@ai-sdk/openai-compatible",
          "name": "LM Studio (local)",
          "options": {
            "baseURL": "http://localhost:1234/v1"
          },
          "models": {
            "google/gemma-4-26b-a4b": {
              "name": "Gemma 4 26B"
            }
          }
        }
      | .model = (.model // "lmstudio/google/gemma-4-26b-a4b")
    ' "${opencodeConfig}" > "$tmp"
    install -m 600 "$tmp" "${opencodeConfig}"
    rm -f "$tmp"
  '';
}
