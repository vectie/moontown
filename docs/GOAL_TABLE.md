# Edit standing goals as a table

Use `goal_table` to export an explicit saved StandingGoal snapshot, edit it in a
CSV/TSV editor, and produce a new canonical JSON snapshot. It preserves all ten
current fields, including goal identity, source policy, disabled state, next due
tick and last run tick. It does not silently reset schedule history during an edit.
This is a local operator configuration workflow supporting authored PRD
MOONTOWN-UC01/B01, not a daemon recovery or production-service qualification.

## Export, edit, reimport

Build `src/cmd/goal_table` with the repository's pinned native Town/Chat graph.
Work from a stable saved `standing-goals.json` or an explicit copy. The ordinary
runtime registry is `.moonsuite/products/moontown/standing-goals.json` under the
configured suite root, but the command never discovers or opens it implicitly.

```sh
goal_table export /absolute/saved-standing-goals.json csv > goals.csv
goal_table export /absolute/saved-standing-goals.json tsv > goals.tsv
# Edit goals.csv or goals.tsv, keeping the header and text-cell quoting.
goal_table import goals.csv > candidate-standing-goals.json
```

Only the named input file is read. Results go to stdout after complete validation;
errors go to stderr, exit 1, and leave stdout empty. Redirection may create an
empty destination on failure. Always redirect to a new file: the shell truncates
an existing destination before this command starts. Never redirect onto the
input or a live registry. No file is replaced by the command, no Book is created,
no source is fetched, and no goal, worker, provider or daemon is started.

The candidate JSON is directly readable by the existing
`storage.load_standing_goals_file` API. Review it before using it in an operator's
separately authorized configuration process. The tool does not install a
candidate or reconcile live daemon state. Do not overwrite a running registry
with an old export, because the daemon may have advanced its schedule/run fields.

## Table format

Keep these exact headers in this order:

```text
id_json,title_json,prompt_json,target_book_id_json,cadence_ticks,next_due_tick,last_run_tick,enabled,source_policy_json,quality_threshold
```

Every field is quoted in the exported CSV/TSV; the CSV layer doubles embedded
quotes. A spreadsheet/editor should parse that layer normally. In the displayed
cell values, the five `_json` columns contain JSON values:

- `id_json`: a JSON string such as `"watch-customer"`. IDs stay exact, including
  case and surrounding spaces; they must be distinct and not whitespace-only.
- `title_json`, `prompt_json`, `source_policy_json`: JSON strings. For example,
  edit the cell `"Review customer evidence"`, retaining both double quotes.
  Write an embedded quote as `\"`, a newline as `\n`, a tab as `\t`, and a
  literal backslash as `\\`. Unicode, empty strings and control characters
  retain their values. No field is trimmed or interpreted as a command.
- `target_book_id_json`: a JSON string or literal `null`. `null` means no target;
  `""` is an explicit empty string and `"null"` is the literal Book ID `null`.
  They remain distinct. Book existence/readiness is not checked.
- `cadence_ticks`, `next_due_tick`, `quality_threshold`: signed 32-bit decimal
  integers, without spaces, plus signs, fractions or exponent notation.
- `last_run_tick`: the same integer format, or literal `null` for no run. Zero
  is a recorded zero tick, not an absent run.
- `enabled`: exactly `true` or `false`; it is never inferred from other cells.

JSON string cells intentionally retain their surrounding quotes inside a
spreadsheet. This prevents formula-looking text such as `=SUM(...)` from becoming
a formula and avoids ambiguous apostrophe stripping on reimport. For example,
the displayed title cell is `"=Customer launch"`, not `=Customer launch`.
Import every column as text and preserve those quotes. A spreadsheet that removes
quotes, rewrites numbers or normalizes text can change your file; this tool
validates the file it receives, not an editor's behavior. Generic exported tables
without this header/cell format are not accepted.

## Editing semantics

