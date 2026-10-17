#!/usr/bin/env bash
# Pinned standard-library-only contract verification. This does not substitute
# dependencies or compile the host/Book/Rabbita integration.
set -euo pipefail
SOURCE=$(cd "$(dirname "$0")/.." && pwd)
OUTPUT=${1:-"$(dirname "$SOURCE")/idea-salon-verification"}
case "$OUTPUT" in /*) ;; *) echo 'Output root must be absolute' >&2; exit 2;; esac
mkdir -p "$OUTPUT"
OUTPUT=$(cd "$OUTPUT" && pwd)
case "$OUTPUT/" in "$SOURCE/"*) echo 'Output root must be outside the source tree' >&2; exit 2;; esac
export WORKER_ROOT="$OUTPUT"
source /workspace/scratch/665adc5202cf/.moonsuite-background/build-readiness-20261011T131950/environment.sh
HARNESS="$OUTPUT/contract-harness"
TARGET="$OUTPUT/contract-target"
export SOURCE HARNESS OUTPUT
python3 - <<'PY'
import os, shutil, hashlib, json
from pathlib import Path
s = Path(os.environ['SOURCE']) / 'src/collaboration_contract'
h = Path(os.environ['HARNESS'])
if shutil.disk_usage(h.parent).free < 4 * 1024**3:
    raise SystemExit('4 GiB reserve required')
(h / 'src/collaboration_contract').mkdir(parents=True, exist_ok=True)
(h / 'moon.mod').write_text('name = "vectie/moontown"\nversion = "0.1.9"\nsource = "src"\npreferred_target = "native"\n')
manifest = []
for p in sorted(s.iterdir()):
    if p.suffix == '.mbt' or p.name == 'moon.pkg':
        destination = h / 'src/collaboration_contract' / p.name
        shutil.copyfile(p, destination)
        manifest.append({'source_relative': str(p.relative_to(Path(os.environ['SOURCE']))), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()})
(Path(os.environ['OUTPUT']) / 'input-manifest.json').write_text(json.dumps({
    'purpose': 'Exact production core-only package compiled in isolation. No product dependency is replaced. Host, Book and Rabbita are not compiled by this check.',
    'module_manifest': (h / 'moon.mod').read_text(),
    'moon_sha256': hashlib.sha256((Path(os.environ['MOON_HOME']) / 'bin/moon').read_bytes()).hexdigest(),
    'moonc_sha256': hashlib.sha256((Path(os.environ['MOON_HOME']) / 'bin/moonc').read_bytes()).hexdigest(),
    'inputs': manifest
}, indent=2) + '\n')
PY
cd "$HARNESS"
printf '%s\n' "flock $MOON_NATIVE_LOCK moon test --frozen --target native --strip -j 1 --target-dir $TARGET src/collaboration_contract" > "$OUTPUT/commands.log"
flock "$MOON_NATIVE_LOCK" moon test --frozen --target native --strip -j 1 --target-dir "$TARGET" src/collaboration_contract 2>&1 | tee "$OUTPUT/test.log"
printf '%s\n' "moon info --frozen --target native --target-dir $TARGET src/collaboration_contract" >> "$OUTPUT/commands.log"
moon info --frozen --target native --target-dir "$TARGET" src/collaboration_contract 2>&1 | tee "$OUTPUT/info.log"
cmp "$HARNESS/src/collaboration_contract/pkg.generated.mbti" "$SOURCE/src/collaboration_contract/pkg.generated.mbti"
echo 'Generated interface matches the candidate; no source file was changed.'
