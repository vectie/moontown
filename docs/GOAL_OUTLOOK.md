# Explore and compare standing-goal schedules

Use `goal_outlook` to answer “Which goals cluster at the same scheduler tick?” and
“What would this edited schedule change?” It reads explicit saved StandingGoal
snapshots and exports a bounded cadence outlook, or compares a baseline with a
candidate by exact goal ID. This completes a local inspect–edit–compare loop with
`goal_table`, supporting PRD MOONTOWN-UC01/B01's due-work inspection. It neither
installs a candidate nor runs a goal.

## Inspect, edit, compare

Start from a stable copy of the existing `standing-goals.json`. The usual saved
registry is `.moonsuite/products/moontown/standing-goals.json` under the suite
root; these tools never discover it implicitly. Choose a start tick from the
state you want to inspect and a later exclusive end. Ticks are scheduler ticks,
not Unix timestamps, minutes or dates. There is no assumed wall-clock conversion.

```sh
goal_outlook preview saved-goals.json 240 600 json > outlook.json
goal_outlook preview saved-goals.json 240 600 csv > outlook.csv
goal_table export saved-goals.json csv > editable-goals.csv
# Edit the table, keeping JSON-quoted text cells and exact goal IDs.
goal_table import edited-goals.csv > candidate-goals.json
goal_outlook compare saved-goals.json candidate-goals.json 240 600 json > comparison.json
goal_outlook compare saved-goals.json candidate-goals.json 240 600 csv > comparison.csv
```

Redirect only to a NEW file. The shell truncates existing destinations before the
program runs, so never redirect onto an input or live registry. Success emits the
entire output; errors emit stderr, exit 1 and leave stdout empty. Redirection may
still create an empty file on failure. Neither command changes an input, creates
a Book, installs state, starts a daemon or contacts a worker/provider. Installing
any reviewed candidate remains a separate operator action. Do not overwrite live
schedule state with an old snapshot; due/run fields may have advanced since export.

## What the projection means

The window is `[start,end)`: start is included, end is excluded. For each goal:

- Disabled goals are `paused` and contribute no occurrences
- Enabled goals with a saved due tick before start are `overdue`; each occurs
  once at start. Historical missed ticks are not backfilled
- A due tick equal to start is `due_now`
- A later due tick inside the window is `scheduled`
- A due tick at or after end is `beyond_window`

After the first occurrence, the projection assumes immediate successful dispatch
and adds the configured cadence. It matches `StandingGoal.is_due` and
`mark_dispatched` for this scenario. Like the core method, cadences below one are
interpreted as one tick; output retains both the original and effective values.
Negative saved due ticks are permitted legacy values and become overdue at any
nonnegative start. Arithmetic is checked before addition, so a large cadence or
near-maximum tick never wraps. A tick at the signed 32-bit maximum cannot be
included, because the exclusive end itself must fit that range.

This is a schedule exploration scenario, not a prediction of actual runs. It does
not load active-task state, model capacity, perform material-change checks, or
simulate review debt, failed/deferred outcomes and retry/review timing. Real
watcher decisions and dispatch delays can change subsequent due ticks. A shared
tick shows clustering; it is not a capacity violation, duplicate dispatch,
notification count, execution cost or human attention estimate. No productivity
claim is inferred from fewer projected occurrences.

## Read the outputs

Preview JSON (`moontown.goal-outlook.v1`) contains:

- Every goal in source order, with all ten current typed fields, original
  1-based `source_position`, state, effective cadence and occurrence ticks/count
- Chronological `slots`, each with its tick and source goal positions. Positions
  refer to that same report's goals; all goals sharing a tick retain source order
- Total occurrences, occupied ticks, shared ticks (at least two goals), and peak
  goals at one tick. Empty and wholly paused schedules have zero totals
- Original input SHA-256, byte count, explicit window and projection policy

Preview CSV has one row per goal, including paused and beyond-window goals,
identity/title/target, state, saved and effective cadence, due tick, occurrence
count/ticks, window and digest. The JSON report additionally carries the full
settings, chronological slots and aggregate clustering figures.

