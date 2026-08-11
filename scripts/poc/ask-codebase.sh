#!/usr/bin/env bash

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
  echo "Run this command inside a Git repository." >&2
  exit 1
fi

question="${*:-}"
if [[ -z "$question" ]]; then
  echo "Usage: $0 \"question about this repository\"" >&2
  exit 2
fi

graph_path="$repo_root/graphify-out/graph.json"
if [[ ! -f "$graph_path" ]]; then
  if ! command -v graphify >/dev/null 2>&1; then
    echo "graphify is required to build the local graph." >&2
    exit 3
  fi
  echo "No graph found; building one with graphify..." >&2
  graphify update "$repo_root"
fi

if ! command -v pi >/dev/null 2>&1; then
  echo "pi is required to run the analyst agent." >&2
  exit 4
fi

cd "$repo_root"
exec pi \
  --approve \
  --no-session \
  --no-builtin-tools \
  --extension npm:pi-mcp-extension \
  --skill .pi/skills/analyst-code-answers/SKILL.md \
  --model "${PI_ANALYST_MODEL:-lmstudio/google/gemma-4-26b-a4b}" \
  --print \
  "$question"
