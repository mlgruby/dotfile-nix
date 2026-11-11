#!/usr/bin/env python3
"""Create project tabs, starting personal agents only when history exists."""
import fcntl
from contextlib import closing
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sqlite3
from urllib.parse import unquote, urlsplit
import sys


def claude_command(repo, config_dir=None):
    """Ignore placeholder histories and subagent-only transcripts."""
    config = Path(config_dir or os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude"))
    project = config / "projects" / re.sub(r"[^a-zA-Z0-9]", "-", str(repo))
    for transcript in project.glob("*.jsonl"):
        try:
            with transcript.open() as lines:
                for line in lines:
                    try:
                        record = json.loads(line)
                    except ValueError:
                        continue
                    if not isinstance(record, dict):
                        continue
                    if (record.get("type") == "user" and not record.get("isSidechain")
                            and record.get("cwd")
                            and Path(record["cwd"]).resolve() == repo):
                        return "ccr"
        except (OSError, ValueError):
            continue
    return "cc"


def _same_directory(value, directory):
    try:
        return bool(value) and Path(value).resolve() == directory
    except (OSError, ValueError, TypeError):
        return False


def has_codex_history(repo, codex_home=None):
    home = Path(codex_home or os.environ.get("CODEX_HOME", Path.home() / ".codex"))
    databases = sorted(home.glob("state_*.sqlite"),
                       key=lambda p: int(p.stem.split("_")[-1]) if p.stem.split("_")[-1].isdigit() else -1,
                       reverse=True)
    for database in databases:
        try:
            with closing(sqlite3.connect(f"{database.resolve().as_uri()}?mode=ro", uri=True, timeout=0.2)) as db:
                rows = db.execute("SELECT cwd, source FROM threads WHERE archived = 0")
                return any("subagent" not in (source or "") and _same_directory(cwd, repo)
                           for cwd, source in rows)
        except (OSError, sqlite3.Error):
            continue
    # Older installs may have rollout files but no usable state database.
    for rollout in (home / "sessions").rglob("*.jsonl"):
        try:
            with rollout.open() as lines:
                for _, line in zip(range(16), lines):
                    record = json.loads(line)
                    if not isinstance(record, dict):
                        continue
                    if record.get("type") == "session_meta":
                        meta = record.get("payload", {})
                        if ("subagent" not in json.dumps(meta.get("source", ""))
                                and _same_directory(meta.get("cwd"), repo)):
                            return True
                        break
        except (OSError, ValueError, TypeError):
            continue
    return False


def agy_directory(database):
    """Read the first workspace URI from Antigravity's protobuf metadata."""
    try:
        with closing(sqlite3.connect(f"{Path(database).resolve().as_uri()}?mode=ro", uri=True, timeout=0.2)) as db:
            row = db.execute("SELECT data FROM trajectory_metadata_blob LIMIT 1").fetchone()
        if not row:
            return None
        data = row[0].encode() if isinstance(row[0], str) else bytes(row[0])
        start = data.find(b"file:///")
        if start < 0:
            return None
        # Protobuf strings carry a varint byte length immediately before them.
        # Honour that length, rather than truncating at spaces or Unicode.
        for width in range(1, min(5, start) + 1):
            prefix = data[start-width:start]
            if any(not b & 128 for b in prefix[:-1]) or prefix[-1] & 128:
                continue
            length = sum((b & 127) << (7*i) for i, b in enumerate(prefix))
            if length < 8 or start + length > len(data):
                continue
            uri = data[start:start+length].decode("utf-8")
            if any(ord(c) < 32 for c in uri):
                continue
            return Path(unquote(urlsplit(uri).path)).resolve()
        # Compatibility with older metadata that embeds a plain URI.
        match = re.search(rb"file:///[a-zA-Z0-9_/.-]+", data)
        if match:
            return Path(unquote(urlsplit(match[0].decode()).path)).resolve()
    except (OSError, ValueError, TypeError, sqlite3.Error):
        pass
    return None


def has_agy_history(repo, agy_home=None):
    home = Path(agy_home or Path.home() / ".gemini/antigravity-cli")
    for database in (home / "conversations").glob("*.db"):
        if agy_directory(database) != repo:
            continue
        transcript = home / "brain" / database.stem / ".system_generated/logs/transcript.jsonl"
        try:
            with transcript.open() as lines:
                for line in lines:
                    try:
                        record = json.loads(line)
                    except ValueError:
                        continue
                    if not isinstance(record, dict):
                        continue
                    content = record.get("content", "")
                    if (record.get("type") == "USER_INPUT" and isinstance(content, str)
                            and any(part.strip() and not any(token in part for token in
                                    ("USER_REQUEST", "ADDITIONAL_METADATA", "USER_SETTINGS_CHANGE"))
                                    for part in content.splitlines())):
                        return True
        except (OSError, ValueError, TypeError):
            continue
    return False


def apply_layout(workspace_id, call, work_root=None, config_dir=None,
                 personal_root=None, dotfile_roots=None, codex_home=None, agy_home=None):
    tabs = call("tab", "list", "--workspace", workspace_id)["tabs"]
    panes = call("pane", "list", "--workspace", workspace_id)["panes"]
    # Never remodel an established workspace or take over an agent's pane.
    if len(tabs) != 1 or len(panes) != 1 or panes[0].get("agent"):
        return False
    pane = panes[0]
    cwd = pane.get("foreground_cwd") or pane.get("cwd")
    if not cwd:
        return False
    repo = Path(cwd).resolve()
    work = Path(work_root or Path.home() / "Documents/Work").resolve()
    personal = Path(personal_root or Path.home() / "Documents/Personal").resolve()
    dotfiles = [Path(p).resolve() for p in (dotfile_roots if dotfile_roots is not None else
                [Path.home() / "dotfile", Path.home() / "Documents/dotfile"])]
    is_work = repo != work and repo.is_relative_to(work)
    is_personal = (repo != personal and repo.is_relative_to(personal)) or repo in dotfiles
    if not (is_work or is_personal):
        return False
    git = subprocess.run(["git", "-C", str(repo), "rev-parse", "--show-toplevel"],
                         capture_output=True, text=True)
    if git.returncode:
        return False
    if is_work:
        agents = [("CC", claude_command(repo, config_dir))]
    else:
        agents = []
        if has_agy_history(repo, agy_home):
            agents.append(("AGY", "agr"))
        if has_codex_history(repo, codex_home):
            agents.append(("CX", "cxr"))
    call("tab", "rename", tabs[0]["tab_id"], "Shell")
    for label, command in agents:
        call("tab", "create", "--workspace", workspace_id, "--cwd", str(repo),
             "--label", label, "--no-focus", "--env", f"DOTFILES_HERDR_PROJECT_AGENT={command}")
    return True


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "--agy-cwd":
        directory = agy_directory(sys.argv[2])
        if directory:
            print(directory)
        return
    if os.environ.get("HERDR_ENV") != "1":
        raise RuntimeError("Run inside Herdr or as a Herdr plugin hook.")
    workspace = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("HERDR_WORKSPACE_ID")
    if not workspace:
        raise RuntimeError("A workspace ID is required.")
    binary = os.environ.get("HERDR_BIN_PATH") or "/opt/homebrew/bin/herdr"

    def call(*args):
        result = subprocess.run([binary, *args], capture_output=True, text=True, check=True)
        return json.loads(result.stdout)["result"]

    # The p launcher and workspace-created event may arrive together.
    state = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "herdr-project-layout"
    state.mkdir(parents=True, exist_ok=True)
    key = hashlib.sha256((os.environ.get("HERDR_SOCKET_PATH", "default") + workspace).encode()).hexdigest()
    with (state / (key + ".lock")).open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        apply_layout(workspace, call)


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        print(f"Herdr project layout: {error}", file=sys.stderr)
        sys.exit(1)
