# Declarative Neovim and LazyVim Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install Neovim and provide a reproducible, GitOps-managed LazyVim environment for the languages used in the work and personal project trees.

**Architecture:** Home Manager owns the executable, editor defaults, tooling, and every file beneath `~/.config/nvim`. A shell guardrail tests this contract; Nix evaluation, the existing rebuild wrapper, and headless Neovim provide progressively stronger verification. The module contains no Darwin-specific logic, but a Linux flake output remains out of scope.

**Tech Stack:** Nix, Home Manager, Neovim, LazyVim, lazy.nvim, Lua, Bash

---

## File Map

- Modify `home-manager/neovim.nix`: enable Neovim and deploy tracked configuration.
- Modify `home-manager/modules/packages/languages.nix`: install editor language tools.
- Delete `home-manager/scripts/install-lazyvim.sh`: remove imperative bootstrap.
- Create `home-manager/config/nvim/`: tracked LazyVim configuration and lock file.
- Create `scripts/testing/check-neovim-config.sh`: GitOps contract test.
- Modify `scripts/testing/onboarding-smoke.sh`: include the contract test.
- Modify `README.md`: document the declarative update workflow.

### Task 1: Add the failing GitOps contract

**Files:**
- Create: `scripts/testing/check-neovim-config.sh`
- Modify: `scripts/testing/onboarding-smoke.sh`

- [ ] **Step 1: Write the contract test**

Create `scripts/testing/check-neovim-config.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"
fail() { printf '[FAIL] %s\n' "$1" >&2; exit 1; }
pass() { printf '[PASS] %s\n' "$1"; }

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
```

- [ ] **Step 2: Add `bash scripts/testing/check-neovim-config.sh` beside the other guardrail calls in `scripts/testing/onboarding-smoke.sh`.**

- [ ] **Step 3: Verify red**

Run: `bash scripts/testing/check-neovim-config.sh`

Expected: exit 1 with `[FAIL] Neovim is not enabled`.

- [ ] **Step 4: Commit the red test**

```bash
git add scripts/testing/check-neovim-config.sh scripts/testing/onboarding-smoke.sh
git commit -m "test: define declarative Neovim contract"
```

### Task 2: Make Neovim and LazyVim repository-owned

**Files:**
- Modify: `home-manager/neovim.nix`
- Delete: `home-manager/scripts/install-lazyvim.sh`
- Create: `home-manager/config/nvim/init.lua`
- Create: `home-manager/config/nvim/lua/config/{lazy,options,keymaps,autocmds}.lua`
- Create: `home-manager/config/nvim/lua/plugins/languages.lua`
- Create: `home-manager/config/nvim/{lazyvim.json,lazy-lock.json,stylua.toml}`

- [ ] **Step 1: Replace `home-manager/neovim.nix`**

```nix
{ ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
  xdg.configFile."nvim" = {
    source = ./config/nvim;
    recursive = true;
  };
}
```

- [ ] **Step 2: Delete `home-manager/scripts/install-lazyvim.sh`; create `init.lua` containing `require("config.lazy")`.**

- [ ] **Step 3: Copy the audited `~/.config/nvim/lua/config/lazy.lua` into the tracked tree. It must load LazyVim followed by `{ import = "plugins" }`. Create tracked `options.lua`, `keymaps.lua`, and `autocmds.lua` containing comments that mark them as repository-owned extension points.**

- [ ] **Step 4: Create `lazyvim.json` with audited language extras**

```json
{
  "extras": [
    "lazyvim.plugins.extras.lang.docker",
    "lazyvim.plugins.extras.lang.go",
    "lazyvim.plugins.extras.lang.java",
    "lazyvim.plugins.extras.lang.json",
    "lazyvim.plugins.extras.lang.kotlin",
    "lazyvim.plugins.extras.lang.markdown",
    "lazyvim.plugins.extras.lang.nix",
    "lazyvim.plugins.extras.lang.python",
    "lazyvim.plugins.extras.lang.rust",
    "lazyvim.plugins.extras.lang.terraform",
    "lazyvim.plugins.extras.lang.yaml"
  ],
  "install_version": 8,
  "news": { "NEWS.md": "11866" },
  "version": 8
}
```

- [ ] **Step 5: Create `lua/plugins/languages.lua` for the Nix-owned TypeScript server**

```lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = { mason = false },
        ts_ls = { mason = false },
      },
    },
  },
}
```

- [ ] **Step 6: Create `stylua.toml`**

```toml
indent_type = "Spaces"
indent_width = 2
column_width = 120
```

- [ ] **Step 7: Copy the audited lock file into Git ownership**

Run: `cp ~/.config/nvim/lazy-lock.json home-manager/config/nvim/lazy-lock.json`

Do not run `:Lazy update` against the live configuration.

- [ ] **Step 8: Run the contract**

Run: `bash scripts/testing/check-neovim-config.sh`

Expected: exit 1 naming the first missing declarative language tool.

- [ ] **Step 9: Commit repository ownership**

