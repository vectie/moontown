#!/usr/bin/env python3
"""Verify the real native table_zones CLI; outputs/evidence go outside source."""
import csv
import hashlib
import io
import json
from pathlib import Path
import subprocess
import sys

binary, source, evidence = map(Path, sys.argv[1:])
evidence.mkdir(parents=True, exist_ok=True)
fixtures = source / 'assets/samples/table-zones'
inputs = list(fixtures.iterdir())
digests = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}
results = []

def run(label, args, ok=True):
    p = subprocess.run([str(binary), *map(str, args)], capture_output=True)
    (evidence / f'{label}.stdout').write_bytes(p.stdout)
    (evidence / f'{label}.stderr').write_bytes(p.stderr)
    assert (p.returncode == 0) == ok, (label, p.returncode, p.stderr.decode())
    if not ok:
        assert not p.stdout and p.stderr, label
    results.append({'case': label, 'exit': p.returncode, 'passed': True})
    return p.stdout

zones = fixtures / 'districts.geojson'
for ext in ['csv', 'tsv']:
    table = fixtures / f'venues.{ext}'
    args = [table, zones, '2', '3', '1', '4']
    geo_bytes = run(f'{ext}-geojson', args + ['geojson'])
    g = json.loads(geo_bytes)
    meta = g['moontown_zone_join']
    assert meta['summary'] == {'places': 8, 'zones': 2, 'ignored_non_polygon_features': 1, 'matched_places': 4, 'unmatched_places': 4, 'overlapping_places': 2, 'memberships': 6}
    assert meta['table_source'] == {'digest': 'sha256:' + digests[table.name], 'size_bytes': table.stat().st_size}
    assert meta['zone_source'] == {'digest': 'sha256:' + digests[zones.name], 'size_bytes': zones.stat().st_size}
    assert meta['columns_1based'] == {'latitude':2, 'longitude':3, 'name':1, 'category':4}
    fs = g['features']
    assert [len(f['properties']['zone_memberships']) for f in fs] == [1,1,0,2,0,0,2,0]
    assert [z['source_feature'] for z in fs[3]['properties']['zone_memberships']] == [2,3]
    assert fs[0]['properties']['source_table']['cells'][4] == '001'
    assert fs[3]['properties']['source_table']['cells'][5] == 'line one\nline two'
    assert fs[7]['properties']['name'] == '=South Gate'
    assert fs[7]['geometry']['coordinates'] == [-2,-1]
    data = run(f'{ext}-csv', args + ['csv'])
    rows = list(csv.reader(io.StringIO(data.decode(), newline='')))
    assert len(rows) == 11
    assert [r[2] for r in rows[1:]] == ['1','2','3','4','4','5','6','7','7','8']
    assert rows[1][6] == "'=North" and rows[5][7] == "'@district"
    assert rows[-1][8:12] == ["'=South Gate", "'-1", "'-2", "'@venue"]
    assert rows[0][12:] == ['note', 'note']
    assert rows[1][12] == '001'
    assert geo_bytes == run(f'{ext}-repeat', args + ['geojson'])

args = [fixtures/'venues.csv', zones, '2', '3', '1', '4', 'geojson']
run('missing-file', [evidence/'missing.csv', *args[1:]], False)
run('invalid-mode', args[:-1] + ['json'], False)
run('reused-column', args[:2] + ['2','2','1','4','csv'], False)
run('invalid-column', args[:2] + ['0','3','1','4','csv'], False)
run('invalid-extension', [zones, *args[1:]], False)
for label, data in [('bad-utf8', b'\xff'), ('bad-table', b'name,lat,lon,kind\nA,NaN,0,B\n'), ('partial-row', b'name,lat,lon,kind\nA,0,0,B\nshort,0\n')]:
    p = evidence/f'{label}.csv'; p.write_bytes(data)
    run(label, [p, *args[1:]], False)
for label, data in [('empty-zones', b'{"type":"FeatureCollection","features":[]}'), ('bad-zones', b'{}'), ('bad-zone-utf8', b'\xff'), ('unsupported-zone', b'{"type":"FeatureCollection","features":[{"type":"Feature","properties":null,"geometry":{"type":"MultiPolygon","coordinates":[]}}]}')]:
    p = evidence/f'{label}.geojson'; p.write_bytes(data)
    run(label, [args[0], p, *args[2:]], False)
empty = evidence/'empty.csv'; empty.write_bytes(b'name,lat,lon,kind\n')
g = json.loads(run('header-only', [empty,*args[1:]]))
assert g['features'] == [] and g['moontown_zone_join']['summary']['places'] == 0
run('help', ['--help'])
assert digests == {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}
(evidence/'input-hashes.json').write_text(json.dumps(digests, indent=2)+'\n')
(evidence/'results.json').write_text(json.dumps(results, indent=2)+'\n')
print(f'{len(results)} native CLI cases passed; source inputs remain byte-identical.')
