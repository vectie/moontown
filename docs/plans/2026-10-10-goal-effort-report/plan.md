# Goal-linked human effort comparison

## Problem and current state
The authored MoonTown PRD MOONTOWN-R03/F03 and N05 ask whether supervision and
review cost less human attention than a simpler manual check. Existing standing
watch accounting records worker cycles/decisions, not measured human minutes.
`src/storage/standing_goals.mbt` saves an array of the canonical
`core.StandingGoal`; `src/imported_output_contract/delimited_table.mbt` already
provides a complete bounded CSV/TSV parser. Neither links an effort diary to goals.

## Goal, protocol fit, and non-goals
Import a locally supplied effort diary, resolve every row against an exact saved
StandingGoal file, and return a complete per-goal report plus its measured periods.
Documents are the evidence: retain source byte hashes, original data-row positions,
defined outcomes and notes. Do not derive minutes from worker ticks, claim causal
productivity gains, change schedules, approve work, or contact services.

## Design and alternatives
A small portable `goal_effort` package owns parsing, goal binding and aggregation;
a native `cmd/goal_effort` command owns bounded file reads and stdout. Reuse canonical
StandingGoal decoding and the existing delimited table parser. Separate explicit
manual/review/supervision/follow-up values; blanks stay unknown and zero is explicit.
Reject overlapping windows per goal to prevent accidental double counting. Require
valid ISO date windows on both methods, equal positive day counts, nonoverlapping
baseline windows, and a human-written common outcome for each comparison.
A generic table comparison duplicates Desk and is out of scope. A dashboard/UI or
automatic watch instrumenter would not establish actual human effort and is deferred.

## Affected files and steps
1. Add goal_effort portable parser, report types, aggregation and JSON/CSV renderers.
2. Add bounded read-only native CLI and synthetic goals/diary fixtures.
3. Add focused API and native CLI verification and a usage guide.

## Acceptance and validation
- [x] Existing saved StandingGoal records decode without new state/schema.
- [x] Known, disabled and unmeasured goals retain identity/title/Book context.
- [x] Same-goal disjoint half-open dates aggregate; overlaps and unknown IDs fail.
- [x] Missing components/baselines remain unknown; zero, positive and negative
      differences are explicit and full period evidence remains available in JSON.
- [x] CSV/TSV, Unicode, multiline notes, bad numbers/dates/UTF-8 and limits covered.
- [x] Native CLI writes only a successful complete report; inputs stay byte-identical.
- [x] Final focused tests bind to committed source/tree and exact-base patch replay.

Use pinned environment/private HOME/XDG and external targets. Portable package
check/test on JS; native CLI build/replay under shared native lock, frozen/strip/one
job with >4 GiB disk reserve. No broad aggregate or provider qualification.

## Recovery and follow-up
Remove/revert this feature commit to recover the exact base; inputs are read-only.
Keep all source/dependency/fixture/evidence files. R50 cumulative qualification is
unchanged. Further UI integration or automatic measurement needs its own decision.

Final exact-commit replay and qualification evidence are retained in the delivery
AUTHOR_RECEIPT.json, TESTED_SOURCE.json and verification logs; these are the
authoritative final statuses for this plan.
