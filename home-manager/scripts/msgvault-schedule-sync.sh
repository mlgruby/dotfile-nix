#!/usr/bin/env bash
set -euo pipefail

remote_host="${MSGVAULT_REMOTE_HOST:-msgvault}"
remote_config="${MSGVAULT_REMOTE_CONFIG:-/root/.msgvault/config.toml}"
remote_service="${MSGVAULT_REMOTE_SERVICE:-msgvault.service}"
sync_service="${MSGVAULT_SYNC_SERVICE:-msgvault-sync.service}"
sync_timer="${MSGVAULT_SYNC_TIMER:-msgvault-sync.timer}"
systemd_calendar="${1:-*-*-* 00/6:00:00}"

ssh "$remote_host" \
  "MSGVAULT_CONFIG='$remote_config' MSGVAULT_SERVICE='$remote_service' MSGVAULT_SYNC_SERVICE='$sync_service' MSGVAULT_SYNC_TIMER='$sync_timer' MSGVAULT_SYSTEMD_CALENDAR='$systemd_calendar' python3 -" <<'PY'
import os
import pathlib
import subprocess
import sys

config_path = pathlib.Path(os.environ.get("MSGVAULT_CONFIG", "/root/.msgvault/config.toml"))
serve_service = os.environ.get("MSGVAULT_SERVICE", "msgvault.service")
sync_service = os.environ.get("MSGVAULT_SYNC_SERVICE", "msgvault-sync.service")
sync_timer = os.environ.get("MSGVAULT_SYNC_TIMER", "msgvault-sync.timer")
calendar = os.environ.get("MSGVAULT_SYSTEMD_CALENDAR", "*-*-* 00/6:00:00")

if not config_path.exists():
    print(f"msgvault config not found: {config_path}", file=sys.stderr)
    sys.exit(1)

backup_path = config_path.with_suffix(config_path.suffix + ".bak-before-systemd-sync")
backup_path.write_text(config_path.read_text())
backup_path.chmod(0o600)

# The built-in msgvault serve scheduler currently resolves configured accounts
# through the OAuth path. This machine uses IMAP token files, so schedule
# `msgvault sync` with systemd instead and keep `serve` focused on the API.
lines = config_path.read_text().splitlines()
kept = []
in_accounts = False
for line in lines:
    stripped = line.strip()
    if stripped == "[[accounts]]":
        in_accounts = True
        continue
    if in_accounts and stripped.startswith("[") and stripped != "[[accounts]]":
        in_accounts = False
    if not in_accounts:
        kept.append(line)

while kept and kept[-1] == "":
    kept.pop()

config_path.write_text("\n".join(kept).rstrip() + "\n")
config_path.chmod(0o600)

service_path = pathlib.Path("/etc/systemd/system") / sync_service
timer_path = pathlib.Path("/etc/systemd/system") / sync_timer

service_path.write_text(
    f"""[Unit]
Description=msgvault scheduled mailbox sync
After=network-online.target {serve_service}
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/msgvault sync --config {config_path} --log-level info
"""
)

timer_path.write_text(
    f"""[Unit]
Description=Run msgvault mailbox sync

[Timer]
OnCalendar={calendar}
Persistent=true
RandomizedDelaySec=15m

[Install]
WantedBy=timers.target
"""
)

subprocess.run(["systemctl", "daemon-reload"], check=True)
subprocess.run(["systemctl", "restart", serve_service], check=True)
subprocess.run(["systemctl", "enable", "--now", sync_timer], check=True)
subprocess.run(["systemctl", "list-timers", sync_timer, "--no-pager"], check=False)
print(f"Configured {sync_timer} with OnCalendar={calendar}")
PY
