# Compare human effort for saved standing goals

Use this local workflow to answer: “How much human review, supervision and
follow-up did this goal require compared with doing the same work manually?”
Supply an explicit measured diary and the actual saved StandingGoal JSON file.
The report resolves every diary row to that goal's ID, title, target Book and
enabled state. It never substitutes worker runtime or activity counts for human
effort. This is a bounded part of the authored PRD MOONTOWN-R03/F03 and N05.

## Prepare the two inputs

1. Use a saved `standing-goals.json` from your Town state, or a retained exact
   copy. The standard state filename is
   `.moonsuite/products/moontown/standing-goals.json` under the configured suite
   root. Pass its explicit path; the command does not search for or create it.
   The canonical `core.StandingGoal` decoder is shared with the existing storage
   reader. Copy IDs exactly, including case and whitespace. Duplicate/blank goal
   IDs and diary rows naming absent goals fail rather than creating a new goal.
2. In a CSV or TSV diary, use these exact eleven headers in this order:

   ```text
   goal_id,period_start,period_end,outcome,manual_period_start,manual_period_end,manual_minutes,review_minutes,supervision_minutes,followup_minutes,note
   ```

3. One row is one comparison for one goal. `period_start`/`period_end` name the
   Town-supported observation window. `manual_period_start`/`manual_period_end`
   name the actual manual-baseline window, which may be an earlier week. Dates
   are valid Gregorian `YYYY-MM-DD` from years 0001 through 9999, inclusive start
   and exclusive end. A seven-day window is `2026-10-01` to `2026-10-08`.
   Each pair must have the same positive day count. Town windows for one goal
   must not overlap; manual windows for that goal must not overlap either. A
   manual window may overlap a Town window, for example for parallel comparison.
   Touching endpoints are allowed. Different goals can use the same windows.
4. Name the common outcome in `outcome`, for example “Review five launch
   sources.” Measure both sides with the same work scope, people, and method.
   Equal window lengths alone do not establish comparable workload or quality.
   Record timing method, workload changes and caveats in `note`. Those are
   human-supplied statements; this tool cannot verify measurements or equivalence.
5. `manual_minutes` is the total human time for the manual method, including its
   follow-up. For the Town method, record nonoverlapping categories:
   `review_minutes` for reading/evaluating outputs, `supervision_minutes` for
   setup/coordination/repair, and `followup_minutes` for remaining human action.
   Count each minute once and apply the same person-minute basis to both methods.
   Report all effort needed for the outcome, including setup attributable to it;
   otherwise the comparison will understate cost.

All four measurements are whole minutes `0` through `100000`. A blank cell means
unknown; zero means explicitly measured zero. Signs, decimals, surrounding spaces,
scientific notation and negative inputs fail. Leading zero digits are accepted.
Measured manual minutes, including zero, require both manual dates. If the
baseline was not measured, leave its minutes and dates blank. You may retain a
complete valid manual date pair with blank minutes to record an unmeasured planned
window. A partially populated date pair fails. A header-only diary is valid.

## Run and read the report

Build the native `src/cmd/goal_effort` package with the pinned root Town graph
and its exact paired Chat R68 workspace. Then run:

```sh
goal_effort /absolute/standing-goals.json /absolute/effort.csv json > goal-effort.json
goal_effort /absolute/standing-goals.json /absolute/effort.tsv csv > goal-effort.csv
```

The command reads each regular file once, with a 1 MiB size limit checked before
reading. It never writes inputs, updates the goal registry, starts a watch or
contacts another service. It prints stdout only after the entire report succeeds.
Failures print stderr and exit 1, with empty stdout. Redirection can itself create
an empty destination on failure. Never redirect output onto either input because
the shell would truncate it before the command starts. Read stable snapshots when
another process could update your source files; this is not a cross-file atomic
snapshot or live-state authentication.

JSON includes every saved goal in file order, even disabled or unmeasured goals.
Every diary period remains in that goal's input order, with its exact 1-based data
row, both date windows, outcome and note. Row numbers are after the header, not
physical line numbers. Its four measurement values are numbers or null. For each
period:

- `town_minutes = review_minutes + supervision_minutes + followup_minutes`,
  only when all three components were measured
- `manual_minus_town_minutes = manual_minutes - town_minutes`, only when both
  methods are fully measured; a negative result means more reported Town effort

Each goal also has totals across its supplied nonoverlapping periods. A field's
total is null if any period is missing that field, and all minute totals are null
for a goal with no diary rows. `complete_town_periods`, `paired_periods` and
`period_count` show coverage. Missing values never silently become zero or disappear
from a total. There is no cross-goal ranking or portfolio total: different outcomes,
people and date windows must not be treated as a controlled comparison.

CSV is a one-row-per-goal summary with those totals/coverage counts. Unknown
minutes are blank and explicit zero is `0`. It retains the original goal position,
source diary rows, source digests and `period_pairs_json` containing both windows
and outcomes for each contributing row. Use JSON for the individual measurements
and notes. CSV quotes every cell, doubles quotes and uses CRLF. It prefixes
formula-leading strings with an apostrophe, including formula-looking goal titles
and computed negative differences. Import CSV as text; remove the apostrophe from
a known computed numeric column only if you deliberately want spreadsheet arithmetic.
JSON retains numeric negatives and the exact original text values.

Both formats record SHA-256 digests of both original UTF-8 input files. JSON
additionally records their byte counts. BOMs and line endings affect the digest.
The JSON contract is
`moontown.goal-effort-report.v1`. Keep the input files with the report for replay.
These are unsigned source fingerprints, not proof of current registry state,
measurement accuracy, Book authenticity or accepted knowledge.

## Try the included synthetic example

`assets/samples/goal-effort/standing-goals.json` is produced by the existing
`storage.save_standing_goals_file` API in the native integration test. It is not a
live user's state. `effort.csv` and `effort.tsv` contain the same four diary rows.

```sh
goal_effort assets/samples/goal-effort/standing-goals.json assets/samples/goal-effort/effort.csv json
goal_effort assets/samples/goal-effort/standing-goals.json assets/samples/goal-effort/effort.tsv csv
```

- Customer goal: two period pairs, manual 70 minutes, Town 40, difference +30
- Market goal: Town 15 minutes; baseline and difference unknown
- High-supervision goal: manual 5, Town 17, difference -12
- Paused goal: no measured periods; all minute totals unknown

The numbers describe only the supplied synthetic measurements. Positive differences
are not causal time-saved estimates, quality gains, revenue or a recommendation to
keep a goal. This tool does not automatically pause low-value coordination or set
an execution/attention budget. Review the evidence before making that decision.

## Bounds and API

Inputs: 1 MiB each, at most 2,000 saved goals and 2,000 diary periods. The shared
CSV/TSV parser additionally enforces lossless UTF-8, rectangular records, no NUL,
128 columns and 100,000 cells. The fixed diary has eleven columns. Final output is
at most 4 MiB; oversize output fails without truncation. All sums are bounded by
these minute/row limits and stay within exact signed 32-bit integer range.

`goal_effort.report(goal_bytes, diary_bytes, delimiter, format="json"|"csv")`
is the reusable portable API and returns `Result[String, String]`. It uses the
same complete parsers and goal type as the CLI. The focused tests cover exact
identity, paired windows, overlap/duplicate rejection, missing data, negative/zero
differences, CSV/TSV/Unicode/multiline notes, limits, native saved-goal readback,
real executable output and unchanged inputs. They do not qualify a graphical UI,
a live service or causal productivity outcomes. Cumulative qualification stays R50.
