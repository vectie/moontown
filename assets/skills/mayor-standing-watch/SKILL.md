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
- The target MoonBook bookkeeper decides what is remembered, rejected, queued
  for review, or projected.
- MoonClaw owns bounded search/fetch/read/summarize execution.
- For App ToolBooks, MoonBook owns accepted data, latest report, app source,
  `tool-manifest.json`, generated tool page, and tool review queue. Moontown
  should only schedule and expose the civic-building link.
- If a previous watcher execution is still active, defer instead of dispatching
  a duplicate run.
- A watcher tick should grow the book only when new accepted facts, changed
  pages, review items, or useful questions exist. Otherwise record a no-change
  decision and back off.
- Do not count operational watcher records as domain evidence.

## Output Contract

Moontown consumes a MoonBook result marker shaped like this:

```text
standing_goal_decision: update | no_change | needs_review | failed
delta_score: 0-100
new_source_count: <integer>
next_check_hint: normal | slower | faster | review
checked_sources_count: <integer>
new_sources_found: <integer>
accepted_facts_count: <integer>
rejected_facts_count: <integer>
wiki_pages_changed_count: <integer>
book_changed: yes | no
tool_changed: yes | no
tool_build_status: passed | failed | skipped
```

Moontown records that marker as `WatcherRunRecord` under:

```text
.moontown/watchers/<goal-id>.jsonl
```

Accounting rules:

- `new_source_count` means newly useful sources, not raw search hits.
- `book_changed: yes` means durable book knowledge changed or a review item was
  queued.
- retries, failed runs, generated site rebuilds, journal maintenance, and
  operational events must not be treated as evidence progress.
- Moontown can show operational activity, but it must not present no-change or
  failed checks as research knowledge gained.

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
checked_sources_count: 5
new_sources_found: 2
accepted_facts_count: 0
rejected_facts_count: 2
wiki_pages_changed_count: 0
book_changed: no
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
checked_sources_count: 9
new_sources_found: 5
accepted_facts_count: 7
rejected_facts_count: 1
wiki_pages_changed_count: 4
book_changed: yes
```

Mayor behavior:

```json
{
  "decision": "Update",
  "ledger": ".moontown/watchers/watch-opc-news.jsonl",
  "next_due_policy": "normal cadence"
}
```
