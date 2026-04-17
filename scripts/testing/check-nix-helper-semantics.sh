#!/usr/bin/env bash
#
# Nix Helper Semantics Guardrail
# Validates small local helper modules whose behavior is easy to regress during
# refactors.

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

info() {
  printf '[INFO] %s\n' "$1"
}

check_eval_ok() {
  local label="$1"
  local expr="$2"

  if nix eval --impure --raw --expr "$expr" >/dev/null; then
    pass "$label"
  else
    fail "$label"
  fi
}

info "checking local Nix helper semantics"

check_eval_ok \
  "Homebrew composeList preserves order, removes duplicates, and applies removals" \
  'let
     lib = import ./darwin/lib/homebrew.nix;
     actual = lib.composeList [ "a" "b" "a" ] [ "c" "b" ] [ "a" ];
   in
   if actual == [ "b" "c" ] then "ok" else throw "unexpected composeList result"'

check_eval_ok \
  "Homebrew profile helper provides empty defaults" \
  'let
     profile = (import ./darwin/profiles/lib.nix).mkProfile { };
     expected = {
       extraTaps = [ ];
       extraBrews = [ ];
       extraCasks = [ ];
       removeTaps = [ ];
       removeBrews = [ ];
       removeCasks = [ ];
       masApps = { };
     };
   in
   if profile == expected then "ok" else throw "unexpected mkProfile defaults"'

check_eval_ok \
  "Homebrew profile helper preserves explicit overrides" \
  'let
     profile = (import ./darwin/profiles/lib.nix).mkProfile {
       extraCasks = [ "example-app" ];
       removeBrews = [ "example-brew" ];
       masApps = { Example = 123; };
     };
   in
   if profile.extraCasks == [ "example-app" ]
      && profile.removeBrews == [ "example-brew" ]
      && profile.masApps.Example == 123
   then "ok"
   else throw "unexpected mkProfile override result"'

if [[ "$HAS_FAILURES" -eq 0 ]]; then
  pass "local Nix helper semantics passed"
  exit 0
fi

fail "local Nix helper semantics failed"
exit 1
