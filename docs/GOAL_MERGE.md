# Carry edited standing goals onto a fresh snapshot

Use `goal_merge` when an exported goal table was edited while a newer saved
snapshot acquired new goals, run history, or unrelated configuration changes.
It compares three explicit, complete snapshots and produces a new candidate that
combines non-conflicting edits. The existing two-way registry helper replaces
whole rows; this command instead compares each field against the original edit
baseline. It is a local editing workflow supporting MOONTOWN-UC01/B01's retention
of goal intent and schedule history.

## Export, edit, refresh, merge

Keep the exact snapshot you exported as `base.json`. Treat all three inputs as
stable local copies. The command does not discover or read a live registry unless
you explicitly name one; a concurrently changing registry is not a supported
transactional input.

```sh
goal_table export base.json csv > editable-goals.csv
# Edit the CSV with its original JSON-string cell quoting and all rows intact.
goal_table import editable-goals.csv > edited.json
# Obtain a separate, current saved snapshot using your existing operator process.
goal_merge inspect base.json edited.json current.json > merge-inspection.json
goal_merge merge base.json edited.json current.json > merged-candidate.json
# Optional: inspect the candidate's cadence using the same explicit tick window.
goal_outlook compare current.json merged-candidate.json 240 600 json > cadence-change.json
```

Redirect only to NEW paths. Shell redirection truncates existing files before a
command starts and can leave an empty file on failure. Never redirect onto an
input or live registry. No command above installs a candidate, acquires a daemon
lock, changes a Book, dispatches a goal or calls a provider. The candidate is
canonical StandingGoal JSON, directly usable by `goal_table` and `goal_outlook`.
Actual installation remains a separately authorized operator workflow; a current
snapshot can become stale again after it is captured.

`BASE`, `EDITED` and `CURRENT` are complete StandingGoal arrays, not partial update
lists. Omitting a BASE goal from EDITED requests deletion. Supply the real edit
baseline; the program cannot prove these files have a common history or identify
which snapshot is newer. Ticks are scheduler ticks, never wall-clock timestamps.

## What is combined

Goal IDs are compared exactly, including case and surrounding spaces. Every other
field is compared by its typed value: title, prompt, target Book, cadence, next
due tick, last-run tick, enabled, source policy and quality threshold.

- If EDITED did not change a field from BASE, use CURRENT's value
- If only EDITED changed it, use EDITED's value
- If both changed it to the same value, use that shared value
- If both changed it differently, record a conflict

This means a title/cadence edit preserves CURRENT's newly advanced due/run ticks
when the editor left those fields alone. Due/run fields are not protected or
inferred: an explicit edit to one is merged by the same rule and can conflict.
Changing cadence never recalculates the next due tick. Paused state is retained
unless explicitly changed. No values are normalized or semantically repaired.
Missing optional values, empty strings, a literal `"null"` Book ID, and zero ticks
remain distinct. Legacy negative signed integers remain unchanged.

Rows present only in CURRENT are kept. Rows newly added only in EDITED are
appended. If both snapshots add the same new ID, their complete typed records
must match or the addition conflicts. Deleting a BASE row succeeds if the other
side retained it unchanged or also deleted it. Deletion versus any modification,
including a newly advanced run tick, is a conflict. A CURRENT deletion is retained
when EDITED left that row unchanged; deleted goals are never silently resurrected.

CURRENT's row order is retained for surviving rows. EDITED-only new IDs follow in
EDITED order. Reordering existing EDITED rows has no effect. Changing an ID is a
deletion plus an addition, never an inferred rename. To deliberately reorder the
finished candidate, use the existing table workflow afterward.

## Inspect and resolve conflicts

`inspect` emits JSON with schema `moontown.goal-merge.v1`, status `merged` or
`conflict`, `conflict_count`, `conflicts`, and `merged_goals`. A successful merge
inspection contains the complete candidate. Any conflict makes `merged_goals`
null; no partial candidate is exposed. Each conflict names the exact goal ID,
field, kind and BASE/EDITED/CURRENT values. Present optional Book IDs are JSON strings and last-run ticks are JSON numbers,
including empty strings and zero; optional absence is JSON null. For a
whole-goal conflict, the field is `$goal` and a missing record is null.

Kinds are `different_edits`, `deleted_modified` (EDITED deleted, CURRENT modified),
`modified_deleted` (EDITED modified, CURRENT deleted), and `added_differently`.
Field conflicts follow CURRENT row order and the field order listed above;
modified/deleted conflicts follow afterward in EDITED row order. This is an
exact-value comparison, not a semantic merge of prompts or source policies.

To keep CURRENT's field, set that EDITED field equal to CURRENT's value or restore
its BASE value. To keep a CURRENT deletion, omit the row from EDITED or restore it
to its unmodified BASE record. Then inspect again with the same stable inputs.
If you intentionally want to supersede a conflicting CURRENT value, start a new
edit from CURRENT as the new baseline and apply that deliberate change. Do not
forge the old BASE or assume a conflict report authorizes changing live state.
The tool has no force/ours/theirs mode and never chooses a conflict winner.

`merge` emits only the complete canonical JSON array and exits 0 on success.
A conflict, malformed input or exceeded bound exits 1, writes a diagnostic to
stderr and leaves stdout empty. `inspect` exits 0 even when its report contains
conflicts: check `status` and `merged_goals`. Invalid inputs and exceeded bounds
still exit 1 with empty stdout. Both operations validate all inputs before output.
Reports can contain private prompts and source policies; inspect before sharing.

## Included example and bounds

`assets/samples/goal-merge/` contains synthetic inputs and real command output.
The edited CSV changes the customer watch title, cadence to 120 and enabled to
false. CURRENT has due tick 300, last-run tick 240, a new goal and a different
row order. The merged result retains all of those newer values plus the edits.
`conflicted-current.json` instead changes the same title; `conflict.json` names
that field, and `resolved-edited.json` demonstrates explicitly keeping that title.

Each input must be a regular, valid UTF-8 file at most 1 MiB, with at most 2,000
exact distinct nonblank IDs. The shared `goal_table` decoder rejects unknown
fields, malformed JSON, wrong types and fractional/out-of-range signed 32-bit
integers. All fields are validated even on rows later omitted. The combined
candidate is limited to 2,000 goals and 1 MiB; inspection is limited to 2 MiB.
Any exceeded bound fails without truncation. There is no automatic file discovery,
source fetching, Book-existence check, synchronization or readiness claim.

The portable APIs are `goal_merge.merge_snapshots(base, edited, current)` and
`goal_merge.inspect_snapshots(base, edited, current)`, taking bytes and returning
`Result[String,String]`. The native `src/cmd/goal_merge` executable provides file
IO. See delivery BUILD.md for the pinned Town/Chat R68 graph and external target.
Focused tests cover merge decisions, exact optional/text/integer values, additions,
deletions, conflicts, bounds, actual CSV editing and unchanged files. These checks
do not qualify live daemon reconciliation, production service, UI or deployment.
