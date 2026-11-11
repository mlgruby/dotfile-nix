#!/usr/bin/env bash
set -euo pipefail

# Popup terminals disappear when their command exits. Keep failures readable.
on_error() {
  status=$?
  trap - ERR
  if [[ -t 0 && -t 2 ]]; then
    printf '\nReview could not open. Press Enter to close. ' >&2
    read -r _ || true
  fi
  exit "$status"
}
trap on_error ERR

# Herdr supplies action context; never use a different client's focused pane.
if [[ -n "${HERDR_ACTIVE_PANE_CWD:-}" ]]; then
  cd "$HERDR_ACTIVE_PANE_CWD"
elif [[ -n "${HERDR_FOCUSED_PANE_CWD:-}" ]]; then
  cd "$HERDR_FOCUSED_PANE_CWD"
elif [[ -n "${HERDR_PANE_ID:-}" ]]; then
  pane_json="$(herdr pane get "$HERDR_PANE_ID")"
  pane_cwd="$(printf '%s' "$pane_json" | jq -er '.result.pane.foreground_cwd // .result.pane.cwd')"
  cd "$pane_cwd"
fi

action="${1:-git}"
case "$action" in
  -h|--help)
    echo 'Usage: herdr-review [git|mark|diff]'
    echo 'git: Lazygit; mark: record current HEAD as task baseline; diff: changes since baseline.'
    exit 0 ;;
  git|mark|diff) ;;
  *) echo "Unknown action: $action" >&2; exit 2 ;;
esac
root="$(git rev-parse --show-toplevel)"
cd "$root"
baseline="$(git rev-parse --git-path herdr-review-base)"

case "$action" in
  git) exec lazygit --path "$root" ;;
  mark)
    head="$(git rev-parse --verify HEAD)"
    temp_base="$(mktemp "${baseline}.XXXXXX")"
    trap 'rm -f "$temp_base"' EXIT
    printf '%s\n' "$head" > "$temp_base"
    mv "$temp_base" "$baseline"
    printf 'Task baseline: %s\n' "$head"
    if [[ -n "$(git status --porcelain)" ]]; then
      echo 'This checkout already has changes. They will also appear in the task diff.'
    fi
    ;;
  diff)
    if [[ -f "$baseline" ]]; then
      base="$(cat "$baseline")"
      heading="Changes since task baseline $base"
    else
      base=HEAD
      heading='Current changes against HEAD (no task baseline set)'
    fi
    git cat-file -e "${base}^{commit}"
    diff_file="$(mktemp "${TMPDIR:-/tmp}/herdr-review.XXXXXX")"
    trap 'rm -f "$diff_file"' EXIT
    {
      printf '%s\nPress q to close. Use herdr-review mark before a task to include its commits.\n\n' "$heading"
      git -c color.ui=always diff --stat "$base" --
      git -c color.ui=always diff "$base" --
      printf '\nUntracked files (contents are not included above):\n'
      git ls-files --others --exclude-standard
    } > "$diff_file"
    # Ignore inherited LESS=-F: even an empty/short diff must remain visible.
    LESS='' LESSOPEN='' LESSCLOSE='' less -R "$diff_file"
    ;;
esac