Import produces the entire table as a snapshot, in row order. It is not an
upsert or merge with a hidden registry. Editing a title, prompt or cadence changes
only that field; it does not reset due/run ticks, enable a paused goal, or rewrite
its ID. Add a fully specified row for a new goal; remove a row to omit it from the
candidate; reorder rows to reorder the candidate. Header-only input produces `[]`.
Changing an ID creates a different identity in the output. Preserve IDs when you
intend to edit the same goal, especially goals referenced by plans and journals.

All current typed values are preserved, including legacy negative integer values.
No scheduler normalization or semantic repair is applied. For ordinary new goals,
choose a positive cadence, appropriate nonnegative ticks and a meaningful quality
threshold; check the owning scheduler's configuration before installing anything.
Ticks are scheduler ticks, not dates or minutes. A source policy is copied as text;
this conversion does not verify its plan, runtime permissions or named Book.

JSON output uses the existing StandingGoal serializer. Whitespace and object-key
formatting may normalize, while typed goal values and array order remain equal.
The canonical storage format omits absent optional fields and rejects explicit
JSON null for them. Table `null` therefore becomes an omitted JSON field, while
`""` stays an explicit empty string and zero stays a number. Unknown fields fail rather than
being discarded. Fractional/out-of-range JSON numbers fail rather than being
rounded by the core integer decoder. Required field/type errors fail as a whole.

## Included example

The synthetic `assets/samples/goal-table/standing-goals.json` is emitted by the
existing storage writer in the native integration test. It includes:

- `watch-customer`: next due 240, last run 180, cadence 60, local-material policy
- `watch-paused`: disabled, next due 360, no recorded run
- `watch-unassigned`: disabled, explicit empty Book ID, recorded last-run tick 0

`goals.csv` and `goals.tsv` are generated by the actual command from that snapshot.
`edited-goals.csv` changes only the first goal's title, cadence to 120 and enabled
to false. `candidate-standing-goals.json` is the actual reimported result. Its
original ID, next due 240, last run 180, prompt, source policy and threshold remain
unchanged; both other goals are unchanged.

```sh
goal_table export assets/samples/goal-table/standing-goals.json csv
goal_table import assets/samples/goal-table/edited-goals.csv
```

These are synthetic local fixtures, not a user's current goals. No source or
provider readiness is implied.

## Bounds and verification

Each input and successful output is at most 1 MiB; at most 2,000 goals are accepted.
If escaping would make an output exceed the limit, conversion fails without
truncation, so every successful export fits the import size bound. The shared
CSV/TSV parser accepts UTF-8 BOM, CR/LF/CRLF records and quoted fields; it requires
rectangular rows. Invalid UTF-8, malformed quoting, duplicate/blank IDs, unknown
snapshot fields, type errors and unsupported delimiters fail explicitly.

Reusable portable APIs are `goal_table.snapshot_to_table(bytes, delimiter)` and
`goal_table.table_to_snapshot(bytes, delimiter)`, returning `Result[String,String]`.
Focused tests cover field-preserving CSV/TSV round trips, edits, row selection and
order, optional values, Unicode/formula-looking text, signed integer bounds and
failure cases. The native integration test uses the actual storage writer and
reader. `scripts/verify-goal-table.py` checks the real command's stdout, exit codes,
reimported values and unchanged inputs. No graphical spreadsheet, full-root suite,
live daemon, Book execution, restart or production service is qualified here.

## Explore a candidate before installation

Use [`goal_outlook`](GOAL_OUTLOOK.md) to compare the original and imported JSON
snapshots over the same explicit scheduler-tick window. It shows exact per-goal
occurrences and clustering changes while retaining paused goals. This is a local
cadence scenario, not a forecast of actual dispatch or approval to install state.

## Retain newer state after an offline edit

If another saved snapshot has advanced since export, use
[`goal_merge`](GOAL_MERGE.md) with the exact export baseline, the imported edited
snapshot and the fresh snapshot. It combines non-conflicting fields, preserves
newer untouched due/run ticks and current-only goals, and exposes conflicts
without a partial candidate. All three inputs must be complete stable snapshots.
It does not install the result or lock live state.
