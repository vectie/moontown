# Executable Book Coordination

Last checked: 2026-06-19.

Moontown is the coordination layer for MoonBooks. It is not only a scheduler:
it is the town-level system where books communicate, standing goals wake up,
new ideas are surfaced, and results are routed for review.

## Standalone Project Rule

Moontown must run as its own checkout. It coordinates books and workers through configured roots, published packages, and runtime protocols; it must not assume adjacent MoonBook, MoonClaw, or Moondesk source checkouts exist. Optional integration tests may use explicit environment variables, but default runtime behavior should stay within the Moontown workspace.

## Ownership

| Concept | Moontown responsibility |
| --- | --- |
| Standing goal | Recurring or ongoing intent for a target MoonBook. |
| Town event | Cross-book signal, notification, failure, result, or synthesis event. |
| Book-to-book message | A routed proposal, reference, or handoff between MoonBooks. |
| Idea discovery | New source signals, pattern suggestions, candidate books, and follow-up prompts. |
| Notification | Tell the operator when meaningful new knowledge, failures, or review work appears. |
| Coordination memory | Town-level memory of what happened across books, without taking over each book's topic truth. |

MoonBook owns durable topic memory. MoonClaw owns bounded execution. Bookkeeper
owns acceptance. Moondesk owns human display and control.

## Call Chain

```text
Moontown daemon tick or town event
  -> due standing goal / cross-book signal / new idea
  -> route to target MoonBook lane
  -> dispatch bounded work to MoonClaw when execution is needed
  -> MoonBook stores result/proposal/review artifacts
  -> Bookkeeper accepts or rejects
  -> Moontown records town event and notifies Moondesk/operator
```

## Book Event Contract

Moontown mirrors MoonBook's `moonbook.executable_event.v1` JSON contract in its
own `moonbook_contracts` package. This is a runtime contract, not a source-code
dependency on a sibling MoonBook checkout, so Moontown remains a standalone
project.

The contract is the portable handoff after MoonBook persists a result:

- `knowledge_accepted`: durable knowledge or executable artifacts can be treated
  as accepted book state.
- `review_required`: durable artifacts exist, but Bookkeeper/operator review
  must accept them before other books or town policies depend on them.

Core fields are `protocol`, `id`, `source`, `book_id`, `result_id`,
`event_type`, `accepted`, `requires_review`, `notify_town`, `summary`, and
`artifacts`. Optional fields are `run_id`, `evidence_id`, `review_path`, and
`lifecycle_proof`; they may be omitted by JSON encoders when absent.

`lifecycle_proof` mirrors MoonBook's persisted executable lifecycle proof. It
is not a scheduling fact and it does not accept knowledge by itself. Moontown
uses it only for routing: complete lifecycle proof strengthens accepted
knowledge notifications, while blocked lifecycle proof becomes a
`book.lifecycle_blocked` town signal with the first blocker id.

Moontown projects those payloads into town events with kinds such as
`book.knowledge_accepted`, `book.review_required`, and
`book.lifecycle_blocked`. It may notify operators or route follow-up
book-to-book work from those events, but topic truth and artifact ownership stay
in MoonBook.

MoonBook persist responses now include the exact event object plus its
book-local paths:

```text
<book>/.moonbook/events/<event-id>.json
<book>/.moonbook/events/latest.json
```

Moontown should consume `PersistResultOutcome.executable_event` from the
MoonBook adapter. It should not infer accepted or review-required state from
page counts, sidecar shape, or review queue text.

## Book State Snapshot

Moontown also mirrors MoonBook's `moonbook.book_state.v1` snapshot in the
MoonBook adapter. The adapter calls:

```text
moonbook wiki extension state [root]
```

and treats the returned snapshot as the primary read model for book status. The
snapshot includes catalog metadata, summary counters, health, the embedded
knowledge bundle, latest executable event, and canonical paths. Moontown may
apply town-local accounting policy after decoding the snapshot, but it should
not scrape MoonBook summary pages, generated site files, review queues, or event
files as separate truth sources.

## MoonCode Sidecar Reconciliation

MoonCode results are imported through the same runtime boundary. MoonClaw writes
portable `mooncode-book-result` JSONL sidecars under a book workspace:

```text
<book>/.moonclaw/mooncode/sessions/<session>/book-results.jsonl
```

Moontown supervision scans those sidecars, validates that each payload contains
either a direct `BookResult` or a nested `book_result`, and then calls MoonBook's
existing `wiki extension persist` CLI through the MoonBook adapter. Moontown does not
link against MoonBook source internals and does not read MoonClaw session state
except for the portable JSON sidecar log.

Imported sidecars are deduped in:

```text
<book>/.moontown/mooncode-book-results/processed.jsonl
```

After a successful persist, Moontown records `book.mooncode_sidecar_persisted`
and projects the executable-book event into `book.review_required` or
`book.knowledge_accepted` when the result asks the town to notify.

## Current Validation

Static inspection on 2026-06-19 found that Moontown already has many of these
pieces: standing-goal registries, daemon ticks, target book ids, watcher ledgers,
town synthesis, runtime status, worker routing, civic communication schedules,
and book-quality repair loops.

The remaining product/documentation gap is to make the communication and idea
routing role explicit. Existing docs often describe scheduling and daemon loops
well, but the town should also be documented as the place where MoonBooks share
signals, propose follow-up work, and coordinate reviewable new ideas.

## Documentation Rule

When updating Moontown docs:

- Describe Moontown as coordination, not only scheduling.
- Keep topic truth and accepted artifacts in MoonBook.
- Keep execution in MoonClaw.
- Use standing goals and town events for long-running intent and notifications.
- Make book-to-book messages/proposals explicit when a workflow crosses books.
