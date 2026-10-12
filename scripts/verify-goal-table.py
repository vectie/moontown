#!/usr/bin/env python3
"""Exercise the real goal_table executable against retained synthetic storage files."""
import csv
import hashlib
import io
import json
from pathlib import Path
import subprocess
import sys

binary, fixture, out = map(Path, sys.argv[1:4])
source = Path(sys.argv[4]) if len(sys.argv) > 4 else None
out.mkdir(parents=True, exist_ok=True)
original_path = fixture / "standing-goals.json"
edited_path = fixture / "edited-goals.csv"
inputs = [original_path, edited_path]
before = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}
original = json.loads(original_path.read_bytes())
expected = json.loads((fixture / "expected-edited.json").read_bytes())
results = []

def invoke(name, *args, ok=True):
    run = subprocess.run([str(binary), *map(str, args)], capture_output=True)
    (out / (name + ".stdout")).write_bytes(run.stdout)
    (out / (name + ".stderr")).write_bytes(run.stderr)
    assert (run.returncode == 0) == ok, (name, run.returncode, run.stderr)
    if not ok:
        assert run.stdout == b"", (name, "partial stdout")
        assert run.stderr, (name, "missing diagnostic")
    results.append({"case": name, "exit": run.returncode, "stdout_sha256": hashlib.sha256(run.stdout).hexdigest()})
    return run.stdout

for kind, delimiter in [("csv", ","), ("tsv", "\t")]:
    exported = invoke("export-" + kind, "export", original_path, kind)
    table_path = out / ("goals." + kind)
    table_path.write_bytes(exported)
    rows = list(csv.reader(io.StringIO(exported.decode()), delimiter=delimiter))
    assert len(rows) == len(original) + 1
    assert rows[1][0] == json.dumps(original[0]["id"])
    assert rows[1][1].startswith('"=')
    assert rows[1][5:8] == ["240", "180", "true"]
    assert rows[2][3] == "null" and rows[2][6:8] == ["null", "false"]
    assert rows[3][3] == '""' and rows[3][6] == "0"
    imported = invoke("import-" + kind, "import", table_path)
    assert json.loads(imported) == original
    assert table_path.read_bytes() == exported
    if kind == "tsv":
        bom = out / "bom.tsv"
        bom.write_bytes(b"\xef\xbb\xbf" + exported)
        assert json.loads(invoke("import-bom-tsv", "import", bom)) == original

candidate = invoke("edited-import", "import", edited_path)
assert json.loads(candidate) == expected
assert expected[0]["id"] == original[0]["id"]
assert expected[0]["next_due_tick"] == original[0]["next_due_tick"] == 240
assert expected[0]["last_run_tick"] == original[0]["last_run_tick"] == 180
assert expected[0]["cadence_ticks"] == 120 and expected[0]["enabled"] is False
assert expected[1:] == original[1:]
(out / "candidate-standing-goals.json").write_bytes(candidate)

# Actual editor-like cell modification through an independent standard CSV reader.
rows = list(csv.reader(io.StringIO((out / "goals.csv").read_text())))
rows[1][2] = json.dumps("Changed question\nKeep source policy", ensure_ascii=False)
rows[2][7] = "true"
stream = io.StringIO(newline="")
csv.writer(stream, lineterminator="\r\n").writerows(rows)
second_edit = out / "second-edit.csv"
second_edit.write_bytes(stream.getvalue().encode())
second = json.loads(invoke("second-edit-import", "import", second_edit))
expected_second = json.loads(json.dumps(original))
expected_second[0]["prompt"] = "Changed question\nKeep source policy"
expected_second[1]["enabled"] = True
assert second == expected_second

bad_table = out / "bad.csv"
bad_table.write_bytes(b"id_json\n\"unterminated")
invalid_utf8 = out / "invalid-utf8.csv"
invalid_utf8.write_bytes(b"\xff")
large = out / "oversize.csv"
large.write_bytes(b" " * 1048577)
future = out / "future.json"
future_value = json.loads(json.dumps(original))
future_value[0]["future_field"] = "must not disappear"
future.write_text(json.dumps(future_value))
fractional = out / "fractional.json"
fractional_value = json.loads(json.dumps(original))
fractional_value[0]["cadence_ticks"] = 1.5
fractional.write_text(json.dumps(fractional_value))
for name, args in [
    ("missing-file", ["export", out / "missing.json", "csv"]),
    ("bad-table", ["import", bad_table]),
    ("invalid-utf8", ["import", invalid_utf8]),
    ("oversize", ["import", large]),
    ("unknown-field", ["export", future, "csv"]),
    ("fractional", ["export", fractional, "csv"]),
    ("directory", ["export", out, "csv"]),
    ("wrong-format", ["export", original_path, "json"]),
    ("wrong-command", ["apply", original_path]),
]:
    invoke(name, *args, ok=False)
assert b"Usage: goal_table" in invoke("help", "--help")

if source is not None:
    samples = source / "assets/samples/goal-table"
    sample_before = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in samples.iterdir() if p.is_file()}
    for kind in ("csv", "tsv"):
        exported = invoke("sample-export-" + kind, "export", samples / "standing-goals.json", kind)
        assert exported == (samples / ("goals." + kind)).read_bytes()
        assert json.loads(invoke("sample-import-" + kind, "import", samples / ("goals." + kind))) == original
    sample_candidate = invoke("sample-edited-import", "import", samples / "edited-goals.csv")
    assert sample_candidate == (samples / "candidate-standing-goals.json").read_bytes()
    assert json.loads(sample_candidate) == expected
    for path, digest in sample_before.items():
        assert hashlib.sha256(Path(path).read_bytes()).hexdigest() == digest
    before.update(sample_before)
for path, digest in before.items():
    assert hashlib.sha256(Path(path).read_bytes()).hexdigest() == digest
(out / "RESULTS.json").write_text(json.dumps({"cases": results, "unchanged_inputs": before}, indent=2) + "\n")
print(f"PASS: {len(results)} real CLI cases; exact typed round trips, edits, schedule/identity preservation, explicit failures, unchanged input hashes")