Comparison JSON (`moontown.goal-outlook-comparison.v1`) matches exact, case- and
whitespace-sensitive IDs. It lists baseline goals first, then candidate-only IDs
in candidate order. Each row is `changed`, `unchanged`, `removed` or `added`.
A changed ID is a removal plus an addition, never an inferred rename.

- `settings_changed` compares all ten typed goal fields. Prompt, title, source
  policy or last-run edits remain visible even if they do not change this outlook
- `outlook_changed` means membership, state or projected ticks changed. A removed
  paused goal still changes membership despite contributing zero occurrences
- `occurrence_delta` is candidate count minus baseline count; negative means
  fewer projected occurrences. Missing sides count as zero only for this delta
- Present `before`/`after` sides retain complete goal details and their own source
  positions. An absent side is omitted in JSON. Reordering alone does not count
  as a settings edit, although both positions and source digests make it visible
- The report compares total occurrences, shared ticks and peak goals, and binds
  both original byte snapshots by digest/size

Comparison CSV is a per-ID summary with status, change flags, counts/delta,
projected ticks, window and both digests. Missing sides use literal `null`, distinct
from a present zero-count goal's `0` and `[]`. Use JSON for complete settings and
aggregate figures. CSV uses CRLF and quotes every cell. Columns ending `_json`
contain JSON, including surrounding quotes for strings; do not strip those quotes
when importing into a spreadsheet. Formula-looking IDs/titles are thereby text.
Numeric negative deltas are emitted as ordinary signed decimal numbers. An empty
CSV has only its header, so use JSON when source identity for an empty result matters.

## A complete synthetic example

`assets/samples/goal-outlook/` retains actual tool outputs and the inputs used by
the executable verifier. `before.json` extends the existing canonical goal-table
fixture with a second enabled goal; no files describe a real user's active town.

For ticks 240–599, the baseline has ten projected occurrences and two shared
ticks. The CSV edit changes only the customer's cadence from 60 to 120 and its
next due tick from 240 to 270. Reimporting through the real `goal_table` CLI produces
`candidate.json`; the outlook becomes seven occurrences and one shared tick.
Its other fields and all other goals remain equal. `comparison.json` and
`comparison.csv` show the exact effect, including the three-occurrence reduction.
No optimization, runtime feasibility or best schedule is claimed.

## Input contracts, provenance and bounds

The reusable APIs are `goal_outlook.report(bytes,start,end,format="json"|"csv")`
and `goal_outlook.compare(before,after,start,end,format="json"|"csv")`, returning
`Result[String,String]`. `goal_table.decode_snapshot` exposes the same validated
snapshot reader used by table export, avoiding a second interpretation of IDs,
optional fields and exact integers. Optional absent fields are omitted in the
canonical JSON; explicit null is not the core decoder's representation.

Each input is a regular, lossless UTF-8 file of at most 1 MiB and at most 2,000
goals. IDs must be nonblank and unique. Unknown fields, fractional/out-of-range
integers, malformed JSON and invalid required/optional types fail, not repair.
The start/end must be nonnegative signed 32-bit integers, with a positive window
of at most 1,000,000 ticks. Each snapshot may produce at most 10,000 occurrences.
Each successful output is at most 4 MiB. Limit failures never truncate or silently
skip goals. Comparison validates both complete inputs. Filenames need no special
extension; explicitly named symlinks to regular files are supported. Directories,
FIFOs and missing files fail.

The CLI reads only the named files and hashes their captured bytes. Formatting,
line endings and whitespace affect the digest even if typed values are equal.
The digests are unsigned local integrity identifiers, not proof of freshness,
authenticated Book ownership or accepted knowledge. Use stable snapshots: the two
files are read separately without a live-filesystem transaction, and hostile
concurrent path/file replacement is outside this local workflow's guarantee.
JSON copies full goal prompts and source policies; inspect before sharing.

## Focused verification

