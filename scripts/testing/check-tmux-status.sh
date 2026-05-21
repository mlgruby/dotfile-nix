#!/usr/bin/env bash
#
# Tmux Status Guardrail
# Verifies the extracted tmux status modules stay syntactically valid and
# produce a non-empty tmux status string.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

HAS_FAILURES=0

pass() {
  printf '[PASS] %s\n' "$1"
}

fail() {
  printf '[FAIL] %s\n' "$1"
  HAS_FAILURES=1
}

status_dir="home-manager/scripts/tmux/status"

if [[ ! -d "$status_dir" ]]; then
  fail "missing tmux status directory: $status_dir"
else
  failed_syntax=0
  while IFS= read -r file; do
    if ! bash -n "$file"; then
      printf '[FAIL] bash syntax failed: %s\n' "$file"
      failed_syntax=1
    fi
  done < <(find "$status_dir" -type f -name '*.sh' | sort)

  if [[ "$failed_syntax" -eq 0 ]]; then
    pass "tmux status shell syntax passed"
  else
    HAS_FAILURES=1
  fi

  output="$(DOTFILES_TMUX_SHOW_AWS_VPN=yes bash "$status_dir/status-right.sh" 2>/dev/null || true)"
  if [[ -n "$output" && "$output" == *'#[default]'* ]]; then
    pass "tmux status renders a non-empty tmux string"
  else
    fail "tmux status did not render expected tmux markup"
  fi
fi

if [[ "$HAS_FAILURES" -eq 0 ]]; then
  pass "tmux status guardrail passed"
  exit 0
fi

fail "tmux status guardrail failed"
exit 1
