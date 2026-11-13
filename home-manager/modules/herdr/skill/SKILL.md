---
name: herdr
description: Coordinate agents and review code changes in Herdr TUI when the user requests Herdr work, another agent's review, or an implementer and reviewer workflow inside Herdr.
---

# Herdr TUI workflow

Check `test "${HERDR_ENV:-}" = 1` before controlling Herdr. If outside Herdr, do not target its focused session. Read `herdr --skill` for release-matched CLI instructions before pane or agent control. Use explicit IDs, caller context and `--no-focus`; never commandeer an existing busy agent or close the user's panes.

## Review changes

`herdr-review` opens Lazygit in the calling pane's repository. Ctrl+A then g opens GitView (interactive diffs and agent feedback), Ctrl+A then Shift-G opens GitView in a dedicated tab, and Ctrl+A then l opens Lazygit as a popup for full commit history and rebasing.

Before a new task, run `herdr-review mark` from its checkout to record HEAD. Do not reset an existing task's baseline automatically. Inspect `git status` first: a baseline includes existing uncommitted changes and cannot attribute them to an agent. Ctrl+A then d, or `herdr-review diff`, shows tracked changes since that baseline, including commits made during the task, and lists untracked files separately. Without a baseline it shows current changes against HEAD. Press q to close. Read new files separately. A baseline belongs to one Git worktree, not one agent or conversation.

## PRs, checks and task context

Read `~/.config/herdr/workflow.md` when using the installed workflow commands. `hpr` opens a PR in an isolated worktree. `hcheck` runs project checks and records actual results. `htask start`, `note`, `show` and `finish` maintain a durable task summary and baseline. Preserve an active task rather than replacing it.

For a requested review, `hreview-agent --kind <codex|claude> --requirements "<scope>"` performs the helper handoff and captures its recent output. Choose the requested kind, or the lead agent's kind. Inspect the transcript and actual diff; report remaining uncertainty. An idle reviewer or successful CLI call is not evidence that findings are correct or checks passed. Do not rerun a timed-out prompt blindly. Submit GitHub comments only when the user explicitly asks.

## Implementer and reviewer

When coordination is requested, let a lead agent implement and a helper review. Choose the requested agent; otherwise use the lead's kind. Before launching, discover current layout and agents using the bundled guide. Create a sibling pane without stealing focus, then start a uniquely named helper with `herdr agent start`. Do not launch helpers merely because this skill is loaded.

Give the reviewer the checkout path, task requirements, starting commit, intended scope, existing dirty changes and validation results. Request review only, no file edits. Submit through `herdr agent prompt <target> "<task>" --wait --timeout 120000`, then inspect status and read its response with `herdr agent read`. A timeout can follow delivery; inspect before retrying. Idle, unknown and blocked states are not evidence that tests passed. Never answer approval dialogs automatically.

The lead collects findings, checks them against the actual diff and tests, makes justified corrections, and reports unresolved findings. This is explicit communication through Herdr's CLI, not shared conversation memory. If terminal history is incomplete, ask the reviewer to write findings to a temporary Markdown file and read it.

For concurrent implementation, create a separate Git worktree and branch per editing task. Preserve pre-existing work and choose paths outside tracked source directories. Use `herdr worktree --help` and its relevant subcommand help for current syntax. Never let two independently editing agents share a checkout by default. A read-only reviewer can share the implementer's checkout after edits settle.

Use helper panes only for the task requested. Leave them available for inspection unless the user asks to close them. Do not push, merge or deploy just because the reviewer approves.
