# MoonTown build and test feedback time

Measured on 2026-09-29–30 with Moon `0.1.20260920`, Apple silicon, 10 logical
CPUs and 24 GiB RAM. These are local observations, not portable guarantees.

## Recommended commands

For a code change, type-check and run the narrowest relevant test first:

```sh
moon check --target native --diagnostic-limit 0 -q
moon test src/town_runtime --target native --diagnostic-limit 0 -q
moon -C src/ui/rabbita-town test main/changed_feature_wbtest.mbt \
  --target js --release --frozen --diagnostic-limit 0 -q
```

Replace the package or test file with the one being changed. For the complete
Rabbita `main` JS suite, use the file-sharded runner:

```sh
moon run scripts/test-rabbita-sharded.mbtx 4
```

On a machine with at least eight free CPU cores, try `8` instead of `4`.
The runner builds once with `--jobs 8`, discovers all `*_test.mbt` and
`*_wbtest.mbt` files in `main`, and gives idle workers the next four-file
batch. A failing batch makes the whole run fail. An optional second argument
sets files per batch; four remains the measured default. The script is for the
Rabbita `main` package; it does not replace the root native suite or the
separate landmark-studio module tests.

## Why these choices

| Measurement | Time |
| --- | ---: |
| Warm root native `moon check`, `--jobs 8` | 4.61 s |
| Warm root native tests, `--jobs 8` | 1.21 s; 1,207 passed |
| Cold JS test build, `--jobs 1` | 37.01 s |
| Cold JS test build, default jobs | 19.12 s |
| Cold JS test build, `--jobs 8` | 15.59 s |
| Warm three-test file, `--release` | 0.51 s |
| Warm five-test rendering file, `--release` | 18.43–23.84 s |
| Warm five-test rendering file, default build | 19.79–20.28 s |
| Complete Rabbita `main` JS suite, four static shards | 351.62 s; all 140 test files passed |
| Complete Rabbita `main` JS suite, eight static shards | 311.76 s; all 140 test files passed |
| Complete Rabbita `main` JS suite, eight dynamic workers | 314.88 s; all 35 four-file batches passed |
| Same suite after road-reachability optimization, eight dynamic workers | 145.84 s; all 140 files / 35 batches passed |
| Custom-placement test file before / after optimization | 113.53 s / 17.28 s |

The cold-build rows used fresh `--target-dir` directories and one run per
configuration, so they include cache and machine-load noise. Default Moon
already parallelizes compilation; `--jobs 8` is a modest improvement over
default here, not an eightfold speedup. The hot-cache delay is test execution:
a single Node process occupies one core. `--release` is not a reliable large
runtime improvement for the measured rendering file. The same two expensive
files took about 35 seconds one after another and about 21 seconds when run
concurrently.

The dynamic queue did not beat eight fixed shards before the road fix; it
reports progress and identifies slow batches while keeping idle workers useful.
Earlier monolithic JS runs were stopped after more than eight minutes, so
there is no exact completed single-process baseline for a speedup ratio.
`energy_valley_custom_placement_wbtest.mbt` alone initially took about 114
seconds. Replacing repeated world lookups in its test helper did not help
(113–115 seconds), so that experimental edit was discarded. A Node CPU profile
instead showed `RoadNetwork::neighbors` and `is_reachable` dominating the
runtime: reachability rescanned every road segment for every BFS node.
Reusing the existing adjacency-based shortest-path traversal reduced that
file to 17.28 seconds and the complete sharded suite from 314.88 to 145.84
seconds on this machine. These are warm-cache measurements; the first run
after source changes also includes recompilation.

One-file batches were stopped after exceeding five minutes with work still
remaining; two-file batches were stopped at 345 seconds with work remaining.
Launching all known slow files first was also slower than the default due to
CPU contention. Neither experimental schedule became the default. Reuse the
normal `_build` cache between runs; changing `--target-dir` forces a cold build.

Do not use `-v` merely to get test progress: for this package it prints a very
large generated runner command and test-filter JSON. `-q` keeps ordinary
success output small; `--diagnostic-limit 0` avoids flooding the terminal with
existing deprecation warnings. Neither flag changes which tests execute.