Build the pinned native Town graph with the unchanged real Chat R68 sibling.
Use an absolute external target, `--frozen --strip -j 1`, the shared native lock
and the required free-space check. The delivery BUILD.md and environment.sh give
the exact commands and dependency/source identities. The focused API tests cover
chronological clustering, core cadence equivalence, overdue and paused behavior,
integer boundaries, exact matching, additions/removals/settings-only edits,
reordering, formats, malformed inputs and occurrence bounds. Existing goal-table
tests also run because its decoder is now exposed.

`scripts/verify-goal-outlook.py OUTLOOK_EXE GOAL_TABLE_EXE NEW_OUTPUT_DIRECTORY`
exercises real executable output, the export/edit/import/compare loop, hashes,
unchanged inputs, invalid inputs, filesystem failures, and CLI limits. It retains
all fixtures and outputs and refuses an existing destination. No UI, broad-root
suite, live daemon, provider, Book acceptance, restart/soak, production deployment
or historical runtime is qualified. Cumulative qualification remains R50.

## Stagger selected goals without hand-editing every due tick

When several standing goals share a due tick, choose an explicit order and create
one revised snapshot. Save `selected-ids.json` as an ordered JSON string array,
for example `["market-watch", "customer-watch"]`. Then:

```sh
goal_outlook stagger saved-goals.json selected-ids.json 250 20 > staggered-candidate.json
goal_outlook compare saved-goals.json staggered-candidate.json 240 600 json > stagger-comparison.json
```

The first selected ID gets tick 250, the second tick 270, and so on. Only each
selected goal's `next_due_tick` changes. Candidate row order stays the original
snapshot order; the selection controls assignment order, never row order. The
full candidate retains all other fields and unselected goals, including paused
ones. Selected paused goals are rejected so this workflow cannot silently resume
or reschedule them. Match IDs exactly, including case, whitespace and Unicode.
An unknown or duplicate selected ID fails the entire operation.

This is an explicit due-tick edit: START is not compared to the old due tick, the
last-run tick, or any live clock. It can bring a goal forward or delay it. Ticks
are scheduler ticks, not wall time. Cadence and last-run history do not change.
Equal spacing only separates selected initial due ticks. Unselected goals or
later recurrence can still overlap, and differing cadences can erase that
spacing. Preview the whole candidate over your relevant window. There is no
optimization, capacity guarantee, execution budget, dispatch or installation.
Active runs are not inspected, so this is not safe automatic daemon reconciliation.

Use stable offline inputs and redirect only to NEW paths. Keep the original
snapshot as the edit baseline. If live state advanced while you were editing,
use the existing `goal_merge` workflow with that baseline, this candidate and a
fresh current snapshot. A changed due tick can conflict with new run history or
another schedule edit; never use the candidate to overwrite live state blindly.
Installation and any live authority checks remain separate operator actions.

START is a nonnegative signed 32-bit integer and SPACING a positive signed 32-bit
integer. Arithmetic is checked before addition. The final assigned tick may be
2147483647, although preview cannot include that tick because its exclusive end
must also fit in the same range. A single selection accepts any positive spacing
without performing an unnecessary final addition.

Both files must meet the existing regular-file/1 MiB/UTF-8 rules. The selection
must contain 1–2,000 distinct nonblank string IDs; the full saved snapshot is
validated, including all unselected goals. The canonical full candidate must
also fit in 1 MiB, including its trailing newline, so it can be read by the
existing table, merge and outlook tools. Any failure produces no candidate on
stdout. Canonical JSON can reformat the input; preservation is by typed values,
not byte identity. Existing source files remain unchanged.

The portable API is `goal_outlook.stagger(snapshot_bytes, selection_bytes,
start, spacing) -> Result[String,String]`. `assets/samples/goal-stagger/` includes
synthetic before/selection inputs and actual candidate/comparison outputs.
`scripts/verify-goal-stagger.py OUTLOOK_EXE NEW_ABSOLUTE_OUTPUT_DIRECTORY` checks
the real stagger/compare/preview loop, preservation, selection errors, integer
limits, filesystem errors and unchanged inputs. This supports MOONTOWN-UC01/B01's
operator schedule revision, with no new daemon or production qualification.
