# Claude Code Skills Management

Research notes + tradeoff analysis for bringing skills under dotfile/Nix management.

---

## Current State (Satyasheel)

```
~/.agents/skills/<skill>/    ← actual files, NOT git-tracked
~/.claude/skills/<skill>/    ← symlinks into ~/.agents/skills/
```

Skills arrived via an installer (likely `ce-setup` or `setup-matt-pocock-skills` skill).
Dates in `~/.agents/skills/` cluster around 2026-05-26 and 2026-05-27 — two install runs.

**Sources visible from skill content:**
- `ce-*` prefix → Claude Code / Anthropic superpowers catalog
- `animejs`, `css-animations`, `gsap`, `lottie`, `three`, `typegpu`, `waapi`, `hyperframes*`, `remotion-*` → animation/frontend cluster (likely one publisher)
- `grill-me`, `grill-with-docs`, `tdd`, `to-issues`, `to-prd`, `triage`, `diagnose`, `improve-codebase-architecture`, `prototype`, `coding-tutor` → Matt Pocock skills catalog

**Problem:** Fresh Nix rebuild = skills gone. No declarative source of truth.

---

## Reference: Edmund Miller's Approach

Repo: https://github.com/edmundmiller/dotfiles

### Architecture

```
dotfiles/
├── flake.nix                    ← imports skills/ as child flake
├── flake.lock                   ← locks skills-catalog flake input too
└── skills/
    ├── flake.nix                ← declares upstream skill repos as inputs
    ├── flake.lock               ← independent lock for skill inputs
    ├── catalog/<name>/SKILL.md  ← locally-authored skills
    └── conditional/<name>/      ← wrapped upstream skills
```

### Upstream repos declared in `skills/flake.nix`

Each uses `flake = false` — content-addressed, not evaluated as a flake:

```nix
mattpocock-skills = { url = "github:mattpocock/skills"; flake = false; };
mitsuhiko-skills  = { url = "github:mitsuhiko/agents";  flake = false; };
bholmesdev        = { url = "github:bholmesdev/...";    flake = false; };
gitbutler         = { url = "github:gitbutler-app/..."; flake = false; };
herdr             = { url = "github:acpxio/herdr";      flake = false; };
acpx              = { url = "github:acpxio/acpx";       flake = false; };
# + ~15 more
```

### Deployment via Home Manager

- Module: `programs.agent-skills` from `inputs.skills-catalog.homeManagerModules.default`
- Skills are **copied** (not symlinked) so agents can mutate them at runtime
- 6 deployment targets: `~/.claude/skills`, `~/.agents/skills`, `~/.pi/agent/skills`,
  `~/.codex/skills`, `~/.config/opencode/skills`, `~/.hermes/skills`
- Conditional: skill only deployed if parent module enabled (`claude.enable`, `git.enable`, etc.)
- Skills can be augmented with a `transform` block to append custom content per-agent

### Lock sync requirement

Two lock files must stay in sync. Pre-commit hook enforces:

```
skills/flake.lock  ← skill input pins
flake.lock         ← includes skills-catalog entry

# Update flow:
cd skills && nix flake lock --update-input mattpocock-skills
cd ..      && nix flake update skills-catalog
```

### Update workflow

```bash
cd skills
nix flake lock --update-input <source-name>   # update one skill source
cd ..
nix flake update skills-catalog               # propagate to parent
darwin-rebuild switch                         # deploy
```

---

## Tradeoff Analysis

### Current (manual install, no tracking)

| | |
|---|---|
| **Pro** | Zero setup. Skills just work. |
| **Pro** | Always latest — installer pulled current at time of run. |
| **Con** | Not reproducible. Fresh machine = manually re-run installer. |
| **Con** | No record of which skills or versions are installed. |
| **Con** | Skills can drift between machines silently. |
| **Con** | Can't roll back a bad skill update. |

### Edmund's approach (child flake + HM module)

| | |
|---|---|
| **Pro** | Fully reproducible — `darwin-rebuild switch` restores everything. |
| **Pro** | Hash-pinned — exact version known, rollback possible via `git revert`. |
| **Pro** | Conditional — only deploy what's relevant to enabled modules. |
| **Pro** | Works for all 6 agent targets in one declaration. |
| **Con** | Significant complexity: child flake, parent lock sync, HM module. |
| **Con** | You own the lock bump — upstream releases don't auto-arrive. |
| **Con** | Need to find every upstream repo URL (some skills' origin is unknown). |
| **Con** | `flake = false` inputs add to `nix flake update` time. |

### Middle path (simpler Nix, no child flake)

Declare skill repos directly as inputs in main `flake.nix` with `flake = false`.
Write a small HM activation script that `cp -r` them into place.
No separate child flake, no HM module dependency.

| | |
|---|---|
| **Pro** | Reproducible and version-pinned. |
| **Pro** | Much simpler than Edmund's full architecture. |
| **Pro** | Fits your existing `home-manager/modules/claude-code.nix` pattern. |
| **Con** | No conditional deployment logic (can add later if needed). |
| **Con** | Main `flake.lock` grows with 20+ skill input entries. |
| **Con** | Still need all upstream repo URLs. |

---

## Open Questions Before Implementing

1. **What upstream repo did `ce-*` skills come from?**
   The `ce-` prefix suggests Anthropic/Claude Code official skills catalog.
   Need URL — possibly `github:anthropics/claude-code-skills` or similar.

2. **What shipped `animejs`, `gsap`, `hyperframes*`, etc.?**
   Animation-heavy cluster with consistent style. Likely one publisher repo.

3. **Are any skills locally authored (not from upstream)?**
   Check if any `SKILL.md` files look hand-written vs. published.
   Local skills → store directly in dotfile under `home-manager/skills/catalog/`.

4. **Acceptable complexity budget?**
   Edmund's approach is powerful but ~200 lines of Nix across 3 files.
   Middle path achieves 80% of the value in ~30 lines.

---

## Recommended Next Step

Before writing any Nix:

```bash
# Try to identify skill origins
cat ~/.agents/skills/animejs/SKILL.md | head -10
cat ~/.agents/skills/ce-brainstorm/SKILL.md | head -5
# Look for author/source metadata in skill frontmatter
```

Then: find the upstream repos, decide complexity budget, implement.
