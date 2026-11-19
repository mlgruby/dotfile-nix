#!/usr/bin/env python3
import importlib.util
import json
import os
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

    def plan(self, directory=None):
        return layout.plan_agents(directory or self.repo, self.work, self.config,
                                  personal_root=self.root / 'Personal',
                                  dotfile_roots=[self.root / 'dotfile', self.root / 'Documents/dotfile'],
                                  codex_home=self.root / 'codex', agy_home=self.root / 'agy')

    def test_new_work_project_gets_cc(self):
        self.assertEqual(self.plan(), [('CC', 'cc')])

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
            self.assertIsNone(self.plan(directory))

    def test_non_git_directory_is_untouched(self):
        directory = self.work / 'not-a-repo'
        directory.mkdir()
        self.assertIsNone(self.plan(directory))

    def personal_repo(self, path=None):
        self.repo = path or self.root / 'Personal/repo with spaces'
        self.repo.mkdir(parents=True)
        subprocess.run(['git', 'init', str(self.repo)], check=True, capture_output=True)

    def seed_codex(self, archived=0, source='cli', rollout=True):
        home = self.root / 'codex'
        home.mkdir(exist_ok=True)
        path = home / f'sessions/rollout-{archived}-{len(source)}.jsonl'
        if rollout:
            path.parent.mkdir(exist_ok=True)
            path.write_text('{}\n')
        with sqlite3.connect(home / 'state_5.sqlite') as db:
            db.execute('CREATE TABLE IF NOT EXISTS threads(cwd TEXT, source TEXT, archived INTEGER, has_user_event INTEGER, rollout_path TEXT)')
            db.execute('INSERT INTO threads VALUES(?,?,?,0,?)', (str(self.repo), source, archived, str(path)))

    def seed_agy(self, content='A saved user conversation', session_id='test-session',
                 repo=None, create_transcript=True):
        home = self.root / 'agy'
        conversations = home / 'conversations'
        conversations.mkdir(parents=True, exist_ok=True)
        uri = (repo or self.repo).as_uri().encode()
        length = len(uri)
        prefix = bytearray()
        while length > 127:
            prefix.append((length & 127) | 128)
            length >>= 7
        prefix.append(length)
        db_path = conversations / f'{session_id}.db'
        with sqlite3.connect(db_path) as db:
            db.execute('CREATE TABLE trajectory_metadata_blob(data BLOB)')
            db.execute('INSERT INTO trajectory_metadata_blob VALUES(?)', (b'\x0a' + bytes(prefix) + uri + b'\x12\x01x',))
        if create_transcript:
            transcript = home / 'brain' / session_id / '.system_generated/logs/transcript.jsonl'
            transcript.parent.mkdir(parents=True)
            transcript.write_text(json.dumps({'type': 'USER_INPUT', 'content': content}) + '\n')
        return db_path

    def assert_personal_layout(self, agy, codex):
        self.personal_repo()
        if agy:
            self.seed_agy()
        if codex:
            self.seed_codex()
        self.assertEqual(self.plan(), (([('AGY', 'agr')] if agy else []) +
                                       ([('CX', 'cxr')] if codex else [])))

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
        self.assertEqual(self.plan(), [('CX', 'cxr')])

    def test_archived_and_subagent_codex_histories_are_excluded(self):
        self.personal_repo()
        self.seed_codex(archived=1)
        self.seed_codex(source='{"subagent":"review"}')
        self.assertFalse(layout.has_codex_history(self.repo, self.root / 'codex'))

    def test_codex_thread_without_rollout_file_is_excluded(self):
        self.personal_repo()
        self.seed_codex(rollout=False)
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

    def test_agy_multiline_request_tag_and_missing_transcript(self):
        self.personal_repo()
        self.seed_agy(session_id='missing', create_transcript=False)
        self.assertFalse(layout.has_agy_history(self.repo, self.root / 'agy'))
        self.seed_agy(session_id='wrapped', content='<USER_REQUEST>\nhello\tworld\n</USER_REQUEST>')
        self.assertTrue(layout.has_agy_history(self.repo, self.root / 'agy'))

    def test_list_agy_conversations_filters_sorts_and_formats(self):
        self.personal_repo()
        other_repo = self.root / 'Personal/other-repo'
        other_repo.mkdir(parents=True)
        older = self.seed_agy(content='first\tprompt', session_id='older-id', repo=self.repo)
        newer = self.seed_agy(content='second prompt ' + ('x' * 90), session_id='newer-id', repo=self.repo)
        other = self.seed_agy(content='other repo task', session_id='other-id', repo=other_repo)
        self.seed_agy(content='USER_SETTINGS_CHANGE', session_id='ignored-id', repo=self.repo)

        os.utime(older, (1700000000, 1700000000))
        os.utime(newer, (1700003600, 1700003600))
        os.utime(other, (1700007200, 1700007200))

        agy_home = self.root / 'agy'
        scoped = layout.list_agy_conversations(cwd=self.repo, show_all=False, agy_home=agy_home)
        self.assertEqual(len(scoped), 2)
        self.assertTrue(scoped[0].endswith('| newer-id'))
        self.assertTrue(scoped[1].endswith('| older-id'))
        self.assertIn('first prompt', scoped[1])
        self.assertEqual(len(scoped[0].split(' | ')[1].rstrip()), 80)

        all_rows = layout.list_agy_conversations(cwd=self.repo, show_all=True,
                                                 agy_home=agy_home, home_dir=self.root)
        self.assertEqual(len(all_rows), 3)
        self.assertTrue(all_rows[0].endswith('| other-id'))
        self.assertIn('~/Personal/other-repo', all_rows[0])

    def test_cli_agy_list_mode(self):
        self.personal_repo()
        self.seed_agy(content='cli check prompt', session_id='cli-id', repo=self.repo)
        fake_home = self.root / 'fake-home'
        (fake_home / '.gemini').mkdir(parents=True)
        (fake_home / '.gemini/antigravity-cli').symlink_to(self.root / 'agy')
        env = dict(os.environ, HOME=str(fake_home))
        result = subprocess.run(
            ['python3', str(SOURCE), '--agy-list', str(self.repo)],
            capture_output=True, text=True, check=True, env=env,
        )
        self.assertIn('cli check prompt', result.stdout)
        self.assertTrue(result.stdout.strip().endswith('| cli-id'))

    def test_agy_long_paths_spaces_and_unicode(self):
        self.personal_repo(self.root / 'Personal' / ('very long project ' * 8 + 'é'))
        database = self.seed_agy()
        self.assertEqual(layout.agy_directory(database), self.repo)
        self.assertTrue(layout.has_agy_history(self.repo, self.root / 'agy'))

    def test_plan_matches_layout_rule(self):
        roots = dict(personal_root=self.root / 'Personal', dotfile_roots=[],
                     codex_home=self.root / 'codex', agy_home=self.root / 'agy')
        self.assertEqual(layout.plan_agents(self.repo, self.work, self.config, **roots), [('CC', 'cc')])
        personal = self.root / 'Personal/app'
        personal.mkdir(parents=True)
        self.assertIsNone(layout.plan_agents(personal, self.work, self.config, **roots))
        subprocess.run(['git', 'init', str(personal)], check=True, capture_output=True)
        self.assertEqual(layout.plan_agents(personal, self.work, self.config, **roots), [])


if __name__ == '__main__':
    unittest.main()
