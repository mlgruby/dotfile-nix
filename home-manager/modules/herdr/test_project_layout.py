#!/usr/bin/env python3
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import sqlite3
import tempfile
import unittest

SOURCE = Path(__file__).with_name('project-layout.py')
spec = importlib.util.spec_from_file_location('project_layout', SOURCE)
layout = importlib.util.module_from_spec(spec)
spec.loader.exec_module(layout)


class LayoutTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='herdr-layout-', dir='/private/tmp')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.work = self.root / 'Work'
        self.repo = self.work / 'repo with spaces'
        self.repo.mkdir(parents=True)
        subprocess.run(['git', 'init', str(self.repo)], check=True, capture_output=True)
        self.config = self.root / 'claude'
        self.project = self.config / 'projects' / re.sub(r'[^a-zA-Z0-9]', '-', str(self.repo))
        self.project.mkdir(parents=True)
        self.tabs = [{'tab_id': 'w1:t1'}]
        self.panes = [{'pane_id': 'w1:p1', 'cwd': str(self.repo)}]
        self.calls = []

    def call(self, *args):
        self.calls.append(args)
        if args[:2] == ('tab', 'list'):
            return {'tabs': self.tabs}
        if args[:2] == ('pane', 'list'):
            return {'panes': self.panes}
        if args[:2] == ('tab', 'create'):
            self.tabs.append({'tab_id': 'w1:t2'})
            self.panes.append({'pane_id': 'w1:p2'})
        return {}

    def apply(self):
        return layout.apply_layout('w1', self.call, self.work, self.config,
                                   personal_root=self.root / 'Personal',
                                   dotfile_roots=[self.root / 'dotfile', self.root / 'Documents/dotfile'],
                                   codex_home=self.root / 'codex', agy_home=self.root / 'agy')

    def test_new_project_creates_exactly_two_tabs_and_cc(self):
        self.assertTrue(self.apply())
        self.assertEqual(len(self.tabs), 2)
        self.assertIn(('tab', 'rename', 'w1:t1', 'Shell'), self.calls)
        create = [c for c in self.calls if c[:2] == ('tab', 'create')][0]
        self.assertIn('CC', create)
        self.assertIn('DOTFILES_HERDR_PROJECT_AGENT=cc', create)
        self.assertIn('--no-focus', create)
        self.assertFalse(self.apply())
        self.assertEqual(len(self.tabs), 2)

    def test_history_selects_ccr_and_ignores_unrelated_or_subagent_records(self):
        records = [{'type': 'file-history-snapshot'},
                   {'type': 'user', 'isSidechain': True, 'cwd': str(self.repo)},
                   {'type': 'user', 'cwd': str(self.work / 'other')}]
        transcript = self.project / 'session.jsonl'
        transcript.write_text('\n'.join(json.dumps(r) for r in records))
        self.assertEqual(layout.claude_command(self.repo, self.config), 'cc')
        with transcript.open('a') as output:
            output.write('\nnot json\n' + json.dumps({'type': 'user', 'cwd': str(self.repo)}))
        self.assertEqual(layout.claude_command(self.repo, self.config), 'ccr')

    def test_non_repo_personal_and_similarly_named_work_roots_are_untouched(self):
        for directory in [self.root / 'Personal/repo', self.root / 'Work-other/repo']:
            directory.mkdir(parents=True)
            self.panes[0]['cwd'] = str(directory)
            self.assertFalse(self.apply())
        self.assertFalse(any(c[1] in ('rename', 'create') for c in self.calls))

    def test_existing_agents_or_multiple_tabs_are_untouched(self):
        self.panes[0]['agent'] = 'claude'
        self.assertFalse(self.apply())
        del self.panes[0]['agent']
        self.tabs.append({'tab_id': 'w1:t2'})
        self.assertFalse(self.apply())
        self.assertFalse(any(c[1] in ('rename', 'create') for c in self.calls))

    def test_non_git_directory_is_untouched(self):
        directory = self.work / 'not-a-repo'
        directory.mkdir()
        self.panes[0]['cwd'] = str(directory)
        self.assertFalse(self.apply())

    def personal_repo(self, path=None):
        self.repo = path or self.root / 'Personal/repo with spaces'
        self.repo.mkdir(parents=True)
        subprocess.run(['git', 'init', str(self.repo)], check=True, capture_output=True)
        self.panes[0]['cwd'] = str(self.repo)

    def seed_codex(self, archived=0, source='cli'):
        home = self.root / 'codex'
        home.mkdir(exist_ok=True)
        with sqlite3.connect(home / 'state_5.sqlite') as db:
            db.execute('CREATE TABLE IF NOT EXISTS threads(cwd TEXT, source TEXT, archived INTEGER, has_user_event INTEGER)')
            db.execute('INSERT INTO threads VALUES(?,?,?,0)', (str(self.repo), source, archived))

    def seed_agy(self, content='A saved user conversation'):
        home = self.root / 'agy'
        conversations = home / 'conversations'
        conversations.mkdir(parents=True, exist_ok=True)
        uri = self.repo.as_uri().encode()
        length = len(uri)
        prefix = bytearray()
        while length > 127:
            prefix.append((length & 127) | 128)
            length >>= 7
        prefix.append(length)
        with sqlite3.connect(conversations / 'test-session.db') as db:
            db.execute('CREATE TABLE trajectory_metadata_blob(data BLOB)')
            db.execute('INSERT INTO trajectory_metadata_blob VALUES(?)', (b'\x0a' + bytes(prefix) + uri + b'\x12\x01x',))
        transcript = home / 'brain/test-session/.system_generated/logs/transcript.jsonl'
        transcript.parent.mkdir(parents=True)
        transcript.write_text(json.dumps({'type': 'USER_INPUT', 'content': content}) + '\n')
        return conversations / 'test-session.db'

    def assert_personal_layout(self, agy, codex):
        self.personal_repo()
        if agy:
            self.seed_agy()
        if codex:
            self.seed_codex()
        self.assertTrue(self.apply())
        created = [c for c in self.calls if c[:2] == ('tab', 'create')]
        self.assertEqual([c[c.index('--label') + 1] for c in created],
                         (['AGY'] if agy else []) + (['CX'] if codex else []))
        self.assertEqual([c[-1] for c in created],
                         (['DOTFILES_HERDR_PROJECT_AGENT=agr'] if agy else []) +
                         (['DOTFILES_HERDR_PROJECT_AGENT=cxr'] if codex else []))
        self.assertIn(('tab', 'rename', 'w1:t1', 'Shell'), self.calls)
        self.assertEqual(len(self.tabs), 1 + agy + codex)

    def test_personal_no_history(self):
        self.assert_personal_layout(False, False)

    def test_personal_agy_only(self):
        self.assert_personal_layout(True, False)

    def test_personal_codex_only(self):
        self.assert_personal_layout(False, True)

    def test_personal_both_histories(self):
        self.assert_personal_layout(True, True)

    def test_dotfile_checkout_is_included(self):
        self.personal_repo(self.root / 'dotfile')
        self.seed_codex()
        self.assertTrue(self.apply())
        self.assertEqual(len(self.tabs), 2)
        self.assertEqual(self.calls[-1][-1], 'DOTFILES_HERDR_PROJECT_AGENT=cxr')

    def test_archived_and_subagent_codex_histories_are_excluded(self):
        self.personal_repo()
        self.seed_codex(archived=1)
        self.seed_codex(source='{"subagent":"review"}')
        self.assertFalse(layout.has_codex_history(self.repo, self.root / 'codex'))

    def test_codex_rollout_fallback(self):
        self.personal_repo()
        home = self.root / 'codex'
        sessions = home / 'sessions/2026/11/11'
        sessions.mkdir(parents=True)
        (sessions / 'test.jsonl').write_text(json.dumps({'type': 'session_meta', 'payload':
            {'cwd': str(self.repo), 'source': 'cli'}}) + '\n')
        self.assertTrue(layout.has_codex_history(self.repo, home))

    def test_agy_requires_usable_transcript(self):
        self.personal_repo()
        database = self.seed_agy(content='USER_SETTINGS_CHANGE')
        self.assertEqual(layout.agy_directory(database), self.repo)
        self.assertFalse(layout.has_agy_history(self.repo, self.root / 'agy'))

    def test_agy_long_paths_spaces_and_unicode(self):
        self.personal_repo(self.root / 'Personal' / ('very long project ' * 8 + 'é'))
        database = self.seed_agy()
        self.assertEqual(layout.agy_directory(database), self.repo)
        self.assertTrue(layout.has_agy_history(self.repo, self.root / 'agy'))


if __name__ == '__main__':
    unittest.main()
