import argparse
from contextlib import redirect_stdout, redirect_stderr
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).with_name('workflow.py')
spec = importlib.util.spec_from_file_location('workflow', SOURCE)
w = importlib.util.module_from_spec(spec)
spec.loader.exec_module(w)


class WorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='herdr-workflow-test-', dir='/private/tmp')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / 'repo with spaces'
        self.repo.mkdir()
        self.env = patch.dict(os.environ, {'XDG_STATE_HOME': str(self.root / 'state'),
                                         'HERDR_ENV': '1',
                                         'HERDR_ACTIVE_PANE_CWD': str(self.repo)})
        self.env.start(); self.addCleanup(self.env.stop)
        self.git('init', '--initial-branch=main')
        self.git('config', 'user.name', 'Test')
        self.git('config', 'user.email', 'test@example.test')
        self.git('config', 'commit.gpgsign', 'false')
        (self.repo / 'file.txt').write_text('initial\n')
        self.git('add', '.'); self.git('commit', '-m', 'initial')
        self.base = self.git('rev-parse', 'HEAD')

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.repo), *args],
                                       stderr=subprocess.STDOUT, text=True).strip()

    def make_pr(self):
        self.git('checkout', '-b', 'feature')
        (self.repo / 'file.txt').write_text('feature\n')
        self.git('commit', '-am', 'feature')
        self.head = self.git('rev-parse', 'HEAD')
        self.git('checkout', 'main')
        self.remote = self.root / 'remote.git'
        subprocess.run(['git', 'clone', '--bare', str(self.repo), str(self.remote)],
                       check=True, capture_output=True)
        subprocess.run(['git', '--git-dir', str(self.remote), 'update-ref',
                        'refs/pull/7/head', self.head], check=True)
        self.pr = dict(number=7, url='https://github.com/example/repo/pull/7', title='Test PR',
                       state='OPEN', baseRefName='main', baseRefOid=self.base, headRefOid=self.head)
        original = w.run

        def fake_gh(argv, cwd=None, **kwargs):
            if argv[:3] == ['gh', 'pr', 'view']:
                return json.dumps(self.pr)
            if argv[:3] == ['gh', 'repo', 'view']:
                return json.dumps(dict(sshUrl=str(self.remote), url='https://github.com/example/repo'))
            return original(argv, cwd, **kwargs)
        self.gh = patch.object(w, 'run', side_effect=fake_gh)
        self.gh.start(); self.addCleanup(self.gh.stop)

    def test_pr_worktree_pins_revision_and_preserves_dirty_checkout(self):
        self.make_pr()
        (self.repo / 'file.txt').write_text('existing dirty change\n')
        signature = w.checkout_signature(self.repo)
        directory, data = w.prepare_pr(self.repo, 7)
        self.assertEqual(self.git('rev-parse', 'HEAD'), self.base)
        self.assertEqual(w.checkout_signature(self.repo), signature)
        self.assertEqual(w.git(directory, 'rev-parse', 'HEAD'), self.head)
        self.assertEqual(data['base'], self.base)
        self.assertEqual(w.private_path(directory, 'herdr-review-base').read_text().strip(), self.base)
        reused, _ = w.prepare_pr(self.repo, 7)
        self.assertEqual(reused, directory)
        self.assertTrue((w.task_dir(directory) / 'SUMMARY.md').exists())

    def test_pr_revision_race_fails_before_creating_worktree(self):
        self.make_pr()
        tree = self.git('rev-parse', self.head + '^{tree}')
        changed = self.git('commit-tree', tree, '-p', self.head, '-m', 'changed while fetching')
        self.git('push', str(self.remote), changed + ':refs/pull/7/head')
        with self.assertRaisesRegex(RuntimeError, 'PR changed'):
            w.prepare_pr(self.repo, 7)
        self.assertEqual(self.git('worktree', 'list', '--porcelain').count('worktree '), 1)

    def test_merged_pr_does_not_fetch_or_create_worktree(self):
        self.make_pr(); self.pr['state'] = 'MERGED'
        with self.assertRaisesRegex(RuntimeError, 'open PRs'):
            w.prepare_pr(self.repo, 7)

    def test_review_workspace_is_reused(self):
        data = dict(repository='github.com/example/repo', number=7)
        calls = []
        def api(*args):
            calls.append(args)
            if args[:2] == ('pane', 'list'):
                return dict(panes=[dict(cwd=str(self.repo), workspace_id='existing')])
            return {}
        with patch.object(w, 'herdr', side_effect=api):
            self.assertEqual(w.open_review(self.repo, data), 'existing')
        self.assertEqual(calls[-1], ('workspace', 'focus', 'existing'))
        self.assertFalse(any(c[:2] == ('workspace', 'create') for c in calls))

    def test_new_review_workspace_has_two_tabs_and_deferred_views(self):
        calls = []
        def api(*args):
            calls.append(args)
            if args[:2] == ('pane', 'list'):
                return dict(panes=[])
            if args[:2] == ('workspace', 'create'):
                return dict(workspace=dict(workspace_id='new'), tab=dict(tab_id='new:t1'))
            return {}
        with patch.object(w, 'herdr', side_effect=api):
            self.assertEqual(w.open_review(self.repo, dict(repository='x/y', number=7)), 'new')
        self.assertIn('DOTFILES_HERDR_PROJECT_AGENT=hpr-view', calls[1])
        self.assertIn(('tab', 'rename', 'new:t1', 'Review'), calls)
        self.assertIn('DOTFILES_HERDR_PROJECT_AGENT=hpr-ci', calls[-1])

    def test_popup_ai_action_targets_selected_worktree_and_returns_without_waiting(self):
        args = argparse.Namespace(pr='7', repo='example/repo', ai_review=True)
        data = dict(headRefOid=self.base)
        with patch.object(w, 'locate_checkout', return_value=self.repo), \
             patch.object(w, 'prepare_pr', return_value=(self.repo, data)), \
             patch.object(w, 'open_review', return_value='review-workspace'), \
             patch.object(w, 'open_ai_review') as launch, \
             patch.object(w, 'reviewer_command') as reviewer, redirect_stdout(io.StringIO()):
            w.pr_command(args)
        launch.assert_called_once_with(self.repo, 'review-workspace')
        reviewer.assert_not_called()

    def test_ai_tab_is_deferred_and_repeated_actions_reuse_it(self):
        calls = []; tabs = []
        def api(*args):
            calls.append(args)
            if args[:2] == ('tab', 'list'):
                return dict(tabs=tabs)
            if args[:2] == ('tab', 'create'):
                tabs.append(dict(label='AI Review', tab_id='review:t3'))
            return {}
        with patch.object(w, 'herdr', side_effect=api):
            w.open_ai_review(self.repo, 'review')
            w.open_ai_review(self.repo, 'review')
        created = [c for c in calls if c[:2] == ('tab', 'create')]
        self.assertEqual(len(created), 1)
        self.assertIn(self.repo, created[0])
        self.assertIn('DOTFILES_HERDR_PROJECT_AGENT=hpr-ai-review', created[0])
        self.assertEqual(calls[-1], ('tab', 'focus', 'review:t3'))

    def test_deferred_ai_review_ignores_original_popup_directory(self):
        with patch.object(Path, 'cwd', return_value=self.repo), \
             patch.object(w, 'repo_root', return_value=self.repo) as root, \
             patch.object(w, 'pr_metadata'), patch.object(w, 'reviewer_command', return_value=0) as reviewer, \
             patch.object(sys, 'argv', ['herdr-workflow', 'pr-ai-review']):
            self.assertEqual(w.main(), 0)
        root.assert_called_once_with(self.repo)
        self.assertEqual(reviewer.call_args.kwargs['repo'], self.repo)

    def test_pr_prompt_includes_body_and_dependabot_checks(self):
        w.atomic_json(w.private_path(self.repo, 'herdr-pr.json'),
                      dict(base=self.base, url='https://github.com/example/repo/pull/7',
                           title='Upgrade package', body='Migration notes', author=dict(login='app/dependabot')))
        prompt = w.reviewer_prompt(self.repo, '')
        for expected in ('Migration notes', 'breaking changes', 'lockfile consistency',
                         'repository instructions', 'severity', 'suggested fixes',
                         'do not edit files or submit GitHub comments'):
            self.assertIn(expected, prompt)

    def test_task_context_preserves_notes_and_requires_explicit_finish(self):
        (self.repo / 'file.txt').write_text('pre-existing\n')
        path = w.start_task(self.repo, 'A task', 'Do the requested work')
        with self.assertRaisesRegex(RuntimeError, 'active task'):
            w.start_task(self.repo, 'replacement', 'Do not overwrite')
        w.update_task(self.repo, 'notes', dict(time=w.now(), text='Verified decision'))
        self.assertIn('Pre-existing checkout changes', path.read_text())
        self.assertIn('Verified decision', path.read_text())
        with redirect_stdout(io.StringIO()):
            w.task_command(argparse.Namespace(action='finish'))
        self.assertFalse(path.exists())
        self.assertEqual(len(list(w.task_dir(self.repo).glob('finished-*/SUMMARY.md'))), 1)

    def test_checks_stop_on_failure_and_record_actual_exit_and_log(self):
        directory = self.repo / '.herdr'; directory.mkdir()
        config = ('[[checks]]\nname="failure"\nargv=' + json.dumps(
            [sys.executable, '-c', 'print("real check output"); raise SystemExit(3)']) +
            '\n[[checks]]\nname="must not run"\nargv=' + json.dumps(
            [sys.executable, '-c', 'open("unexpected", "w").write("bad")']) + '\n')
        (directory / 'checks.toml').write_text(config)
        w.start_task(self.repo, 'checks', 'Validate')
        with redirect_stdout(io.StringIO()):
            self.assertEqual(w.check_command(argparse.Namespace(init=False)), 3)
        result = w.load_json(w.task_dir(self.repo) / 'latest-check.json')
        self.assertEqual(result['exit'], 3)
        self.assertIn('real check output', Path(result['log']).read_text())
        self.assertFalse((self.repo / 'unexpected').exists())
        self.assertIn('exit 3', (w.task_dir(self.repo) / 'SUMMARY.md').read_text())

    def test_signature_detects_content_change_with_same_git_status(self):
        file = self.repo / 'file.txt'; file.write_text('first\n')
        first = w.checkout_signature(self.repo)
        file.write_text('second\n')
        self.assertNotEqual(first, w.checkout_signature(self.repo))

    def test_search_opens_exact_filename_as_argument(self):
        name = 'a: spaced file.py'; (self.repo / name).write_text('print(1)\n')
        original = subprocess.run; opened = []
        def fake_run(argv, **kwargs):
            if argv[0] == 'fzf':
                row = next(r for r in kwargs['input'].splitlines() if name in r)
                return subprocess.CompletedProcess(argv, 0, row + '\n', '')
            if argv[0] == 'nvim':
                opened.append(argv)
                return subprocess.CompletedProcess(argv, 0)
            return original(argv, **kwargs)
        with patch.object(subprocess, 'run', side_effect=fake_run):
            w.find_command(argparse.Namespace(query=None))
        self.assertEqual(opened, [['nvim', '+1', '--', str(self.repo / name)]])

    def test_reviewer_uses_read_only_mode_and_collects_output(self):
        w.start_task(self.repo, 'review', 'Review changes')
        original = w.run; calls = []
        def api(*args):
            calls.append(args)
            if args[:2] == ('pane', 'current'):
                return dict(pane=dict(pane_id='caller'))
            if args[:2] == ('pane', 'layout'):
                return dict(layout=dict(panes=[dict(pane_id='caller', rect=dict(width=100, height=40))]))
            if args[:2] == ('pane', 'split'):
                return dict(pane=dict(pane_id='helper'))
            if args[:2] == ('agent', 'get'):
                return dict(agent=dict(agent_status='idle'))
            return {}
        def read(argv, cwd=None, **kwargs):
            if len(argv) > 2 and argv[1:3] == ['agent', 'read']:
                return 'Actionable reviewer findings'
            return original(argv, cwd, **kwargs)
        with patch.object(w, 'herdr', side_effect=api), patch.object(w, 'run', side_effect=read), redirect_stdout(io.StringIO()):
            self.assertEqual(w.reviewer_command(argparse.Namespace(kind='codex', requirements='Check edge cases', timeout=120000)), 0)
        start = next(c for c in calls if c[:2] == ('agent', 'start'))
        self.assertEqual(start[-3:], ('--', '--sandbox', 'read-only'))
        split = next(c for c in calls if c[:2] == ('pane', 'split'))
        self.assertIn('down', split); self.assertIn('--no-focus', split)
        task = w.load_json(w.task_dir(self.repo) / 'task.json')
        self.assertEqual(len(task['reviews']), 1)
        self.assertIn('Actionable', Path(task['reviews'][0]['path']).read_text())

    def test_pr_input_and_ssh_remote_normalization(self):
        self.assertEqual(w.parse_pr('https://github.com/a/b/pull/23'), (23, 'github.com/a/b'))
        self.assertEqual(w.normalize_remote('git@github.com:a/b.git'), ('github.com', 'a/b'))
        with self.assertRaises(ValueError):
            w.parse_pr('7; echo bad')

    def test_inbox_uses_managed_config_outside_current_repo(self):
        with patch.object(subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)) as execute:
            with patch.object(sys, 'argv', ['herdr-workflow', 'inbox']):
                self.assertEqual(w.main(), 0)
        argv = execute.call_args.args[0]
        self.assertEqual(argv[:2], ['gh-dash', '--config'])
        self.assertEqual(execute.call_args.kwargs['cwd'], Path.home())

    def test_project_launcher_delegates_tab_creation_to_one_layout_driver(self):
        calls = []
        original = w.run
        def api(*args):
            calls.append(args)
            if args[:2] == ('workspace', 'create'):
                return dict(workspace=dict(workspace_id='new-project'), tab=dict(tab_id='new-project:t1'))
            return {}
        def execute(argv, cwd=None, **kwargs):
            if argv[0] == 'herdr-project-layout':
                calls.append(tuple(argv))
                return ''
            return original(argv, cwd, **kwargs)
        with patch.object(w, 'herdr', side_effect=api), patch.object(w, 'run', side_effect=execute), redirect_stdout(io.StringIO()):
            w.project_command(argparse.Namespace(directory=str(self.repo)))
        self.assertIn(('tab', 'rename', 'new-project:t1', 'Shell'), calls)
        self.assertEqual(sum(c[0] == 'herdr-project-layout' for c in calls), 1)
        self.assertFalse(any(c[:2] == ('tab', 'create') for c in calls))

    def test_loaded_p_shim_uses_updated_launcher_without_shell_reload(self):
        source = Path(__file__).parents[2] / 'scripts/zsh-integration.zsh'
        text = source.read_text()
        start = text.index('function p() {')
        end = text.index('\n# ==============================================================================', start)
        shim = text[start:end]
        directory = self.root / 'bin'; directory.mkdir()
        executable = directory / 'herdr-project-open'
        executable.write_text('#!/bin/sh\nprintf "version-one\\n"\n')
        executable.chmod(0o755)
        script = shim + '''
p first
printf '%s\\n' '#!/bin/sh' 'printf "version-two\\n"' > "$1/herdr-project-open"
p second
'''
        env = dict(os.environ, PATH=str(directory) + os.pathsep + os.environ['PATH'])
        result = subprocess.check_output(['zsh', '-f', '-c', script, '_', str(directory)], env=env, text=True)
        self.assertEqual(result.splitlines(), ['version-one', 'version-two'])


if __name__ == '__main__':
    unittest.main()
