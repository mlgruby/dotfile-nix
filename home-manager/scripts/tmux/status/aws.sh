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
    root-sso|root|vortexa-sso|vortexa)
      aws_label="ROOT"
      aws_color="#d3869b"
      ;;
    "")
      aws_label=""
      ;;
    *)
      aws_label="$aws_profile"
      aws_color="#928374"
      ;;
  esac

  aws_expiry=""
  if [ -n "$aws_label" ]; then
    local expiry_cache="${TMPDIR:-/tmp}/tmux_aws_expiry_${UID:-0}_${aws_label}.cache"
    if declare -F tmux_status_cache_fresh >/dev/null 2>&1 && tmux_status_cache_fresh "$expiry_cache" 15; then
      IFS= read -r aws_expiry < "$expiry_cache" 2>/dev/null || true
    else
      aws_expiry="$(
        jq -rn --argjson now "$(date +%s)" '
          [ inputs
            | select(.startUrl != null and .expiresAt != null)
            | (.expiresAt | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601)
          ]
          | if length == 0 then empty
            else
              ((max - $now) / 60 | floor) as $rem
              | if $rem <= 0 then "exp"
                elif $rem < 60 then "\($rem)m"
                else
                  (($rem / 60 | floor)) as $h
                  | (($rem % 60)) as $m
                  | if $m < 10 then "\($h)h" else "\($h)h\($m)m" end
                end
            end
        ' "$HOME"/.aws/sso/cache/*.json 2>/dev/null || true
      )"
      printf '%s\n' "$aws_expiry" > "$expiry_cache" 2>/dev/null || true
    fi
  fi

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
