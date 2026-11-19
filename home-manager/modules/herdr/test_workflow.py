import argparse
from contextlib import redirect_stdout
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
        self.env = patch.dict(os.environ, {'XDG_STATE_HOME': str(self.root / 'state')})
        self.env.start(); self.addCleanup(self.env.stop)
        # The commands act on the current directory's repository.
        previous = os.getcwd(); os.chdir(self.repo); self.addCleanup(os.chdir, previous)
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

    def test_inbox_uses_managed_config_outside_current_repo(self):
        with patch.object(subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)) as execute:
            with patch.object(sys, 'argv', ['herdr-workflow', 'inbox']):
                self.assertEqual(w.main(), 0)
        argv = execute.call_args.args[0]
        self.assertEqual(argv[:2], ['gh-dash', '--config'])
        self.assertEqual(execute.call_args.kwargs['cwd'], Path.home())

    def test_project_list_prints_groups(self):
        home = self.root / 'home'
        for rel in ('dotfile', 'Documents/Work/api', 'Documents/Personal/site'):
            (home / rel / '.git').mkdir(parents=True)
        out = io.StringIO()
        with patch.object(Path, 'home', return_value=home), redirect_stdout(out):
            w.project_command(argparse.Namespace(list=True))
        groups = {p['name']: p['group'] for p in json.loads(out.getvalue())}
        self.assertEqual(groups, {'dotfile': 'dotfile', 'api': 'work', 'site': 'personal'})


if __name__ == '__main__':
    unittest.main()
