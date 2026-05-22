# Mayor Standing Watch

Use this skill when the Mayor claw supervises a durable 24/7 standing topic such
as `watch-opc-news`.

## Responsibility

- decide whether a standing goal is due
- route the check to the target MoonBook
- avoid duplicate watcher runs for the same standing goal
- record the MoonBook decision in the town watcher ledger
- adjust the next due tick based on update/no-change/review/failure outcome

## Hard Rules

- Do not decide topic novelty inside Moontown.
- Do not write durable research memory into Moontown.
- Do not force a full research rewrite just because a standing goal is due.
- The target MoonBook owns baseline comparison, source fingerprints, wiki
  updates, digest history, and generated projection.
- MoonClaw owns bounded search/fetch/read/summarize execution.
- If a previous watcher execution is still active, defer instead of dispatching
  a duplicate run.

## Output Contract

Moontown consumes a MoonBook result marker shaped like this:

```text
standing_goal_decision: update | no_change | needs_review | failed
delta_score: 0-100
new_source_count: <integer>
next_check_hint: normal | slower | faster | review
```

Moontown records that marker as `WatcherRunRecord` under:

```text
.moontown/watchers/<goal-id>.jsonl
```

## Examples

### Example: no useful delta

Input situation:

- goal: `watch-opc-news`
- target book: `research-opc`
- MoonBook checked web-first sources
- MoonBook found no evidence that beats the current source baseline

MoonBook marker:

```text
standing_goal_decision: no_change
delta_score: 8
new_source_count: 0
next_check_hint: slower
```

Mayor behavior:

```json
{
  "decision": "NoChange",
  "ledger": ".moontown/watchers/watch-opc-news.jsonl",
  "next_due_policy": "increase no-change backoff, capped at 4x cadence"
}
```

### Example: useful update

Input situation:

- goal: `watch-opc-news`
- target book: `research-opc`
- MoonBook found and materialized new verified sources

MoonBook marker:

```text
standing_goal_decision: update
delta_score: 86
new_source_count: 4
next_check_hint: normal
```

Mayor behavior:

```json
{
  "decision": "Update",
  "ledger": ".moontown/watchers/watch-opc-news.jsonl",
  "next_due_policy": "normal cadence"
}
```
