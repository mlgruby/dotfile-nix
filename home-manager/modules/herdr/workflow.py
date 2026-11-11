#!/usr/bin/env python3
"""On-demand Herdr PR review, checks, task context and editor navigation."""
import argparse
from contextlib import contextmanager
from datetime import datetime, timezone
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import tomllib
from urllib.parse import urlsplit
import uuid


def run(argv, cwd=None, **kwargs):
    return subprocess.run([str(a) for a in argv], cwd=cwd, text=True, check=True,
                          capture_output=True, **kwargs).stdout.strip()


def git(repo, *args):
    return run(['git', '-C', repo, *args])


def now():
    return datetime.now(timezone.utc).isoformat(timespec='seconds')


def context_dir():
    # Custom-command popups supply the original pane's directory.
    return Path(os.environ.get('HERDR_ACTIVE_PANE_CWD') or
                os.environ.get('HERDR_FOCUSED_PANE_CWD') or os.getcwd()).resolve()


def repo_root(directory=None):
    return Path(git(directory or context_dir(), 'rev-parse', '--show-toplevel')).resolve()


def state_root():
    root = Path(os.environ.get('XDG_STATE_HOME', Path.home() / '.local/state')) / 'herdr-workflow'
    root.mkdir(parents=True, exist_ok=True, mode=0o700)
    return root


def repo_key(repo):
    return hashlib.sha256(str(repo).encode()).hexdigest()[:20]


def task_dir(repo):
    directory = state_root() / 'tasks' / repo_key(repo)
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    return directory


def atomic_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as output:
            json.dump(value, output, indent=2)
            output.write('\n')
        os.replace(temp, path)
    finally:
        Path(temp).unlink(missing_ok=True)


def private_path(repo, name):
    return Path(git(repo, 'rev-parse', '--path-format=absolute', '--git-path', name))


def load_json(path, default=None):
    return json.loads(path.read_text()) if path.exists() else default


def render_task(data):
    lines = [f"# {data['name']}", '', f"Goal: {data['goal']}",
             f"Repository: {data['repo']}", f"Baseline: {data['baseline']}",
             f"Started: {data['started']}", '', '## Notes', '']
    lines += [f"- {note['time']}: {note['text']}" for note in data.get('notes', [])]
    lines += ['', '## Validation', '']
    for check in data.get('checks', []):
        lines.append(f"- {check['time']}: {check['name']}, exit {check['exit']}, log: {check['log']}")
    lines += ['', '## Reviewer output', '']
    lines += [f"- {r['time']}: {r['agent']}, {r['status']}, transcript: {r['path']}"
              for r in data.get('reviews', [])]
    return '\n'.join(lines) + '\n'


