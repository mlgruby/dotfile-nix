# AI Agent Skills & Plugins Management

This document describes how upstream AI agent skills and plugins are declaratively pinned, built, and deployed across **Claude Code**, **Google Antigravity**, and shared `~/.agents` directories.

---

## Architecture Overview

To keep the root `flake.lock` clean while still version-pinning third-party skill repositories, all external agent skill and plugin inputs live in a dedicated child flake:

```text
dotfile/
├── flake.nix                            # Imports ./home-manager/agent-extras as input `agent-extras`
├── flake.lock                           # Locks `agent-extras`
└── home-manager/
    ├── agent-extras/
    │   ├── flake.nix                    # Declares upstream skill/plugin repos (`flake = false`)
    │   └── flake.lock                   # Pins exact commit hashes & NAR hashes for each upstream repo
    └── modules/
        ├── claude-code.nix              # Declarative Claude Code config (`~/.claude/settings.json`, MCPs, statusline)
        ├── antigravity.nix              # Declarative Antigravity config (`~/.gemini/antigravity/...`)
        └── plugins.nix                  # Links skills & plugins into ~/.claude, ~/.agents, and ~/.gemini/config
```

---

## Upstream Sources (`home-manager/agent-extras/flake.nix`)

Upstream repositories are declared with `flake = false` in `home-manager/agent-extras/flake.nix`:

- `claude-plugins-official` (`github:anthropics/claude-plugins-official`) — official Anthropic Claude Code plugins (`pyright-lsp`, `typescript-lsp`, `rust-analyzer-lsp`, `gopls-lsp`, `context7`, `code-review`, `commit-commands`, `security-guidance`, `skill-creator`, `claude-md-management`)
- `superpowers-marketplace` (`github:obra/superpowers-marketplace`) — Superpowers workflow plugin
- `codex-plugin-cc` (`github:openai/codex-plugin-cc`) — OpenAI Codex plugin for Claude Code
- `mattpocock-skills` (`github:mattpocock/skills`) — TDD, grill-me, diagnose, architecture, writing, and triage skills
- `frontend-design` (`github:anthropics/claude-code`) — Frontend design skill
- `modern-web-guidance` (`github:GoogleChromeLabs/web-skills`) — Modern web and Chrome extensions skills
- `android-cli` (`github:google/android-cli`) — Android CLI skill
- `science-skills` (`github:google-deepmind/science-skills`) — Bioinformatics and scientific research skills
- `caveman` (`github:JuliusBrussee/caveman`) — Ultra-compressed communication skill

Additionally, locally authored skills (such as `security-audit`) live directly in `home-manager/skills/` and are symlinked via `home-manager/modules/plugins.nix`.

---

## Deployment Targets (`home-manager/modules/plugins.nix`)

During `rebuild`, `home-manager/modules/plugins.nix`:

1. Links Claude Code marketplaces and plugins into `~/.claude/plugins/` and registers them in `~/.claude/settings.json`.
2. Links standalone skills (`frontend-design`, `caveman`, `security-audit`) into `~/.claude/skills/`, `~/.agents/skills/`, and `~/.gemini/config/skills/`.
3. Links multi-skill plugin bundles (`mattpocock-skills`, `modern-web-guidance`, `android-cli`, `science`, `google-antigravity-sdk`) into `~/.gemini/config/plugins/`.

---

## Updating Skills & Plugins

### Automated via `update`

Running `update` (`home-manager/scripts/update-system.sh`) automatically updates both the child flake (`nix flake update --flake ./home-manager/agent-extras`) and the root flake (`nix flake update`), then runs `rebuild`.

### Updating a Single Skill Source Manually

```bash
# 1. Update a specific input in the child flake
nix flake update mattpocock-skills --flake ~/dotfile/home-manager/agent-extras

# 2. Propagate the updated child lock into the root flake.lock
nix flake update agent-extras --flake ~/dotfile

# 3. Apply changes
rebuild
```

### Validating Sources in CI

The root `flake.nix` exposes `checks.aarch64-darwin.agent-sources` (defined in `home-manager/agent-extras/flake.nix`), which verifies that every pinned upstream repository contains its expected plugin/skill directory structure and manifest files (`plugin.json` / `SKILL.md`).
