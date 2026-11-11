# Herdr terminal workflow

These tools run when opened. They use your existing GitHub authentication and Neovim configuration.

## Project launcher

Run `p` from a Shell tab to choose a project, or `p PATH` to open a specific repository. Work projects get Shell and CC. Personal projects and either dotfile checkout get Shell, then AGY only with Antigravity history, then CX only with Codex history.

The shell function delegates to `herdr-project-open`. Its implementation updates with the system profile, so a future rebuild does not leave old layout logic loaded in a long-running shell. Shells with a launcher from before this shim need one initial refresh.

## PR inbox and review

Run `hinbox`, or press Ctrl+A then i, to open the GitHub inbox. Its sections show PRs that need your review, your open PRs, and PRs involving you. Dependabot has its own section covering your account and the VorTECHsa and bodhispace-xyz organisations. Dependabot results load 20 at a time; move down to the last loaded PR to fetch more. Bot PRs are excluded from the human-review sections. Select a PR and press Shift+V to open it in Herdr. Press q to close the inbox popup and see the review workspace.

Select a PR and press Shift+A to queue an AI review in the background. Keep browsing the inbox, or press q to return to your original agent. Preparation and review run without changing focus. Herdr shows a notification when the review workspace is ready, when reviewer output is ready, or when it needs attention. Select the PR workspace in Herdr's sidebar and open its AI Review tab to inspect progress and findings. Repeating Shift+A reuses the existing review tab for that revision without interrupting your current work. Close that tab before requesting a fresh review. Claude reviews work repositories; Codex reviews personal repositories. The reviewer receives the PR description and exact diff, plus dependency upgrade checks for Dependabot PRs. Findings stay local and include severity, file/line references and suggested fixes. The command saves recent reviewer output; inspect the agent pane for the complete exchange or any approval prompt. Launch logs are stored under `~/.local/state/herdr-workflow/launches/` (or `$XDG_STATE_HOME/herdr-workflow/launches/`).

PR descriptions render with bold headings, shaded inline code and visible table borders. Rebuild activation reloads the running Herdr configuration so new popups use the current dashboard binary. Close and reopen an existing popup after rebuilding.

Scroll the right-hand preview with your mouse wheel or a two-finger touchpad gesture while the pointer is over it. The preview scrolls three lines per wheel event and works in either the right or bottom position. Ctrl+D and Ctrl+U remain available.

You can also run:

```sh
hpr 123
hpr https://github.com/OWNER/REPO/pull/123
hpr 123 --repo OWNER/REPO
```

The repository must already be cloned. The launcher looks in the current checkout, Work, Personal, and both dotfile locations. Nested repositories are searched up to three directory levels below Work and Personal.

The launcher fetches and verifies the PR head and base commits. It creates a detached Git worktree outside your project folders and records the merge-base used for review. Your original checkout keeps its branch and changes. A repeated launch of the same revision reuses its worktree and open Herdr workspace. A new PR revision gets another worktree.

The workspace has two tabs:

- **Review:** Neovim with Diffview showing the selected PR revision.
- **Checks:** a shell that prints the current GitHub CI result. Run `hpr-ci` again to refresh it. Run `hcheck` here to execute local checks.

The launcher accepts open PRs. For historical PRs, use Octo or `gh pr diff`.

In Neovim, press Space, g, R to open the selected PR in Octo, including from a detached review worktree. Space, g, I lists PRs. Space, g, v opens a local diff, and Space, g, H opens the current file's history. `:Octo review start` starts a line-level review. Use `:Octo review submit` to choose how to submit it. Octo writes comments to GitHub when you save or submit them, so inspect your text first.

The PR-status pane remains available through Ctrl+A then p. Ctrl+A then g opens Lazygit; Ctrl+A then d shows the task diff.

## Project checks

Run `hcheck` in the checkout you want to validate. Rust projects default to format, Clippy and locked tests. Nix flakes default to `nix flake check --no-build --no-write-lock-file`. Other projects need a check definition.

Run `hcheck --init` to create `.herdr/checks.toml`, then replace the example with the repository's actual commands. For example:

```toml
[[checks]]
name = "tests"
argv = ["uv", "run", "pytest"]

[[checks]]
name = "lint"
argv = ["uv", "run", "ruff", "check", "."]
```

Commands run in order in the repository root. A failure stops the sequence. Each result records the exit status, log path, commit and checkout signatures. An active task summary also receives the result. Logs live under `~/.local/state/herdr-workflow/tasks/` unless XDG_STATE_HOME changes that location.

## Search and edit

Run `hfind` to select a tracked or untracked file and open it in Neovim. Run `hfind PATTERN` to select a ripgrep match and open its exact line. Match selection is limited to 2,000 results. Ctrl+A then f opens the file picker in a popup. Press Escape to cancel, or close Neovim to return to Herdr.

## Task context

Start a task before editing:

```sh
htask start "Fix namespace handling" --goal "Preserve namespace on every backup request"
htask note "The API requires ns on the groups endpoint as well"
hcheck
htask show
```

Starting a task records HEAD as its baseline. Existing checkout changes are listed in the summary. The summary contains your goal, notes, actual check results and captured reviewer transcripts. It lives outside the checkout, so it creates no untracked project files.

An existing task cannot be overwritten. Use `htask finish` to archive its summary, then start the next task. Finishing a task does not close agent panes or remove worktrees.

For separate editing tasks, use separate worktrees. A read-only reviewer can inspect the implementer's checkout after edits settle.

## Agent reviewer

When you want another agent to review the changes, run:

```sh
hreview-agent --requirements "Check correctness, regressions and missing namespace tests"
hreview-agent --kind claude --requirements "Review the selected PR"
```

The command starts one helper in a sibling pane without changing your focus. Its default is Claude for a work checkout, including a review worktree created from one; otherwise it uses Codex. Codex runs with its read-only sandbox. Claude starts in plan mode.

The helper receives the checkout, comparison baseline, requirements, task-summary path and available validation evidence. The command waits for its state and saves its recent output as a transcript. The lead agent must inspect the findings, check them against the diff, and resolve or report them. Captured output is not a guarantee that every finding or the full response is present.

If startup needs approval, or a wait times out, inspect the named helper pane before trying again. A timeout does not mean the prompt was not delivered. No approval dialog is answered automatically, and no review is posted by the helper command.

Close finished helpers when you no longer need them. Review worktrees are retained for inspection. After closing their Herdr workspaces, use `git worktree list` and `git worktree remove PATH` from the source repository to remove a finished review checkout. Git will refuse to remove a dirty worktree without an explicit override.
