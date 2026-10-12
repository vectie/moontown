#!/usr/bin/env python3
"""Exercise the actual native outlook and table tools; retain every input/output."""
import csv
import hashlib
import io
import json
import os
from pathlib import Path
import subprocess
import sys

outlook, table, destination = map(Path, sys.argv[1:])
root = destination.resolve()
root.mkdir(parents=True, exist_ok=False)
source = Path(__file__).resolve().parents[1]
results = []
inputs = {}


def keep_input(name, data):
    path = root / name
    path.write_bytes(data)
    inputs[name] = hashlib.sha256(data).hexdigest()
    return path


def run(label, args, ok=True, program=outlook):
    completed = subprocess.run([str(program), *map(str, args)], capture_output=True, timeout=10)
    (root / (label + '.stdout')).write_bytes(completed.stdout)
    (root / (label + '.stderr')).write_bytes(completed.stderr)
    assert completed.returncode == (0 if ok else 1), (label, completed.returncode, completed.stderr)
    if ok:
        assert completed.stdout, label
    else:
        assert not completed.stdout and completed.stderr, label
    results.append({'case': label, 'exit_code': completed.returncode, 'passed': True})
    return completed.stdout


def js(data):
    return json.loads(data)


baseline = js((source / 'assets/samples/goal-table/standing-goals.json').read_bytes())
market = dict(baseline[0], id='watch-market', title='=Market, "中文"\nsecond line', cadence_ticks=90,
              next_due_tick=240, source_policy='', prompt='Check independent market sources')
baseline.append(market)
before = keep_input('before.json', (json.dumps(baseline, ensure_ascii=False, indent=2) + '\n').encode())
preview = js(run('preview-json', ['preview', before, 240, 600, 'json']))
assert (preview['occurrence_count'], preview['shared_tick_count'], preview['peak_goals_at_tick']) == (10, 2, 2)
assert preview['goals'][1]['state'] == 'paused'
assert preview['source_digest'] == 'sha256:' + inputs['before.json']
assert preview['source_size_bytes'] == before.stat().st_size
assert preview['slots'][0] == {'tick': 240, 'goal_positions': [1, 4]}
assert preview['slots'] == sorted(preview['slots'], key=lambda item: item['tick'])
rows = list(csv.DictReader(io.StringIO(run('preview-csv', ['preview', before, 240, 600, 'csv']).decode())))
assert len(rows) == 4 and json.loads(rows[3]['title_json']) == market['title']
assert rows[3]['title_json'].startswith('"=')
assert rows[1]['occurrence_count'] == '0' and rows[1]['occurrence_ticks_json'] == '[]'
assert json.loads(rows[0]['occurrence_ticks_json']) == [240,300,360,420,480,540]

