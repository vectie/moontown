#!/usr/bin/env python3
"""Replay the actual offline CSV edit -> three-way merge workflow without mutation."""
import csv
import hashlib
import io
import json
from pathlib import Path
import subprocess
import sys

merge, table, destination = map(Path, sys.argv[1:])
root = destination.resolve()
root.mkdir(parents=True, exist_ok=False)
source = Path(__file__).resolve().parents[1]
inputs = {}
cases = []


def save(name, data):
    if not isinstance(data, bytes):
        data = (json.dumps(data, ensure_ascii=False, indent=2) + '\n').encode()
    path = root / name
    path.write_bytes(data)
    inputs[name] = hashlib.sha256(data).hexdigest()
    return path


def run(name, args, ok=True, program=merge):
    proc = subprocess.run([str(program), *map(str, args)], capture_output=True, timeout=10)
    (root / (name + '.stdout')).write_bytes(proc.stdout)
    (root / (name + '.stderr')).write_bytes(proc.stderr)
    assert proc.returncode == (0 if ok else 1), (name, proc.returncode, proc.stderr)
    if ok:
        assert proc.stdout, name
    else:
        assert not proc.stdout and proc.stderr, name
    cases.append({'case': name, 'exit_code': proc.returncode, 'passed': True})
    return proc.stdout


base = json.loads((source / 'assets/samples/goal-table/standing-goals.json').read_bytes())
base_path = save('base.json', base)
rows = list(csv.reader(io.StringIO(run('export-table', ['export', base_path, 'csv'], program=table).decode())))
header = rows[0]
rows[1][header.index('title_json')] = json.dumps('=客户 review, "launch"\n🌙', ensure_ascii=False)
rows[1][header.index('cadence_ticks')] = '120'
rows[1][header.index('enabled')] = 'false'
stream = io.StringIO(newline='')
csv.writer(stream).writerows(rows)
edited_table = save('edited.csv', stream.getvalue().encode())
edited_path = save('edited.json', run('import-table', ['import', edited_table], program=table))
edited = json.loads(edited_path.read_bytes())
latest_first = dict(base[0], next_due_tick=300, last_run_tick=240)
added = dict(base[0], id='watch-new-current', title='New current goal')
current = [added, base[2], latest_first, base[1]]
current_path = save('current.json', current)
expected_first = dict(edited[0], next_due_tick=300, last_run_tick=240)
expected = [added, base[2], expected_first, base[1]]
merged_bytes = run('merge-current', ['merge', base_path, edited_path, current_path])
assert json.loads(merged_bytes) == expected
merged_path = save('merged.json', merged_bytes)
inspection = json.loads(run('inspect-current', ['inspect', base_path, edited_path, current_path]))
assert inspection['status'] == 'merged' and inspection['conflict_count'] == 0
assert inspection['merged_goals'] == expected
reexport = run('export-merged', ['export', merged_path, 'tsv'], program=table)
reexport_path = save('merged.tsv', reexport)
assert json.loads(run('reimport-merged', ['import', reexport_path], program=table)) == expected
assert run('deterministic', ['merge', base_path, edited_path, current_path]) == merged_bytes
# A conflicting current title is kept visible; resolving means explicitly editing
# the candidate to the current title before rerunning against the same baseline.
conflicted = [dict(goal, title='Concurrent title') if goal['id'] == base[0]['id'] else goal for goal in current]
conflicted_path = save('conflicted-current.json', conflicted)
run('conflict-no-candidate', ['merge', base_path, edited_path, conflicted_path], ok=False)
conflict = json.loads(run('inspect-conflict', ['inspect', base_path, edited_path, conflicted_path]))
assert conflict['status'] == 'conflict' and conflict['merged_goals'] is None
assert conflict['conflicts'] == [{'goal_id': base[0]['id'], 'field': 'title', 'kind': 'different_edits',
                                 'base_value': base[0]['title'], 'edited_value': edited[0]['title'],
                                 'current_value': 'Concurrent title'}]
