#!/usr/bin/env bash

tmux_status_collect_aws() {
  aws_profile="$(
    if command -v tmux >/dev/null 2>&1; then
      tmux show-environment -g AWS_PROFILE 2>/dev/null | sed 's/^AWS_PROFILE=//' || true
    fi
  )"
  [ -n "$aws_profile" ] || aws_profile="${AWS_PROFILE:-}"

  if [ -z "$aws_profile" ] && awk '/^\[default\]$/ { found=1 } END { exit found ? 0 : 1 }' "$HOME/.aws/credentials" 2>/dev/null; then
    aws_profile="default"
  fi

  aws_label=""
  aws_color="#83a598"
  case "$aws_profile" in
    production-sso|production|prod|prd)
      aws_label="PROD"
      aws_color="#fb4934"
      ;;
    default-sso|default|dev|develop|development|staging-sso|staging|stg)
      aws_label="DEV"
      aws_color="#83a598"
      ;;
    "")
      aws_label=""
      ;;
    *)
      aws_label="$aws_profile"
      aws_color="#928374"
      ;;
  esac

  aws_expiry="$(
    python3 - <<'PY' 2>/dev/null || true
import datetime as dt
import glob
import json
import os

now = dt.datetime.now(dt.timezone.utc)
expiries = []

for path in glob.glob(os.path.expanduser("~/.aws/sso/cache/*.json")):
    try:
        with open(path) as fh:
            data = json.load(fh)
    except Exception:
        continue

    if "startUrl" not in data:
        continue

    raw = data.get("expiresAt")
    if not raw:
        continue

    try:
        expires = dt.datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        continue

    expiries.append(expires)

if not expiries:
    raise SystemExit

remaining = int((max(expiries) - now).total_seconds() // 60)
if remaining <= 0:
    print("exp")
elif remaining < 60:
    print(f"{remaining}m")
else:
    hours, minutes = divmod(remaining, 60)
    print(f"{hours}h" if minutes < 10 else f"{hours}h{minutes}m")
PY
  )"

  aws_status=""
  if [ -n "$aws_label" ]; then
    aws_status="󰸏 $aws_label"
    [ -n "$aws_expiry" ] && aws_status="$aws_status $aws_expiry"
  fi

  if [ "$aws_expiry" = "exp" ]; then
    aws_color="#fb4934"
  elif [ -n "$aws_expiry" ] && [ "${aws_expiry%m}" != "$aws_expiry" ] && [ "${aws_expiry%m}" -le 60 ] 2>/dev/null; then
    aws_color="#fabd2f"
  fi
}
