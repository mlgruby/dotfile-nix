#!/usr/bin/env bash
set -euo pipefail

dotfile_dir="${DOTFILE_DIR:-$HOME/Documents/dotfile}"
recipient_file="${MSGVAULT_AGE_RECIPIENT:-$HOME/.ssh/nuc_homelab_id_ed25519.pub}"
secret_file="$dotfile_dir/home-manager/secrets/msgvault-api-key.age"
remote_host="${MSGVAULT_REMOTE_HOST:-msgvault}"
remote_config="${MSGVAULT_REMOTE_CONFIG:-/root/.msgvault/config.toml}"
remote_service="${MSGVAULT_REMOTE_SERVICE:-msgvault.service}"
print_key=false

if [ "${1:-}" = "--print" ]; then
  print_key=true
fi

if [ ! -r "$recipient_file" ]; then
  echo "Recipient public key not readable: $recipient_file" >&2
  exit 1
fi

mkdir -p "$(dirname "$secret_file")"

new_key="$(openssl rand -base64 48)"
recipient="$(cat "$recipient_file")"
printf '%s' "$new_key" | age -a -r "$recipient" -o "$secret_file"

if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "$new_key" | pbcopy
  copied_message="Copied new API key to clipboard."
else
  copied_message="Clipboard unavailable. Run 'mvkey' to print the current key."
fi

remote_message="Remote LXC update was not attempted."
if command -v ssh >/dev/null 2>&1; then
  if remote_output="$(
    ssh "$remote_host" \
      "MSGVAULT_CONFIG='$remote_config' MSGVAULT_SERVICE='$remote_service' sh -s" <<EOF
set -eu
new_key=\$(cat <<'KEY'
$new_key
KEY
)

config="\${MSGVAULT_CONFIG:-/root/.msgvault/config.toml}"
service="\${MSGVAULT_SERVICE:-msgvault.service}"
mkdir -p "\$(dirname "\$config")"

if [ ! -f "\$config" ]; then
  {
    printf '%s\n' '[server]'
    printf 'api_key = "%s"\n' "\$new_key"
  } > "\$config"
  chmod 600 "\$config"
else
  tmp="\$(mktemp)"
  awk -v key="\$new_key" '
    BEGIN { in_server = 0; seen_server = 0; wrote_key = 0 }
    /^\[[^]]+\]/ {
      if (in_server && !wrote_key) {
        print "api_key = \"" key "\""
        wrote_key = 1
      }
      in_server = (\$0 == "[server]")
      if (in_server) {
        seen_server = 1
      }
      print
      next
    }
    in_server && /^[[:space:]]*api_key[[:space:]]*=/ {
      print "api_key = \"" key "\""
      wrote_key = 1
      next
    }
    { print }
    END {
      if (in_server && !wrote_key) {
        print "api_key = \"" key "\""
      }
      if (!seen_server) {
        print ""
        print "[server]"
        print "api_key = \"" key "\""
      }
    }
  ' "\$config" > "\$tmp"
  install -m 600 "\$tmp" "\$config"
  rm -f "\$tmp"
fi

if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files "\$service" >/dev/null 2>&1; then
  systemctl restart "\$service"
  printf 'Updated %s and restarted %s\n' "\$config" "\$service"
else
  printf 'Updated %s; restart msgvault manually\n' "\$config"
fi
EOF
  )"
  then
    if remote_key="$(
      ssh "$remote_host" \
        "MSGVAULT_CONFIG='$remote_config' sh -s" <<'EOF'
set -eu
config="${MSGVAULT_CONFIG:-/root/.msgvault/config.toml}"
awk -F'"' '
  /^\[server\]/ { in_server = 1; next }
  /^\[[^]]+\]/ { in_server = 0; next }
  in_server && /^[[:space:]]*api_key[[:space:]]*=/ { print $2; exit }
' "$config"
EOF
    )" && [ "$remote_key" = "$new_key" ]; then
      remote_message="$remote_host: $remote_output"
    else
      remote_message="$remote_host: updated config, but could not verify the remote [server] api_key. Run 'mvkey' and compare it with $remote_config."
    fi
    unset remote_key
  else
    remote_message="Could not update $remote_host automatically. Run 'mvkey' and update $remote_config manually."
  fi
else
  remote_message="ssh not found. Run 'mvkey' and update $remote_config manually."
fi

cat <<EOF
Rotated msgvault API key.

Encrypted repo file:
  $secret_file

$copied_message

$remote_message

Commit the updated .age file after verifying mvt works.
EOF

if [ "$print_key" = true ]; then
  printf '\nNew API key:\n  %s\n' "$new_key"
fi
