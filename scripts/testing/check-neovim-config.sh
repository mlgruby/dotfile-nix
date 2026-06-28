#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

pass() {
  printf '[PASS] %s\n' "$1"
}

rg -q 'enable = true;' home-manager/neovim.nix || fail 'Neovim is not enabled'
rg -q 'defaultEditor = true;' home-manager/neovim.nix || fail 'Neovim is not the default editor'
rg -q 'config/nvim' home-manager/neovim.nix || fail 'tracked config is not deployed'
test -f home-manager/config/nvim/init.lua || fail 'tracked init.lua is missing'
test -f home-manager/config/nvim/lazy-lock.json || fail 'tracked lazy-lock.json is missing'
test ! -e home-manager/scripts/install-lazyvim.sh || fail 'imperative bootstrap remains'

for extra in python rust go java kotlin nix docker terraform markdown yaml json; do
  rg -q "lazyvim.plugins.extras.lang.${extra}" home-manager/config/nvim/lazyvim.json \
    || fail "LazyVim extra missing: ${extra}"
done

for tool in pyright typescript-language-server rust-analyzer gopls jdt-language-server \
  kotlin-language-server nixd lua-language-server bash-language-server ruff shfmt stylua prettier; do
  rg -q "(^|[[:space:]])${tool}([[:space:]#]|$)" home-manager/modules/packages/languages.nix \
    || fail "declarative language tool missing: ${tool}"
done

pass 'Neovim configuration is declarative and covers audited project languages'
