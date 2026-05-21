# home-manager/modules/msgvault.nix
#
# Installs msgvault from the upstream GitHub release installer and provides
# remote command wrappers for the homelab LXC.
#
# msgvault is not available in our pinned nixpkgs today. The upstream installer
# downloads the latest wesm/msgvault release and verifies SHA256SUMS when the
# release provides them, so activation only runs it when the binary is missing.
{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}:
let
  homelab = import ../config/ssh.nix;
  remoteUrl = "http://${homelab.homelabHosts.msgvault}:8080";
  encryptedApiKey = "${config.home.homeDirectory}/${userConfig.directories.dotfiles}/home-manager/secrets/msgvault-api-key.age";
  identityFile = "${config.home.homeDirectory}/.ssh/nuc_homelab_id_ed25519";
in
{
  home.file.".local/bin/msgvault-remote" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      encrypted_key="${encryptedApiKey}"
      identity_file="${identityFile}"
      tmp_dir="$(mktemp -d)"
      tmp_config="$tmp_dir/config.toml"
      cleanup() {
        rm -rf "$tmp_dir"
      }
      trap cleanup EXIT INT TERM
      chmod 700 "$tmp_dir"

      if [ ! -r "$identity_file" ]; then
        echo "msgvault age identity not readable: $identity_file" >&2
        exit 1
      fi

      api_key="$(${pkgs.age}/bin/age --decrypt --identity "$identity_file" "$encrypted_key" | tr -d '\n')"

      {
        printf '%s\n' '[remote]'
        printf 'url = "%s"\n' '${remoteUrl}'
        printf 'api_key = "%s"\n' "$api_key"
        printf '%s\n' 'allow_insecure = true'
      } > "$tmp_config"
      chmod 600 "$tmp_config"

      if [ "$#" -eq 0 ]; then
        set -- tui
      fi

      exec msgvault --config "$tmp_config" "$@"
    '';
  };

  home.file.".local/bin/msgvault-api" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      method="''${1:-GET}"
      path="''${2:-/health}"
      if [ "$#" -ge 2 ]; then
        shift 2
      else
        set --
      fi

      encrypted_key="${encryptedApiKey}"
      identity_file="${identityFile}"

      if [ ! -r "$identity_file" ]; then
        echo "msgvault age identity not readable: $identity_file" >&2
        exit 1
      fi

      api_key="$(${pkgs.age}/bin/age --decrypt --identity "$identity_file" "$encrypted_key" | tr -d '\n')"

      exec ${pkgs.curl}/bin/curl -fsS \
        -X "$method" \
        -H "X-API-Key: $api_key" \
        '${remoteUrl}'"$path" \
        "$@"
    '';
  };

  home.file.".local/bin/msgvault-api-search" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      mode="''${1:-hybrid}"
      shift || true
      raw_json=false

      if [ "''${1:-}" = "--json" ]; then
        raw_json=true
        shift
      fi

      if [ "$#" -eq 0 ]; then
        echo "Usage: msgvault-api-search <fts|vector|hybrid> [--json] <query>" >&2
        exit 1
      fi

      query="$*"
      encoded_query="$(${pkgs.python3}/bin/python3 -c 'import sys, urllib.parse; print(urllib.parse.quote_plus(sys.argv[1]))' "$query")"
      page_size="''${MSGVAULT_SEARCH_PAGE_SIZE:-10}"
      response="$(msgvault-api GET "/api/v1/search?q=$encoded_query&mode=$mode&explain=1&page_size=$page_size")"

      if [ "$raw_json" = true ]; then
        printf '%s\n' "$response"
        exit 0
      fi

      printf '%s\n' "$response" | ${pkgs.jq}/bin/jq -r '
        def compact:
          tostring
          | gsub("[\r\n\t]+"; " ")
          | gsub(" +"; " ")
          | if length > 120 then .[0:117] + "..." else . end;

        def score_value($name):
          (.score[$name] // null)
          | if . == null then "-" else (. * 1000 | round / 1000 | tostring) end;

        def result_rows:
          (.results // .messages // [])
          | to_entries[]
          | .key as $index
          | .value as $message
          | "\($index + 1). [\($message.id)] \($message.sent_at[0:10] // "-") \($message.subject // "(no subject)" | compact)",
            "   from: \($message.from // "-")",
            "   score: rrf=\($message | score_value("rrf")) bm25=\($message | score_value("bm25")) vector=\($message | score_value("vector"))",
            (if ($message.snippet // "") != "" then "   \($message.snippet | compact)" else empty end);

        "query: \(.query // "")",
        "mode: \(.mode // "fts") | returned: \(.returned // .total // ((.results // .messages // []) | length)) | took: \(.took_ms // "-")ms | model: \(.generation.model // "-")",
        "",
        result_rows
      '
    '';
  };

  home.file.".local/bin/msgvault-pick" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      mode="hybrid"
      page_size="''${MSGVAULT_PICK_PAGE_SIZE:-50}"
      query_prefix=""
      account_filter=""

      while [ "$#" -gt 0 ]; do
        case "$1" in
          --semantic|--vector)
            mode="vector"
            shift
            ;;
          --fts|--keyword)
            mode="fts"
            shift
            ;;
          --hybrid)
            mode="hybrid"
            shift
            ;;
          -n|--limit)
            if [ -z "''${2:-}" ]; then
              echo "Usage: msgvault-pick [--hybrid|--semantic|--fts] [-n limit] <query>" >&2
              exit 1
            fi
            page_size="$2"
            shift 2
            ;;
          --query-prefix)
            if [ -z "''${2:-}" ]; then
              echo "Usage: msgvault-pick [--hybrid|--semantic|--fts] [-n limit] [--query-prefix text] [--account email] <query>" >&2
              exit 1
            fi
            query_prefix="$2"
            shift 2
            ;;
          --account)
            if [ -z "''${2:-}" ]; then
              echo "Usage: msgvault-pick [--hybrid|--semantic|--fts] [-n limit] [--query-prefix text] [--account email] <query>" >&2
              exit 1
            fi
            account_filter="$2"
            shift 2
            ;;
          --)
            shift
            break
            ;;
          -*)
            echo "Unknown option: $1" >&2
            echo "Usage: msgvault-pick [--hybrid|--semantic|--fts] [-n limit] [--query-prefix text] [--account email] <query>" >&2
            exit 1
            ;;
          *)
            break
            ;;
        esac
      done

      if [ "$#" -eq 0 ]; then
        echo "Usage: msgvault-pick [--hybrid|--semantic|--fts] [-n limit] [--query-prefix text] [--account email] <query>" >&2
        exit 1
      fi

      if ! command -v fzf >/dev/null 2>&1; then
        echo "fzf is required for msgvault-pick" >&2
        exit 1
      fi

      if [ -n "$query_prefix" ]; then
        query="$query_prefix $*"
      else
        query="$*"
      fi

      encoded_query="$(${pkgs.python3}/bin/python3 -c 'import sys, urllib.parse; print(urllib.parse.quote_plus(sys.argv[1]))' "$query")"
      response="$(msgvault-api GET "/api/v1/search?q=$encoded_query&mode=$mode&explain=1&page_size=$page_size")"

      selected="$(
        printf '%s\n' "$response" | ${pkgs.jq}/bin/jq -r --arg account_filter "$account_filter" '
          def compact:
            tostring
            | gsub("[\r\n\t]+"; " ")
            | gsub(" +"; " ")
            | if length > 100 then .[0:97] + "..." else . end;

          def score_value($name):
            (.score[$name] // null)
            | if . == null then "-" else (. * 1000 | round / 1000 | tostring) end;

          (.results // .messages // [])
          | map(select($account_filter == "" or ((.account // .account_email // .source // "") == $account_filter) or (((.to // []) + (.cc // []) + (.bcc // [])) | index($account_filter)) or ((.from // "") == $account_filter)))
          | .[]
          | [
              (.id | tostring),
              (.sent_at[0:10] // "-"),
              (.from // "-"),
              (.score.rrf // 0 | tostring),
              (.score.vector // 0 | tostring),
              (.subject // "(no subject)" | compact)
            ]
          | @tsv
        ' | fzf \
          --with-nth=2,3,6,4,5 \
          --delimiter='\t' \
          --header="msgvault $mode search: $query" \
          --preview='msgvault-remote show-message {1} | sed -n "1,120p"' \
          --preview-window=down:60%:wrap
      )"

      if [ -z "$selected" ]; then
        exit 0
      fi

      message_id="$(printf '%s\n' "$selected" | cut -f1)"
      exec msgvault-remote show-message "$message_id"
    '';
  };

  home.file.".local/bin/msgvault-pick-attachments" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      exec msgvault-pick --query-prefix "has:attachment" "$@"
    '';
  };

  home.file.".local/bin/msgvault-pick-account" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      if ! command -v fzf >/dev/null 2>&1; then
        echo "fzf is required for msgvault-pick-account" >&2
        exit 1
      fi

      if [ "$#" -eq 0 ]; then
        echo "Usage: msgvault-pick-account <query>" >&2
        exit 1
      fi

      selected_account="$(
        msgvault-remote list-accounts --json --log-level error \
          | ${pkgs.jq}/bin/jq -r '.[] | [.email, (.schedule // "-"), (.next_sync_at // "-")] | @tsv' \
          | fzf \
              --delimiter='\t' \
              --with-nth=1,2,3 \
              --header="pick msgvault account"
      )"

      if [ -z "$selected_account" ]; then
        exit 0
      fi

      account="$(printf '%s\n' "$selected_account" | cut -f1)"
      exec msgvault-pick --account "$account" "$@"
    '';
  };

  home.file.".local/bin/msgvault-api-key" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      ${pkgs.age}/bin/age --decrypt --identity "${identityFile}" "${encryptedApiKey}"
    '';
  };

  home.activation.installMsgvault = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    (
      export PATH="${config.home.homeDirectory}/.local/bin:${pkgs.curl}/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

      if command -v msgvault >/dev/null 2>&1; then
        echo "msgvault is already installed; skipping."
      elif ! command -v curl >/dev/null 2>&1; then
        echo "curl not found; skipping msgvault install."
      else
        tmp="$(mktemp)"
        trap 'rm -f "$tmp"' EXIT

        echo "Installing msgvault from upstream release installer..."
        if curl -fsSL https://msgvault.io/install.sh -o "$tmp"; then
          bash "$tmp" || echo "msgvault installer failed; run manually with: curl -fsSL https://msgvault.io/install.sh | bash"
        else
          echo "Could not download msgvault installer; skipping."
        fi
      fi
    )
  '';
}