resolved = [dict(goal, title='Concurrent title') if goal['id'] == base[0]['id'] else goal for goal in edited]
resolved_path = save('resolved-edited.json', resolved)
expected_resolved = [dict(goal, title='Concurrent title') if goal['id'] == base[0]['id'] else goal for goal in expected]
assert json.loads(run('resolve-conflict', ['merge', base_path, resolved_path, conflicted_path])) == expected_resolved
# Removing a goal whose run state advanced is also a conflict, not a silent deletion.
removed_path = save('removed.json', base[1:])
removed_report = json.loads(run('inspect-delete-modify', ['inspect', base_path, removed_path, current_path]))
assert removed_report['conflicts'][0]['kind'] == 'deleted_modified'
assert removed_report['merged_goals'] is None
run('delete-modify-no-candidate', ['merge', base_path, removed_path, current_path], ok=False)
# Current-only deletion survives a candidate that did not edit the deleted goal.
current_deleted = save('current-deleted.json', base[1:])
assert json.loads(run('retain-current-deletion', ['merge', base_path, base_path, current_deleted])) == base[1:]
# Edited-only new IDs append; their source ordering never reorders current rows.
new_a = dict(base[0], id='new-a')
new_b = dict(base[0], id='new-b')
with_additions = save('additions.json', list(reversed(base)) + [new_a, new_b])
assert json.loads(run('append-edited-additions', ['merge', base_path, with_additions, current_path])) == current + [new_a, new_b]
# Optional fields must use their actual scalar/null values, not Option's
# generic singleton-array JSON representation.
optional_edited = [dict(base[0], last_run_tick=0), *base[1:]]
optional_edited[0].pop('target_book_id')
optional_current = [dict(base[0], target_book_id=''), *base[1:]]
optional_current[0].pop('last_run_tick')
optional_edit_path = save('optional-edited.json', optional_edited)
optional_current_path = save('optional-current.json', optional_current)
optional_report = json.loads(run('optional-conflict-values', ['inspect', base_path, optional_edit_path, optional_current_path]))
assert optional_report == {'schema': 'moontown.goal-merge.v1', 'status': 'conflict', 'conflict_count': 2,
                          'merged_goals': None, 'conflicts': [
    {'goal_id': base[0]['id'], 'field': 'target_book_id', 'kind': 'different_edits',
     'base_value': base[0]['target_book_id'], 'edited_value': None, 'current_value': ''},
    {'goal_id': base[0]['id'], 'field': 'last_run_tick', 'kind': 'different_edits',
     'base_value': base[0]['last_run_tick'], 'edited_value': 0, 'current_value': None}]}
run('optional-conflict-no-candidate', ['merge', base_path, optional_edit_path, optional_current_path], ok=False)
run('help', ['--help'])
run('unknown-operation', ['install', base_path, edited_path, current_path], ok=False)
run('missing-argument', ['merge', base_path, edited_path], ok=False)
for label, bad in [('invalid-json', b'['), ('invalid-utf8', b'\xff'), ('oversize', b' ' * 1048577),
                   ('duplicate', [base[0], base[0]]), ('unknown-field', [dict(base[0], unknown=True)]),
                   ('fractional', [dict(base[0], next_due_tick=1.5)])]:
    path = save(label + '.json', bad)
    run(label, ['merge', base_path, edited_path, path], ok=False)
run('missing-file', ['merge', base_path, edited_path, root / 'missing.json'], ok=False)
run('directory', ['merge', base_path, edited_path, root], ok=False)
for name, digest in inputs.items():
    assert hashlib.sha256((root / name).read_bytes()).hexdigest() == digest, name
samples = source / 'assets/samples/goal-merge'
for name in ['base.json','edited.csv','edited.json','current.json','merged.json','conflicted-current.json','resolved-edited.json']:
    assert (samples / name).read_bytes() == (root / name).read_bytes(), name
for sample, output in [('inspection.json', 'inspect-current.stdout'), ('conflict.json', 'inspect-conflict.stdout')]:
    assert (samples / sample).read_bytes() == (root / output).read_bytes(), sample
results = {'sample_bytes_verified': 9, 'passed': len(cases), 'cases': cases, 'inputs_unchanged': True, 'input_hashes': inputs,
           'merged_order': [goal['id'] for goal in expected], 'advanced_due_tick': 300, 'retained_last_run_tick': 240}
(root / 'RESULTS.json').write_text(json.dumps(results, indent=2) + '\n')
print(json.dumps({'passed': len(cases), 'inputs_unchanged': True, 'output': str(root)}, indent=2))