exported = run('table-export', ['export', before, 'csv'], program=table)
edited = list(csv.reader(io.StringIO(exported.decode())))
header = edited[0]
edited[1][header.index('cadence_ticks')] = '120'
edited[1][header.index('next_due_tick')] = '270'
stream = io.StringIO(newline='')
csv.writer(stream).writerows(edited)
edit = keep_input('edited-goals.csv', stream.getvalue().encode())
candidate_bytes = run('table-import', ['import', edit], program=table)
after = keep_input('candidate.json', candidate_bytes)
candidate = js(candidate_bytes)
assert candidate[0] == dict(baseline[0], cadence_ticks=120, next_due_tick=270)
assert candidate[1:] == baseline[1:]
comparison = js(run('compare-json', ['compare', before, after, 240, 600, 'json']))
assert (comparison['before_occurrences'], comparison['after_occurrences'], comparison['occurrence_delta']) == (10, 7, -3)
assert (comparison['before_shared_ticks'], comparison['after_shared_ticks']) == (2, 1)
assert comparison['after_digest'] == 'sha256:' + inputs['candidate.json']
assert comparison['changes'][0]['state'] == 'changed'
assert comparison['changes'][0]['after']['occurrence_ticks'] == [270,390,510]
assert all(change['state'] == 'unchanged' for change in comparison['changes'][1:])
rows = list(csv.DictReader(io.StringIO(run('compare-csv', ['compare', before, after, 240, 600, 'csv']).decode())))
assert rows[0]['occurrence_delta'] == '-3'
assert json.loads(rows[0]['before_ticks_json']) == [240,300,360,420,480,540]
assert json.loads(rows[0]['after_ticks_json']) == [270,390,510]
second_preview = js(run('candidate-preview', ['preview', after, 240, 600, 'json']))
assert second_preview['occurrence_count'] == comparison['after_occurrences']
assert second_preview['shared_tick_count'] == comparison['after_shared_ticks']
identical = js(run('compare-identical', ['compare', before, before, 240, 600, 'json']))
assert identical['occurrence_delta'] == 0 and all(c['state'] == 'unchanged' for c in identical['changes'])
empty = keep_input('empty.json', b'[]')
assert js(run('empty-preview', ['preview', empty, 0, 1000000, 'json']))['slots'] == []
removed = js(run('all-removed', ['compare', before, empty, 240, 600, 'json']))
assert all(c['state'] == 'removed' and 'after' not in c for c in removed['changes'])
added = js(run('all-added', ['compare', empty, before, 240, 600, 'json']))
assert all(c['state'] == 'added' and 'before' not in c for c in added['changes'])
reordered = keep_input('reordered.json', json.dumps(list(reversed(baseline))).encode())
reorder = js(run('reordered', ['compare', before, reordered, 240, 600, 'json']))
assert all(c['state'] == 'unchanged' for c in reorder['changes'])
assert reorder['before_digest'] != reorder['after_digest']
run('help', ['--help'])
run('bad-mode', ['dispatch', before, 240, 600, 'json'], ok=False)
run('missing-argument', ['preview', before, 240, 600], ok=False)
run('bad-format', ['preview', before, 240, 600, 'html'], ok=False)
for label, start, end in [('negative', '-1', '20'), ('fraction', '1.5', '20'), ('exponent', '1e2', '300'),
                          ('space', ' 1', '20'), ('overflow', '2147483648', '2147483649'),
                          ('backwards', '20', '10'), ('empty-window', '10', '10'), ('wide-window', '0', '1000001')]:
    run('window-' + label, ['preview', before, start, end, 'json'], ok=False)
for label, data in [('malformed', b'['), ('invalid-utf8', b'\xff'), ('too-large', b' ' * 1048577),
                    ('unknown-field', json.dumps([dict(baseline[0], future='unknown')]).encode()),
                    ('fractional-tick', json.dumps([dict(baseline[0], next_due_tick=1.5)]).encode()),
                    ('duplicate-id', json.dumps([baseline[0], baseline[0]]).encode()),
                    ('blank-id', json.dumps([dict(baseline[0], id='  ')]).encode()),
                    ('too-many-goals', json.dumps([dict(baseline[0], id=str(i), enabled=False) for i in range(2001)]).encode())]:
    invalid = keep_input(label + '.json', data)
    run(label, ['preview', invalid, 240, 600, 'json'], ok=False)
    run(label + '-compare', ['compare', before, invalid, 240, 600, 'json'], ok=False)
run('missing-file', ['preview', root / 'absent.json', 0, 10, 'json'], ok=False)
run('directory', ['preview', root, 0, 10, 'json'], ok=False)
fifo = root / 'fifo'
os.mkfifo(fifo)
run('fifo', ['preview', fifo, 0, 10, 'json'], ok=False)
link = root / 'explicit-symlink.json'
link.symlink_to(before.name)
assert js(run('explicit-symlink', ['preview', link, 240, 600, 'json'])) == preview
normalized = keep_input('normalized.json', json.dumps([dict(baseline[0], cadence_ticks=0, next_due_tick=-2147483648)]).encode())
edge = js(run('int-edge', ['preview', normalized, 2147483644, 2147483647, 'json']))
assert edge['goals'][0]['occurrence_ticks'] == [2147483644,2147483645,2147483646]
assert edge['goals'][0]['effective_cadence_ticks'] == 1
run('too-many-occurrences', ['preview', normalized, 0, 10001, 'json'], ok=False)
assert js(run('exact-occurrence-limit', ['preview', normalized, 0, 10000, 'json']))['occurrence_count'] == 10000
for name, digest in inputs.items():
    assert hashlib.sha256((root / name).read_bytes()).hexdigest() == digest, name
report = {'cases': results, 'passed': len(results), 'input_hashes': inputs, 'inputs_unchanged': True,
          'example': {'before_occurrences': 10, 'after_occurrences': 7, 'before_shared_ticks': 2, 'after_shared_ticks': 1}}
(root / 'RESULTS.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'passed': len(results), 'inputs_unchanged': True, 'output': str(root)}, indent=2))
