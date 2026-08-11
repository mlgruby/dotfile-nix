---
artifact_contract: ce-unified-plan/v1
artifact_readiness: requirements-only
product_contract_source: ce-brainstorm
date: 2026-08-11
---

# Requirements Plan: CodexBar & AI Quotas Tmux Status Line Integration

## Summary
Add a non-blocking, modular status segment (`codexbar.sh`) to the tmux status bar in home-manager dotfiles. The module renders live usage metrics for OpenAI Codex, Google Gemini (AGY), and Anthropic Claude alongside mini pixel-accurate ANSI logos generated via `chafa`.

## Problem Frame
Developers using multiple AI coding assistants (Codex, Antigravity/Gemini, Claude Code) lack a centralized, unobtrusive view of their remaining limits and daily expenditure inside their terminal session. Checking rate limits manually in web dashboards or separate CLI commands interrupts context.

## User Persona & User Journey
- **User**: Command-line developer working extensively inside `tmux`.
- **Journey**: While coding in tmux, the top status bar displays clean AI quota indicators. As limits approach reset windows or daily cost changes, the status bar reflects these values without freezing shell commands or status redraws.

## Requirements

### R1: Data Collection & Metrics
1. **R1.1 Codex Quota**: Retrieve weekly remaining percentage and reset timer using `codexbar usage --provider codex --format json`.
2. **R1.2 Antigravity (AGY) Quotas**: Retrieve 5-hour window remaining % and weekly window remaining % using `codexbar usage --provider antigravity --format json`.
3. **R1.3 Claude Daily Cost**: Compute today's total dollar cost by scanning local JSONL session logs in `~/.claude/` for today's timestamp and multiplying input/output tokens by Anthropic model rates.

### R2: Logo Assets & ANSI Rendering
1. **R2.1 Asset Storage**: Store vector/PNG logo assets for OpenAI, Gemini, and Claude in `~/.config/tmux/status/logos/`.
2. **R2.2 Mini ANSI Rendering**: Use `chafa` to render mini 2x1 character ANSI color logo icons for each provider.
3. **R2.3 Dependency Management**: Include `pkgs.chafa` and `pkgs.jq` in `home-manager/modules/tmux.nix` package dependencies.

### R3: Performance & Non-Blocking Caching
1. **R3.1 Asynchronous Background Fetch**: Perform web queries and log parsing in a background subshell that updates `/tmp/codexbar_status.cache`.
2. **R3.2 Expiration Window**: Refresh cache if older than 120 seconds (2 minutes).
3. **R3.3 Sub-Millisecond Status Read**: Reading from `/tmp/codexbar_status.cache` during tmux status-interval redraws must take `< 5ms` to prevent terminal lag.

### R4: Tmux Integration & Styling
1. **R4.1 Modular Integration**: Add `home-manager/scripts/tmux/status/codexbar.sh` and wire it into `status-right.sh`.
2. **R4.2 Theme Compatibility**: Apply Gruvbox color scheme matching existing status bar segments.
3. **R4.3 Guardrail Validation**: Pass `scripts/testing/check-tmux-status.sh` syntax and rendering checks.

## Key Decisions
- **Decision 1**: Asynchronous file caching over synchronous CLI invocation inside `status-right.sh` to guarantee 0-lag status redraws.
- **Decision 2**: Local log parsing (`~/.claude/`) for Claude daily dollar cost calculations rather than web API (web session API only provides percentage of 5-hour window).
- **Decision 3**: `chafa` mini ANSI image rendering over standard unicode emoji to deliver real brand logos in terminal tmux.

## Scope Boundaries
- **In Scope**: Codex weekly quota, AGY 5h + weekly quota, Claude daily cost calculation, `chafa` logo rendering, background caching, home-manager tmux nix integration.
- **Out of Scope**: Real-time network calls on every status tick; modifying CodexBar Swift source code.
