#!/usr/bin/env python3
"""Herdr.app project tabs: the agent tabs a new project gets, from saved history."""
from contextlib import closing
from datetime import datetime
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
                # `codex resume` lists only threads whose rollout file exists.
                rows = db.execute("SELECT cwd, source, rollout_path FROM threads WHERE archived = 0")
                return any("subagent" not in (source or "") and _same_directory(cwd, repo)
                           and bool(rollout) and Path(rollout).is_file()
                           for cwd, source, rollout in rows)
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


def _agy_first_preview(transcript):
    """Return the first meaningful user prompt line from an Antigravity transcript."""
    try:
        with transcript.open(encoding="utf-8", errors="replace") as lines:
            for line in lines:
                # Skip non-input events before decoding JSON to keep large transcripts fast.
                if '"USER_INPUT"' not in line:
                    continue
                try:
                    record = json.loads(line)
                except ValueError:
                    continue
                if not isinstance(record, dict) or record.get("type") != "USER_INPUT":
                    continue
                content = record.get("content", "")
                if not isinstance(content, str):
                    continue
                for part in content.splitlines():
                    if part.strip() and not any(
                        token in part
                        for token in ("USER_REQUEST", "ADDITIONAL_METADATA", "USER_SETTINGS_CHANGE")
                    ):
                        return part
    except (OSError, ValueError, TypeError):
        pass
    return None


def _short_home_path(directory, home_dir=None):
    home_str = str((Path(home_dir) if home_dir else Path.home()).resolve())
    path_str = str(directory)
    if path_str == home_str or path_str.startswith(home_str + os.sep):
        return "~" + path_str[len(home_str):]
    return path_str


def list_agy_conversations(cwd=None, show_all=False, agy_home=None, home_dir=None):
    """Format Antigravity conversations sorted newest-first for fzf selection."""
    home = Path(agy_home or Path.home() / ".gemini/antigravity-cli")
    target_cwd = None if show_all else Path(cwd or os.getcwd()).resolve()
    entries = []
    for database in (home / "conversations").glob("*.db"):
        if not database.is_file():
            continue
        uuid = database.stem
        transcript = home / "brain" / uuid / ".system_generated/logs/transcript.jsonl"
        if not transcript.is_file():
            continue
        session_cwd = agy_directory(database)
        # Check directory match before reading transcript so non-matching repos skip JSON I/O.
        if not show_all and session_cwd != target_cwd:
            continue
        preview = _agy_first_preview(transcript)
        if not preview:
            continue
        try:
            mtime_epoch = database.stat().st_mtime
        except OSError:
            mtime_epoch = 0
        mtime_fmt = datetime.fromtimestamp(mtime_epoch).strftime("%Y-%m-%d %H:%M") if mtime_epoch else "Unknown"
        clean_preview = preview.replace("\r", "").replace("\n", "").replace("\t", " ")[:80]
        if show_all and session_cwd is not None:
            short_cwd = _short_home_path(session_cwd, home_dir=home_dir)
            line = f"{mtime_fmt} | {short_cwd:<25} | {clean_preview:<60} | {uuid}"
        else:
            line = f"{mtime_fmt} | {clean_preview:<75} | {uuid}"
        entries.append((mtime_epoch, line))
    entries.sort(key=lambda item: item[0], reverse=True)
    return [line for _, line in entries]


def has_agy_history(repo, agy_home=None):
    home = Path(agy_home or Path.home() / ".gemini/antigravity-cli")
    for database in (home / "conversations").glob("*.db"):
        if agy_directory(database) != repo:
            continue
        transcript = home / "brain" / database.stem / ".system_generated/logs/transcript.jsonl"
        if _agy_first_preview(transcript) is not None:
            return True
    return False


def plan_agents(cwd, work_root=None, config_dir=None, personal_root=None,
                dotfile_roots=None, codex_home=None, agy_home=None):
    """The agent tabs a new project gets, as (label, command) pairs.

    None: the folder is not a git repo under the work or personal roots.
    Herdr.app reads it with `--plan DIR`.
    """
    repo = Path(cwd).resolve()
    work = Path(work_root or Path.home() / "Documents/Work").resolve()
    personal = Path(personal_root or Path.home() / "Documents/Personal").resolve()
    dotfiles = [Path(p).resolve() for p in (dotfile_roots if dotfile_roots is not None else
                [Path.home() / "dotfile", Path.home() / "Documents/dotfile"])]
    is_work = repo != work and repo.is_relative_to(work)
    is_personal = (repo != personal and repo.is_relative_to(personal)) or repo in dotfiles
    if not (is_work or is_personal):
        return None
    git = subprocess.run(["git", "-C", str(repo), "rev-parse", "--show-toplevel"],
                         capture_output=True, text=True)
    if git.returncode:
        return None
    if is_work:
        return [("CC", claude_command(repo, config_dir))]
    agents = []
    if has_agy_history(repo, agy_home):
        agents.append(("AGY", "agr"))
    if has_codex_history(repo, codex_home):
        agents.append(("CX", "cxr"))
    return agents


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "--plan":
        # For Herdr.app: JSON [[label, command], ...], or null for no layout.
        print(json.dumps(plan_agents(sys.argv[2])))
        return
    if len(sys.argv) >= 2 and sys.argv[1] == "--agy-list":
        show_all = False
        cwd = None
        for arg in sys.argv[2:]:
            if arg in ("-a", "--all"):
                show_all = True
            elif cwd is None:
                cwd = arg
        for line in list_agy_conversations(cwd=cwd, show_all=show_all):
            print(line)
        return
    if len(sys.argv) == 3 and sys.argv[1] == "--agy-cwd":
        directory = agy_directory(sys.argv[2])
        if directory:
            print(directory)
        return
    raise RuntimeError("Use --plan DIR, --agy-list [DIR] [-a] or --agy-cwd DB.")

if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        print(f"herdr-project-layout: {error}", file=sys.stderr)
        sys.exit(1)
