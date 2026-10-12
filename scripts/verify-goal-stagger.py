#!/usr/bin/env python3
"""Exercise the actual goal_outlook CLI; preserve every input/output in a NEW directory."""
import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

exe = Path(sys.argv[1]).resolve()
out = Path(sys.argv[2])
assert out.is_absolute() and not out.exists(), 'Output must be a new absolute directory'
out.mkdir(parents=True)
samples = Path(__file__).resolve().parents[1] / 'assets/samples/goal-stagger'
inputs = {}
checks = []

def save(name, data):
    p = out / name
    p.write_bytes(data if isinstance(data, bytes) else (json.dumps(data, ensure_ascii=False) + '\n').encode())
    inputs[name] = hashlib.sha256(p.read_bytes()).hexdigest()
    return p

def call(name, args, ok=True):
    result = subprocess.run([str(exe), *map(str, args)], capture_output=True, timeout=20)
    (out / (name + '.stdout')).write_bytes(result.stdout)
    (out / (name + '.stderr')).write_bytes(result.stderr)
    assert result.returncode == (0 if ok else 1), (name, result.returncode, result.stderr)
    if not ok:
        assert result.stdout == b'', (name, 'partial output')
        assert result.stderr, (name, 'missing diagnostic')
    checks.append({'name': name, 'exit': result.returncode, 'stdout_bytes': len(result.stdout)})
    return result.stdout

before_bytes = (samples / 'before.json').read_bytes()
ids_bytes = (samples / 'selection.json').read_bytes()
before = save('before.json', before_bytes)
ids = save('selection.json', ids_bytes)
goals = json.loads(before_bytes)
candidate_bytes = call('stagger', ['stagger', before, ids, 250, 20])
candidate = save('candidate.json', candidate_bytes)
actual = json.loads(candidate_bytes)
expected = copy.deepcopy(goals)
expected[0]['next_due_tick'] = 270
expected[1]['next_due_tick'] = 250
assert actual == expected, 'Only selected next_due_tick fields may change; retain row order'
comparison_bytes = call('compare', ['compare', before, candidate, 240, 360, 'json'])
comparison = json.loads(comparison_bytes)
assert comparison['before_shared_ticks'] == 2 and comparison['after_shared_ticks'] == 0
assert comparison['before_occurrences'] == comparison['after_occurrences'] == 6
assert comparison['before_digest'] == 'sha256:' + hashlib.sha256(before_bytes).hexdigest()
assert comparison['after_digest'] == 'sha256:' + hashlib.sha256(candidate_bytes).hexdigest()
preview = json.loads(call('preview', ['preview', candidate, 240, 360, 'json']))
assert preview['shared_tick_count'] == 0
assert call('idempotent', ['stagger', candidate, ids, 250, 20]) == candidate_bytes
assert b'stagger' in call('help', ['--help'])
for filename, data in [('candidate.json', candidate_bytes), ('comparison.json', comparison_bytes)]:
    assert (samples / filename).read_bytes() == data, ('Shipped sample differs', filename)
checks.append({'name': 'shipped_samples_exact', 'files': 4})

for name, selection in [('empty', []), ('duplicate', ['market-watch', 'market-watch']), ('missing', ['market-watch', 'absent']), ('paused', ['market-watch', 'paused-watch']), ('blank', [' ']), ('nonstring', ['market-watch', 12]), ('null', None), ('object', {}), ('case', ['Market-watch']), ('trim', [' market-watch'])]:
    p = save(name + '-ids.json', selection)
    call(name, ['stagger', before, p, 0, 1], ok=False)
for name, data in [('invalid-utf8', b'\xff'), ('malformed', b'['), ('oversize', b' ' * 1048577), ('too-many', ['market-watch'] * 2001)]:
    p = save(name + '-ids.json', data)
    call(name, ['stagger', before, p, 0, 1], ok=False)
for name, start, spacing in [('negative-start', '-1', '1'), ('zero-spacing', '0', '0'), ('negative-spacing', '0', '-1'), ('fraction', '0.5', '1'), ('plus', '+1', '1'), ('huge-start', '2147483648', '1'), ('huge-spacing', '0', '2147483648'), ('overflow', '2147483647', '1')]:
    call(name, ['stagger', before, ids, start, spacing], ok=False)
edge = json.loads(call('maximum-final-tick', ['stagger', before, ids, 2147483640, 7]))
assert edge[1]['next_due_tick'] == 2147483640 and edge[0]['next_due_tick'] == 2147483647
one = save('single-id.json', ['market-watch'])
edge = json.loads(call('single-at-maximum', ['stagger', before, one, 2147483647, 2147483647]))
assert edge[1]['next_due_tick'] == 2147483647
bad = copy.deepcopy(goals)
bad[-1]['unrecognized'] = True
call('unselected-unknown-field', ['stagger', save('unknown-field.json', bad), ids, 0, 1], ok=False)
bad = copy.deepcopy(goals)
bad[-1]['cadence_ticks'] = 1.5
call('unselected-fraction', ['stagger', save('fractional-snapshot.json', bad), ids, 0, 1], ok=False)
call('duplicate-snapshot-id', ['stagger', save('duplicate-snapshot.json', goals + [goals[0]]), ids, 0, 1], ok=False)
call('missing-file', ['stagger', before, out / 'absent.json', 0, 1], ok=False)
call('directory', ['stagger', before, out, 0, 1], ok=False)
fifo = out / 'ids.fifo'
os.mkfifo(fifo)
call('fifo', ['stagger', before, fifo, 0, 1], ok=False)
symlink = out / 'ids-link.json'
symlink.symlink_to(ids.name)
assert call('explicit-symlink', ['stagger', before, symlink, 250, 20]) == candidate_bytes
call('usage', ['stagger', before, ids, 0], ok=False)

exact_goals = copy.deepcopy(goals[:3])
for i, goal in enumerate(exact_goals):
    goal['id'] = ['A', ' A ', '客户 🌙'][i]
    goal['cadence_ticks'] = -2147483648
    goal['last_run_tick'] = [0, -2147483648, 2147483647][i]
    goal['target_book_id'] = ['', 'null', '图书'][i]
    goal['prompt'] = '=formula\tquoted "text"\nline'
exact = save('exact-goals.json', exact_goals)
exact_ids = save('exact-ids.json', ['客户 🌙', ' A '])
exact_expected = copy.deepcopy(exact_goals)
exact_expected[2]['next_due_tick'] = 0
exact_expected[1]['next_due_tick'] = 5
assert json.loads(call('exact-fields', ['stagger', exact, exact_ids, 0, 5])) == exact_expected

assert {name: hashlib.sha256((out / name).read_bytes()).hexdigest() for name in inputs} == inputs
receipt = {'schema': 'moontown.goal-stagger-smoke.v1', 'status': 'passed', 'checks': checks, 'check_count': len(checks), 'input_sha256': inputs, 'inputs_unchanged': True, 'executable_sha256': hashlib.sha256(exe.read_bytes()).hexdigest(), 'scope': 'Offline candidate staggering, preview and comparison only; no live state or dispatch'}
(out / 'RESULTS.json').write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps({'status': 'passed', 'check_count': len(checks), 'inputs_unchanged': True, 'results': str(out / 'RESULTS.json')}))