```bash
git add home-manager/neovim.nix home-manager/config/nvim home-manager/scripts/install-lazyvim.sh
git commit -m "feat: manage Neovim and LazyVim declaratively"
```

### Task 3: Add the language toolchain

**Files:**
- Modify: `home-manager/modules/packages/languages.nix`

- [ ] **Step 1: Add these packages to the existing `home.packages` list**

```nix
    # Neovim language servers
    gopls
    jdt-language-server
    nixd
    lua-language-server
    nodePackages.bash-language-server
    yaml-language-server
    nodePackages.vscode-langservers-extracted
    nodePackages.dockerfile-language-server-nodejs
    terraform-ls
    marksman

    # Neovim formatters and linters
    ruff
    shfmt
    stylua
    nodePackages.prettier
    gofumpt
    hadolint
    ktlint
```

Retain existing `pyright`, `typescript-language-server`, `rust-analyzer`,
`kotlin-language-server`, `rustfmt`, and `shellcheck` entries.

- [ ] **Step 2: Verify green contract**

Run: `bash scripts/testing/check-neovim-config.sh`

Expected: exit 0 with the `[PASS]` message.

- [ ] **Step 3: Evaluate the target**

```bash
env XDG_CACHE_HOME=/tmp/codex-nix-cache nix eval \
  '.#darwinConfigurations.satya-wmbp.config.home-manager.users.satyasheel.programs.neovim.enable'
```

Expected: `true`. If nixpkgs reports an unknown package attribute, replace only
that entry with the current attribute providing the same executable and rerun.

- [ ] **Step 4: Verify formatting and repository guardrails**

```bash
nix run nixpkgs#nixfmt -- --check home-manager/neovim.nix home-manager/modules/packages/languages.nix
bash scripts/testing/check-package-ownership.sh
bash scripts/testing/onboarding-smoke.sh
git diff --check
```

Expected: every command exits 0.

- [ ] **Step 5: Commit language support**

```bash
git add home-manager/modules/packages/languages.nix
git commit -m "feat: add Neovim language tooling"
```

### Task 4: Document the GitOps update path

**Files:**
- Modify: `README.md:470-474`

- [ ] **Step 1: Replace the mutable Neovim note**

```markdown
- **Neovim:** Home Manager installs Neovim and deploys the LazyVim configuration
  from `home-manager/config/nvim`. This repository is the source of truth; do not
  edit `~/.config/nvim` or run unrecorded plugin updates there. Update the tracked
  `lazy-lock.json`, review its diff, run the Neovim contract test, and deploy via
  `rebuild`.
```

- [ ] **Step 2: Verify docs**

```bash
bash scripts/testing/check-docs-stale-patterns.sh
git diff --check
```

Expected: both commands exit 0.

- [ ] **Step 3: Commit documentation**

```bash
git add README.md
git commit -m "docs: document Neovim GitOps workflow"
```

### Task 5: Deploy and verify the real editor

**Files:** Verification only; never edit `~/.config/nvim` manually.

- [ ] **Step 1: Reconfirm the original red signal**

Run: `command -v nvim`

Expected before deployment: non-zero exit.

- [ ] **Step 2: Deploy through GitOps**

Run: `rebuild --work`

Expected: exit 0 ending with `System rebuild complete for: satya-wmbp`.

- [ ] **Step 3: Verify executable and deployed ownership**

```bash
command -v nvim
nvim --version | head -n 3
readlink ~/.config/nvim/init.lua
```

Expected: the binary resolves through the active Nix profile and `init.lua`
resolves to a Nix store path.

- [ ] **Step 4: Bootstrap and inspect pinned plugins**

```bash
nvim --headless '+Lazy! sync' +qa
nvim --headless "+lua for name, plugin in pairs(require('lazy.core.config').plugins) do if plugin._.installed == false then error('plugin not installed: ' .. name) end end" +qa
```

Expected: both commands exit 0 with no Lua traceback.

- [ ] **Step 5: Verify representative tools**

```bash
for tool in pyright-langserver typescript-language-server rust-analyzer gopls \
  jdtls kotlin-language-server nixd lua-language-server bash-language-server \
  ruff shfmt stylua prettier; do
  command -v "$tool" || exit 1
done
```

Expected: every executable resolves.

- [ ] **Step 6: Capture health**

```bash
nvim --headless '+checkhealth' '+silent write! /tmp/neovim-checkhealth.txt' +qa
rg -n 'ERROR|WARNING' /tmp/neovim-checkhealth.txt || true
```

Expected: no `ERROR` lines. Report any optional provider warnings.

- [ ] **Step 7: Run final verification**

```bash
bash scripts/testing/check-neovim-config.sh
bash scripts/testing/check-package-ownership.sh
bash scripts/testing/onboarding-smoke.sh
git diff --check
git status --short
```

Expected: checks exit 0 and status contains no unexplained generated files.

- [ ] **Step 8: Commit only tracked corrections discovered during verification**

```bash
git add home-manager/neovim.nix home-manager/config/nvim home-manager/modules/packages/languages.nix README.md scripts/testing
git commit -m "fix: complete Neovim verification"
```

Skip this commit if verification required no correction.
