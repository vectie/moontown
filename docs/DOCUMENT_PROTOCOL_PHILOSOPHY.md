# Document Protocol Philosophy

This is the baseline architecture rule for Moontown, MoonBook, MoonClaw,
Moondesk, Wenyu buildings, and future self-build work.

## Canonical Summary

Everything durable is a document/book. Everything active is a protocol running over documents. Agents are temporary workers that read/write documents through protocols. Buildings are protocol places.

So the layers become:

```text
MoonBook = durable filesystem/book/wiki/state
Moontown = town-level protocol scheduler + visual map
Building = named communication/exchange protocol over one or more books
MoonClaw = temporary executor/participant/reviewer
Moondesk = human-facing desktop/file manager for books and artifacts
```

For the building task specifically, model it as a document protocol, not a single job:

```text
building/
  charter.md              # why this building exists
  protocol.md             # how participants exchange info
  inbox/*.md              # incoming contributions
  agenda/current.md       # what is being discussed
  round/YYYYMMDD-HHMM.md  # meeting/reduction rounds
  ledger.jsonl            # immutable event log
  outbox/*.md             # accepted outputs to send back to books
  review/*.md             # pending human/AI review
  state.json              # current status/progress
```

Then agents just perform roles inside that protocol:

```text
participant agent -> writes contribution into inbox
reducer agent -> turns inbox into synthesis
critic agent -> reviews contradictions/gaps
keeper/bookkeeper -> promotes accepted output back into MoonBook
mayor -> schedules next round and checks health
```

So for a Research Salon building:

```text
10 domain books come in
-> each exports current questions/findings
-> building protocol reduces/exchanges them
-> new ideas/questions are written to outbox
-> each source book imports relevant output
-> agents go back to their home books
```

This matches the Linux philosophy baseline: files/books are the stable interface. The system should avoid hidden state and avoid making agent runs the source of truth. Agent runs are like processes; documents are the filesystem.

## Core Idea

Moontown should be designed like an operating system for long-running
knowledge and civic work:

- books are the filesystem
- building protocols are services
- ledgers are append-only logs
- agents are short-lived processes
- skills are executable role manuals
- projections are views over persisted state
- the mayor is the scheduler and supervisor
- Moondesk is the human file manager

The durable truth must survive worker crashes, model changes, context loss,
UI rebuilds, and daemon restarts. Therefore, the durable truth must live in
documents, not in chat memory or transient agent runs.

## Why This Matters

If a feature is modeled as an agent job, the system loses the product after
the job finishes. The result is hard to inspect, retry, resume, review, or
compose with other buildings.

If a feature is modeled as a document protocol, the system gains:

- resumability: a later agent can continue from the same files
- auditability: every protocol round can be inspected
- reviewability: accepted and rejected outputs remain distinct
- portability: Moondesk can browse and edit the same state
- composability: multiple buildings can exchange document packets
- autonomy: the mayor can schedule recurring rounds without inventing hidden state

## Correct Mental Model

Do not ask first:

```text
Which agent should do this job?
```

Ask first:

```text
Which durable book or building protocol owns this state?
What documents define its charter, inputs, outputs, review gates, and ledger?
Which temporary agents are needed to advance the protocol one step?
```

Agents are necessary, but they are not the center of the model. They are
participants, reducers, critics, keepers, reviewers, and messengers inside a
document protocol.

## Building Protocol Example

```text
.moontown/civic/protocols/social-square/
  charter.md
  protocol.md
  agenda/current.md
  inbox/
    opc-founder-needs.md
    robotics-lab-open-question.md
  round/
    2026-05-31-1800.md
  ledger.jsonl
  outbox/
    match-candidate-2026-05-31.md
  review/
    consent-gate-2026-05-31.md
  state.json
```

The building is not the MoonBook. The building is the place/protocol. A
MoonBook support workspace may persist accepted outputs, wiki pages, and
review queues, but the product concept is the protocol place.

## Implementation Rules

- Never make an agent run the source of truth.
- Never hide durable state in prompts, chat transcript, or UI-only variables.
- Every recurring building must have a charter, protocol, inbox, ledger,
  outbox, review surface, and state file.
- Every protocol output must be either accepted, rejected, pending review, or
  returned home to a source book.
- Every self-build change should update a PlanBook plan before implementation
  and update execution evidence after validation.
- Every stable rule promoted from a plan should be copied into the cookbook.
- A new civic feature should usually start as a protocol document pack, not a
  new MoonBit branch.
- MoonBit code should implement reusable protocol capabilities, not hardcoded
  per-domain reasoning.
- Self-patching is allowed only as a bounded document protocol: PlanBook names
  the gap, target files, acceptance criteria, validation commands, and output
  contract; MoonClaw launches the configured Codex ACP target; Codex patches the
  repository; PlanBook records validation, diff hygiene, commit readiness, and
  review evidence.
- Future self-build work belongs in the PlanBook backlog JSON and its generated
  MoonBook pages. The daemon may select from that backlog, but it should not
  invent feature lists in MoonBit code.
- Stop criteria, progress, and cadence are also documents. If a worker discovers
  a task is already done or a plan is stale, it updates the PlanBook evidence
  and plan/backlog documents instead of producing code for activity.
- MoonClaw worker runs are temporary freelance processes. Bookkeepers are
  resident MoonBook roles that wake through events or schedules and decide what
  becomes durable memory. Mayor owns town routing and cadence.

## Boundary Table

| Layer | Stable responsibility | Active responsibility |
| --- | --- | --- |
| MoonBook | books, wiki, schemas, review queues, durable memory | bookkeeper decisions and projection generation |
| Moontown | town registry, schedules, ledgers, visual map, live spine | mayor supervision, routing, recurring protocol ticks |
| Building | charter, protocol, inbox, ledger, outbox, review state | exchange, reduction, distribution, social responsibility |
| MoonClaw | skills and result contracts | temporary execution, critique, synthesis, tool use |
| Moondesk | human-readable file and artifact surfaces | human edits, imports, exports, custom protocol packs |

## PlanBook Standard

When PlanBook evaluates or writes a future implementation plan, it should
include a `Document Protocol Fit` section:

- source of truth: which document/book owns durable state?
- protocol owner: which building or plan owns active exchange?
- agent roles: which temporary workers are needed?
- ledgers: where are events and decisions appended?
- review gate: what must be accepted before promotion?
- projection: which UI or site reads the resulting state?

If a plan cannot answer these questions, it is not ready for autonomous
implementation.