@contextmanager
def locked_task(repo):
    directory = task_dir(repo)
    with (directory / 'lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        yield directory


def update_task(repo, field, entry):
    with locked_task(repo) as directory:
        path = directory / 'task.json'
        data = load_json(path)
        if data:
            data.setdefault(field, []).append(entry)
            atomic_json(path, data)
            (directory / 'SUMMARY.md').write_text(render_task(data))


def start_task(repo, name, goal, baseline=None):
    with locked_task(repo) as directory:
        path = directory / 'task.json'
        if path.exists():
            raise RuntimeError(f'An active task already exists: {directory / "SUMMARY.md"}. Use htask finish first.')
        baseline = baseline or git(repo, 'rev-parse', 'HEAD')
        git(repo, 'cat-file', '-e', baseline + '^{commit}')
        data = dict(name=name, goal=goal, repo=str(repo), baseline=baseline, started=now(),
                    notes=[], checks=[], reviews=[])
        # Record existing changes rather than attributing them to the new task.
        status = git(repo, 'status', '--short')
        if status:
            data['notes'].append(dict(time=now(), text='Pre-existing checkout changes:\n' + status))
        atomic_json(path, data)
        (directory / 'SUMMARY.md').write_text(render_task(data))
        private_path(repo, 'herdr-review-base').write_text(baseline + '\n')
    return directory / 'SUMMARY.md'


def require_herdr():
    if os.environ.get('HERDR_ENV') != '1':
        raise RuntimeError('Run this command inside Herdr. No focused session was changed.')


def herdr(*args):
    require_herdr()
    binary = os.environ.get('HERDR_BIN_PATH') or '/opt/homebrew/bin/herdr'
    return json.loads(run([binary, *args]))['result']


def normalize_remote(value):
    if value.startswith('git@') and ':' in value:
        value = 'ssh://' + value.replace(':', '/', 1)
    parsed = urlsplit(value)
    return (parsed.hostname or '').lower(), parsed.path.strip('/').removesuffix('.git').lower()


def parse_pr(value, repository=None):
    if value.startswith('https://'):
        parsed = urlsplit(value)
        match = re.fullmatch(r'/([\w.-]+/[\w.-]+)/pull/(\d+)/?', parsed.path)
        if not parsed.hostname or not match:
            raise ValueError('Expected a GitHub PR URL.')
        repository = f'{parsed.hostname}/{match[1]}'
        value = match[2]
    if not value.isdecimal() or int(value) < 1:
        raise ValueError('PR must be a positive number or an HTTPS PR URL.')
    if repository and not re.fullmatch(r'(?:[\w.-]+/)?[\w.-]+/[\w.-]+', repository):
        raise ValueError('Repository must be OWNER/REPO or HOST/OWNER/REPO.')
    return int(value), repository


def checkout_candidates():
    seen = set()
    for direct in [Path.home() / 'dotfile', Path.home() / 'Documents/dotfile']:
        if direct.exists():
            seen.add(direct.resolve())
            yield direct.resolve()
    for root in [Path.home() / 'Documents/Work', Path.home() / 'Documents/Personal']:
        for directory, dirs, files in os.walk(root):
            path = Path(directory)
            if '.git' in dirs or '.git' in files:
                if path.resolve() not in seen:
                    seen.add(path.resolve())
                    yield path.resolve()
                dirs[:] = []
            elif len(path.relative_to(root).parts) >= 3:
                dirs[:] = []
            else:
                dirs[:] = [d for d in dirs if not d.startswith('.') and d not in
                           ('node_modules', 'target', 'vendor', '.venv')]


def matches_repo(repo, target):
    host, identity = ('github.com', target) if target.count('/') == 1 else target.split('/', 1)
    try:
        remotes = git(repo, 'remote').splitlines()
        return any(normalize_remote(git(repo, 'remote', 'get-url', remote)) ==
                   (host.lower(), identity.lower()) for remote in remotes)
    except subprocess.CalledProcessError:
        return False


def locate_checkout(target=None):
    try:
        current = repo_root()
        if not target or matches_repo(current, target):
            return current
    except subprocess.CalledProcessError:
        pass
    if target:
        for candidate in checkout_candidates():
            if matches_repo(candidate, target):
                return candidate
    raise RuntimeError('No local checkout found. Run hpr from the repository, or clone it under Work/Personal first.')


def prepare_pr(repo, number, target=None):
    fields = 'number,url,title,state,baseRefName,baseRefOid,headRefOid'
    command = ['gh', 'pr', 'view', str(number), '--json', fields]
    if target:
        command += ['--repo', target]
    pr = json.loads(run(command, repo))
    if pr['state'] != 'OPEN':
        raise RuntimeError('This launcher reviews open PRs. Use Octo or gh pr diff for closed/merged PRs.')
    parsed = urlsplit(pr['url'])
    identity = parsed.path.split('/pull/')[0].strip('/')
    target = parsed.hostname + '/' + identity
    info = json.loads(run(['gh', 'repo', 'view', target, '--json', 'sshUrl,url'], repo))
    remote = info['sshUrl']
    for field in ('baseRefOid', 'headRefOid'):
        if not re.fullmatch(r'[0-9a-f]{40,64}', pr[field]):
            raise RuntimeError('GitHub returned an invalid commit ID.')
    git(repo, 'fetch', '--no-tags', '--', remote, f'refs/pull/{number}/head')
    if git(repo, 'rev-parse', 'FETCH_HEAD') != pr['headRefOid']:
        raise RuntimeError('The PR changed while fetching. Rerun hpr to review its current revision.')
    git(repo, 'fetch', '--no-tags', '--', remote, 'refs/heads/' + pr['baseRefName'])
    if git(repo, 'rev-parse', 'FETCH_HEAD') != pr['baseRefOid']:
        raise RuntimeError('The base branch changed while fetching. Rerun hpr.')
    base = git(repo, 'merge-base', pr['baseRefOid'], pr['headRefOid'])
    directory = state_root() / 'reviews' / repo_key(repo) / f"pr-{number}-{pr['headRefOid'][:12]}"
    directory.parent.mkdir(parents=True, exist_ok=True)
    if directory.exists():
        if (repo_root(directory) != directory or git(directory, 'rev-parse', 'HEAD') != pr['headRefOid']
                or git(directory, 'rev-parse', '--path-format=absolute', '--git-common-dir') !=
                git(repo, 'rev-parse', '--path-format=absolute', '--git-common-dir')):
            raise RuntimeError(f'Review path exists with different content: {directory}')
    else:
        git(repo, 'worktree', 'add', '--detach', directory, pr['headRefOid'])
    metadata = dict(pr, base=base, repository=target, source_checkout=str(repo), fetched=now())
    atomic_json(private_path(directory, 'herdr-pr.json'), metadata)
    if not (task_dir(directory) / 'task.json').exists():
        start_task(directory, f"Review #{number}: {pr['title']}",
                   f"Review {pr['url']} at {pr['headRefOid']}. Report actionable findings.", base)
    return directory, metadata


def open_review(directory, metadata):
    for pane in herdr('pane', 'list')['panes']:
        if pane.get('cwd') and Path(pane['cwd']).resolve() == directory:
            herdr('workspace', 'focus', pane['workspace_id'])
            return pane['workspace_id']
    label = f"PR {metadata['repository'].split('/')[-1]}#{metadata['number']}"
    result = herdr('workspace', 'create', '--cwd', directory, '--label', label,
                   '--env', 'DOTFILES_HERDR_PROJECT_AGENT=hpr-view')
    workspace = result['workspace']['workspace_id']
    herdr('tab', 'rename', result['tab']['tab_id'], 'Review')
    herdr('tab', 'create', '--workspace', workspace, '--cwd', directory,
          '--label', 'Checks', '--no-focus', '--env', 'DOTFILES_HERDR_PROJECT_AGENT=hpr-ci')
    return workspace


def pr_command(args):
    require_herdr()
    number, target = parse_pr(args.pr, args.repo)
    repo = locate_checkout(target)
    directory, metadata = prepare_pr(repo, number, target)
    workspace = open_review(directory, metadata)
    print(f"Opened {workspace}: {directory}\nReview exact head: {metadata['headRefOid']}\n"
          'In Neovim use <leader>gR for GitHub comments. Close the inbox with q to see the workspace.')


def pr_metadata(repo):
    data = load_json(private_path(repo, 'herdr-pr.json'))
    if not data:
        raise RuntimeError('This checkout is not an hpr review worktree.')
    return data


def checks_for(repo):
    path = repo / '.herdr/checks.toml'
    if path.exists():
        checks = tomllib.loads(path.read_text()).get('checks', [])
    elif (repo / 'Cargo.toml').exists():
        checks = [dict(name='format', argv=['cargo', 'fmt', '--all', '--', '--check']),
                  dict(name='lint', argv=['cargo', 'clippy', '--all-targets', '--locked']),
                  dict(name='tests', argv=['cargo', 'test', '--locked'])]
    elif (repo / 'flake.nix').exists():
        checks = [dict(name='flake', argv=['nix', 'flake', 'check', '--no-build', '--no-write-lock-file'])]
    else:
        raise RuntimeError('Define project checks with hcheck --init, then edit .herdr/checks.toml.')
    if not isinstance(checks, list) or not checks:
        raise ValueError('checks.toml must contain at least one [[checks]] entry.')
    for check in checks:
        argv = check.get('argv')
        if not isinstance(argv, list) or not argv or not all(isinstance(x, str) and x for x in argv):
            raise ValueError('Each check needs a non-empty argv array, not a shell command string.')
    return checks


def checkout_signature(repo):
    digest = hashlib.sha256(git(repo, 'rev-parse', 'HEAD').encode())
    digest.update(subprocess.check_output(['git', '-C', str(repo), 'diff', '--no-ext-diff', '--binary', 'HEAD', '--']))
    names = subprocess.check_output(['git', '-C', str(repo), 'ls-files', '--others', '--exclude-standard', '-z'])
    for raw in names.split(b'\0'):
        if not raw:
            continue
        digest.update(raw)
        path = repo / os.fsdecode(raw)
        if path.is_symlink():
            digest.update(os.readlink(path).encode())
        elif path.is_file():
            with path.open('rb') as source:
                for chunk in iter(lambda: source.read(131072), b''):
                    digest.update(chunk)
    return digest.hexdigest()


def check_command(args):
    repo = repo_root()
    if args.init:
        path = repo / '.herdr/checks.toml'
        path.parent.mkdir(exist_ok=True)
        with path.open('x') as output:
            output.write('[[checks]]\nname = "tests"\nargv = ["replace-with-your-test-command"]\n')
        print(f'Edit {path} with this repository\'s build, lint and test commands.')
        return 0
    signature = checkout_signature(repo)
    for check in checks_for(repo):
        name = check.get('name') or check['argv'][0]
        log = task_dir(repo) / f'check-{uuid.uuid4().hex[:12]}.log'
        print(f"Running {name}: {check['argv']}", flush=True)
        with log.open('w') as output:
            try:
                process = subprocess.Popen(check['argv'], cwd=repo, stdout=subprocess.PIPE,
                                           stderr=subprocess.STDOUT, text=True)
            except OSError as error:
                output.write(str(error) + '\n')
                print(error, file=sys.stderr)
                code = 127
            else:
                try:
                    for line in process.stdout:
                        print(line, end='', flush=True)
                        output.write(line)
                    code = process.wait()
                except BaseException:
                    process.terminate()
                    process.wait()
                    raise
                finally:
                    process.stdout.close()
        entry = dict(time=now(), name=name, argv=check['argv'], exit=code, log=str(log),
                     head=git(repo, 'rev-parse', 'HEAD'), signature=signature,
                     signature_after=checkout_signature(repo))
        atomic_json(task_dir(repo) / 'latest-check.json', entry)
        update_task(repo, 'checks', entry)
        print(f'{name}: exit {code}. Log: {log}', flush=True)
        if code:
            return code
    return 0


def task_command(args):
    repo = repo_root()
    directory = task_dir(repo)
    if args.action == 'start':
        print(start_task(repo, args.name, args.goal or args.name))
    elif args.action == 'show':
        path = directory / 'SUMMARY.md'
        if not path.exists():
            raise RuntimeError('No active task. Use htask start NAME --goal TEXT.')
        print(path.read_text())
    elif args.action == 'note':
        if not (directory / 'task.json').exists():
            raise RuntimeError('No active task. Use htask start first.')
        update_task(repo, 'notes', dict(time=now(), text=args.text))
    elif args.action == 'finish':
        with locked_task(repo):
            if not (directory / 'task.json').exists():
                raise RuntimeError('No active task.')
            archive = directory / ('finished-' + uuid.uuid4().hex[:12])
            archive.mkdir()
            for name in ['task.json', 'SUMMARY.md']:
                (directory / name).rename(archive / name)
        print(f'Archived task summary: {archive / "SUMMARY.md"}')


def find_command(args):
    repo = repo_root()
    choices = []
    if args.query:
        process = subprocess.Popen(['rg', '--json', '--smart-case', '-e', args.query, '--', '.'],
                                   cwd=repo, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            for line in process.stdout:
                row = json.loads(line)
                if row['type'] == 'match':
                    data = row['data']
                    if 'text' in data['path']:
                        choices.append((data['path']['text'], data['line_number'],
                                        data['lines'].get('text', '').strip()))
                if len(choices) >= 2000:
                    process.terminate()
                    break
        finally:
            process.stdout.close()
            errors = process.stderr.read()
            process.stderr.close()
            code = process.wait()
        if code == 2:
            raise RuntimeError(errors)
    else:
        names = subprocess.check_output(['git', '-C', str(repo), 'ls-files', '-c', '-o', '--exclude-standard', '-z'])
        choices = [(os.fsdecode(name), 1, '') for name in dict.fromkeys(names.split(b'\0')) if name]
    if not choices:
        print('No matches.')
        return
    rows = '\n'.join(f'{i}\t{path!r}:{line} ' + re.sub(r'[\x00-\x1f\x7f]', ' ', preview)
                     for i, (path, line, preview) in enumerate(choices))
    result = subprocess.run(['fzf', '--delimiter', '\t', '--with-nth', '2..', '--prompt', 'Edit > '],
                            input=rows, capture_output=True, text=True)
    if result.returncode:
        if result.returncode not in (1, 130):
            raise RuntimeError(result.stderr)
        return
    path, line, _ = choices[int(result.stdout.split('\t', 1)[0])]
    subprocess.run(['nvim', f'+{line}', '--', str(repo / path)], check=True)


def reviewer_prompt(repo, requirements):
    metadata = load_json(private_path(repo, 'herdr-pr.json'))
    baseline = private_path(repo, 'herdr-review-base')
    base = metadata['base'] if metadata else baseline.read_text().strip() if baseline.exists() else 'HEAD'
    summary = task_dir(repo) / 'SUMMARY.md'
    checks = load_json(task_dir(repo) / 'latest-check.json')
    evidence = json.dumps(checks) if checks else 'No recorded checks.'
    if checks and checks.get('signature_after') != checkout_signature(repo):
        evidence += '\nThe checkout has changed since these checks.'
    return (f'Review only, do not edit files or submit GitHub comments. Checkout: {repo}. '
            f'Compare {base} to HEAD and include current staged, unstaged and untracked changes. '
            f'Requirements: {requirements or "Report actionable correctness and regression findings."}\n'
            f'Task context: {summary if summary.exists() else "No task summary."}\n'
            f'Validation evidence: {evidence}\n'
            'Read relevant code and report actionable findings with file/line references and supporting reasoning. '
            'State any unverified assumptions. Do not treat idle status as proof of passing tests.')


def reviewer_command(args):
    require_herdr()
    repo = repo_root()
    kind = args.kind
    if not kind:
        work = (Path.home() / 'Documents/Work').resolve()
        metadata = load_json(private_path(repo, 'herdr-pr.json'), {})
        source = Path(metadata.get('source_checkout', repo)).resolve()
        kind = 'claude' if source.is_relative_to(work) else 'codex'
    prompt = reviewer_prompt(repo, args.requirements)
    current = herdr('pane', 'current', '--current')['pane']['pane_id']
    layout = herdr('pane', 'layout', '--pane', current)['layout']
    rect = next(p['rect'] for p in layout['panes'] if p['pane_id'] == current)
    direction = 'right' if rect['width'] >= 160 else 'down'
    pane = herdr('pane', 'split', '--pane', current, '--direction', direction,
                 '--cwd', repo, '--no-focus')['pane']['pane_id']
    name = 'reviewer-' + uuid.uuid4().hex[:8]
    print(f'Reviewer: {name}, pane: {pane}', flush=True)
    native = ['--sandbox', 'read-only'] if kind == 'codex' else ['--permission-mode', 'plan']
    try:
        herdr('agent', 'start', name, '--kind', kind, '--pane', pane, '--', *native)
        herdr('agent', 'prompt', name, prompt, '--wait', '--timeout', str(args.timeout))
    except subprocess.CalledProcessError as error:
        print(error.stderr or str(error), file=sys.stderr)
        print(f'The reviewer may need attention. Inspect {pane}; do not resend the task blindly.', file=sys.stderr)
        return 1
    status = herdr('agent', 'get', name)['agent']['agent_status']
    binary = os.environ.get('HERDR_BIN_PATH') or '/opt/homebrew/bin/herdr'
    output = run([binary, 'agent', 'read', name, '--source', 'recent-unwrapped', '--lines', '160'])
    path = task_dir(repo) / f'{name}.md'
    path.write_text(output + '\n')
    update_task(repo, 'reviews', dict(time=now(), agent=name, status=status, path=str(path)))
    print(output)
    print(f'Captured reviewer transcript: {path}\nState: {status}. Check findings against the actual diff.')
    return 0 if status in ('done', 'idle') else 1


def main():
    parser = argparse.ArgumentParser(prog="herdr-workflow", description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    commands.add_parser('inbox')
    pr = commands.add_parser('pr')
    pr.add_argument('pr'); pr.add_argument('--repo')
    commands.add_parser('pr-view'); commands.add_parser('pr-ci')
    checks = commands.add_parser('check'); checks.add_argument('--init', action='store_true')
    find = commands.add_parser('find'); find.add_argument('query', nargs='?')
    task = commands.add_parser('task').add_subparsers(dest='action', required=True)
    start = task.add_parser('start'); start.add_argument('name'); start.add_argument('--goal')
    task.add_parser('show'); task.add_parser('finish')
    note = task.add_parser('note'); note.add_argument('text')
    reviewer = commands.add_parser('reviewer')
    reviewer.add_argument('--kind', choices=['codex', 'claude'])
    reviewer.add_argument('--requirements', default='')
    reviewer.add_argument('--timeout', type=int, default=120000)
    args = parser.parse_args()
    if args.command == 'inbox':
        config = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config')) / 'gh-dash/config.yml'
        return subprocess.run(['gh-dash', '--config', str(config)], cwd=Path.home()).returncode
    if args.command == 'pr':
        return pr_command(args)
    if args.command == 'pr-view':
        repo = repo_root(); data = pr_metadata(repo)
        return subprocess.run(['nvim', '-c', f"DiffviewOpen {data['base']}..{data['headRefOid']}"], cwd=repo).returncode
    if args.command == 'pr-ci':
        repo = repo_root(); data = pr_metadata(repo)
        return subprocess.run(['gh', 'pr', 'checks', str(data['number']), '--repo', data['repository']], cwd=repo).returncode
    if args.command == 'check':
        return check_command(args)
    if args.command == 'find':
        return find_command(args)
    if args.command == 'task':
        return task_command(args)
    return reviewer_command(args)


if __name__ == '__main__':
    try:
        sys.exit(main() or 0)
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.CalledProcessError) as error:
        detail = error.stderr if isinstance(error, subprocess.CalledProcessError) else str(error)
        print(detail or str(error), file=sys.stderr)
        if sys.stdin.isatty() and sys.stderr.isatty():
            input('Press Enter to close. ')
        sys.exit(1)
    except KeyboardInterrupt:
        sys.exit(130)
