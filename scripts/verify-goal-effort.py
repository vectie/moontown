#!/usr/bin/env python3
"""Exercise the built CLI, not a reimplementation. Preserve all evidence."""
import csv
import hashlib
import io
import json
import pathlib
import subprocess
import sys

binary, source, evidence = map(pathlib.Path, sys.argv[1:4])
evidence.mkdir(parents=True, exist_ok=True)
samples = source / 'assets/samples/goal-effort'
goals = samples / 'standing-goals.json'
diary = samples / 'effort.csv'
results = []

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

original = {str(p): sha(p) for p in samples.iterdir() if p.is_file()}

def invoke(name, args, success=True):
    p = subprocess.run([str(binary), *map(str, args)], capture_output=True, timeout=30)
    (evidence / (name + '.stdout')).write_bytes(p.stdout)
    (evidence / (name + '.stderr')).write_bytes(p.stderr)
    if success:
        assert p.returncode == 0, (name, p.returncode, p.stderr)
        assert not p.stderr, (name, p.stderr)
    else:
        assert p.returncode == 1 and not p.stdout and p.stderr, (name, p.returncode, p.stdout, p.stderr)
    results.append({'case': name, 'exit': p.returncode, 'passed': True, 'stdout_sha256': hashlib.sha256(p.stdout).hexdigest()})
    return p.stdout

out = invoke('report-json', [goals, diary, 'json'])
report = json.loads(out)
assert report['contract'] == 'moontown.goal-effort-report.v1'
for key, path in [('goal_source', goals), ('diary_source', diary)]:
    assert report[key] == {'digest': 'sha256:' + sha(path), 'size_bytes': path.stat().st_size}
by_id = {g['goal_id']: g for g in report['goals']}
a = by_id['watch-customer']
assert a['source_goal'] == 1 and a['target_book_id'] == 'research-customer'
assert [p['source_data_row'] for p in a['periods']] == [1, 3]
assert a['totals'] == {'period_count': 2, 'complete_town_periods': 2, 'paired_periods': 2, 'manual_minutes': 70, 'review_minutes': 20, 'supervision_minutes': 10, 'followup_minutes': 10, 'town_minutes': 40, 'manual_minus_town_minutes': 30}
assert a['periods'][0]['manual_period_start'] == '2026-09-01'
assert a['periods'][1]['note'] == 'Second comparison\nIncludes handoff time'
assert by_id['watch-market']['totals']['town_minutes'] == 15
assert by_id['watch-market']['totals']['manual_minus_town_minutes'] is None
assert by_id['watch-heavy']['totals']['manual_minus_town_minutes'] == -12
assert by_id['watch-paused']['enabled'] is False
assert by_id['watch-paused']['totals']['period_count'] == 0
assert by_id['watch-paused']['totals']['town_minutes'] is None
assert invoke('deterministic-json', [goals, diary, 'json']) == out

csv_bytes = invoke('report-csv', [goals, diary, 'csv'])
assert csv_bytes.endswith(b'\r\n')
rows = list(csv.DictReader(io.StringIO(csv_bytes.decode())))
assert len(rows) == 4
assert rows[0]['manual_minus_town_minutes'] == '30'
assert rows[1]['manual_minutes'] == '' and rows[1]['town_minutes'] == '15'
assert rows[2]['manual_minus_town_minutes'] == "'-12"
assert rows[3]['title'] == "'=Paused and unmeasured"
assert rows[3]['town_minutes'] == ''
assert json.loads(rows[0]['period_pairs_json'])[0]['manual_period_start'] == '2026-09-01'

out_tsv = json.loads(invoke('bom-tsv', [goals, samples / 'effort.tsv', 'json']))
assert out_tsv['goals'] == report['goals']
assert out_tsv['diary_source']['digest'] != report['diary_source']['digest']

with diary.open(newline='') as f:
    reader = csv.DictReader(f)
    fields = reader.fieldnames
    records = list(reader)

def make_diary(name, records, headers=fields):
    p = evidence / (name + '.csv')
    with p.open('w', newline='') as f:
        writer = csv.DictWriter(f, headers)
        writer.writeheader()
        writer.writerows(records)
    return p

def rejection(name, mutation):
    changed = [dict(r) for r in records]
    mutation(changed)
    path = make_diary(name, changed)
    before = sha(path)
    invoke(name, [goals, path, 'json'], False)
    assert sha(path) == before

empty = make_diary('header-only', [])
empty_report = json.loads(invoke('header-only', [goals, empty, 'json']))
assert all(g['totals']['period_count'] == 0 and g['totals']['town_minutes'] is None for g in empty_report['goals'])
rejection('unknown-goal', lambda rs: rs[0].update(goal_id='no-such-goal'))
rejection('blank-outcome', lambda rs: rs[0].update(outcome=' '))
rejection('town-overlap', lambda rs: rs[2].update(period_start='2026-10-01', period_end='2026-10-08'))
rejection('baseline-reused', lambda rs: rs[2].update(manual_period_start='2026-09-01', manual_period_end='2026-09-08'))
rejection('unequal-windows', lambda rs: rs[0].update(manual_period_end='2026-09-09'))
rejection('invalid-date', lambda rs: rs[0].update(period_start='2026-02-29'))
rejection('missing-baseline-dates', lambda rs: rs[0].update(manual_period_start='', manual_period_end=''))
rejection('decimal-minutes', lambda rs: rs[0].update(review_minutes='1.5'))
rejection('negative-minutes', lambda rs: rs[0].update(review_minutes='-1'))
rejection('oversized-minutes', lambda rs: rs[0].update(review_minutes='100001'))

missing = [dict(r) for r in records]
missing[0]['review_minutes'] = ''
missing_report = json.loads(invoke('missing-component', [goals, make_diary('missing-component', missing), 'json']))
totals = missing_report['goals'][0]['totals']
assert totals['town_minutes'] is None and totals['manual_minutes'] == 70 and totals['paired_periods'] == 1
zeros = [dict(r) for r in records]
zeros[0].update(manual_minutes='0', review_minutes='0', supervision_minutes='0', followup_minutes='0')
zero_report = json.loads(invoke('explicit-zero', [goals, make_diary('explicit-zero', zeros), 'json']))
assert zero_report['goals'][0]['periods'][0]['manual_minus_town_minutes'] == 0

for name, content in [('bad-utf8', b'\xff'), ('wrong-header', b'goal_id\nwatch-customer\n'), ('ragged', (','.join(fields) + '\nx,y\n').encode()), ('oversize', b' ' * 1048577)]:
    path = evidence / (name + '.csv')
    path.write_bytes(content)
    invoke(name, [goals, path, 'json'], False)

for name, values in [('duplicate-goal', json.loads(goals.read_text()) * 2), ('invalid-goals', {'goals': []})]:
    path = evidence / (name + '.json')
    path.write_text(json.dumps(values))
    invoke(name, [path, diary, 'json'], False)

invoke('missing-file', [evidence / 'does-not-exist.json', diary, 'json'], False)
invoke('directory-input', [samples, diary, 'json'], False)
invoke('unknown-format', [goals, diary, 'html'], False)
invoke('help', ['--help'])
assert {str(p): sha(p) for p in samples.iterdir() if p.is_file()} == original
(evidence / 'input-hashes.json').write_text(json.dumps(original, indent=2) + '\n')
(evidence / 'results.json').write_text(json.dumps(results, indent=2) + '\n')
print(f'{len(results)} actual CLI cases passed; all source inputs unchanged')
