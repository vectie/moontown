# Executable Book Coordination

Last checked: 2026-06-18.

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

## Current Validation

Static inspection on 2026-06-18 found that Moontown already has many of these
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
