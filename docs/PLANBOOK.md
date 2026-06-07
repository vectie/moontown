# Moontown Planbook

The planbook is the third durable MoonBook book type in Moontown.

Research books answer "what is true or changing?"
Course books teach "how should a beginner learn this?"
ToolBooks expose "what usable tool should this book power?"
Planbooks decide "what should we build, change, verify, and ship?"

The goal is to make planning a persisted artifact, not a chat side effect.
For non-trivial code or product work, Moontown should create or update a
planbook before execution starts. MoonClaw can then execute against the plan,
mark acceptance criteria, and leave reviewable evidence.

## Why This Exists

The current Moontown repo already has strong execution paths:

- MoonTown routes work and supervises the daemon.
- MoonBook owns durable workspace memory and projection.
- MoonClaw executes bounded work through skills and result contracts.

The weak point is product/code intent drift. A request can start as a design
idea, become a UI task, turn into a MoonBook task, and then land as code without
a stable checkpoint that explains why the direction is correct.

The planbook fixes that.

## Document Protocol Philosophy

PlanBook must preserve the town's baseline architecture rule:

> Everything durable is a document/book. Everything active is a protocol
> running over documents. Agents are temporary workers that read/write
> documents through protocols. Buildings are protocol places.

This rule is documented in
[docs/DOCUMENT_PROTOCOL_PHILOSOPHY.md](/Users/kq/Workspace/moontown/docs/DOCUMENT_PROTOCOL_PHILOSOPHY.md)
and in the PlanBook workspace at
[wiki/planning/document-protocol-philosophy.md](/Users/kq/Workspace/moontown/.moontown/books/plan-moontown-quality/wiki/planning/document-protocol-philosophy.md).

For future self-build work, the planbook should model durable state as files,
books, ledgers, schemas, and review queues. It should model active behavior as
protocol rounds over those documents. It should model MoonClaw agents as
temporary process-like participants, reducers, critics, reviewers, and
bookkeepers, not as the durable source of truth.

Every non-trivial implementation plan should include a `Document Protocol Fit`
section:

- source of truth: which document/book owns durable state?
- protocol owner: which building or plan owns active exchange?
- agent roles: which temporary workers are needed?
- ledgers: where are events and decisions appended?
- review gate: what must be accepted before promotion?
- projection: which UI or site reads the resulting state?

If a plan cannot answer those questions, it is not ready for autonomous
implementation.

## Operating Architecture To Preserve

Every PlanBook plan, repair, and review must preserve this architecture:

```text
Mayor routes and supervises
  -> building protocol or target MoonBook hydrates durable context
  -> MoonClaw worker executes one bounded packet
  -> MoonBook bookkeeper reviews and persists memory/projection changes
  -> Moontown records health, visual state, and next action
```

Do not blur these roles:

- A civic building is a protocol place for exchange and reduction, not a
  generic persistent agent.
- A MoonBook is the durable book/workspace and memory surface.
- A MoonBook bookkeeper is the resident role that wakes to maintain that book.
- A MoonClaw worker is a temporary executor.
- A PlanBook is the durable implementation-control book.
- The Cookbook is the accepted stable-state book.

Plans must say how output returns home. For research, this means source/wiki/
synthesis/review pages. For course work, this means lessons, exercises, and
checkpoints. For ToolBooks, this means accepted data, analysis reports, app
source, tool manifest, generated web tool, review queue, and civic building
route. For civic work, this means inbox/contribution/reduction/outbox/review/
return-home ledgers. For implementation work, this means code changes, tests,
validation evidence, commit readiness, and cookbook impact when stable
definitions change.

## Book Types

| Book type | Primary question | Durable output | Main owner |
| --- | --- | --- | --- |
| Research book | What is true, new, or uncertain? | sources, evidence, synthesis, reports | MoonBook |
| Course book | How should someone learn this? | lessons, exercises, checkpoints | MoonBook |
| ToolBook / AppBook | What usable tool should this knowledge power? | reports, data, `tool-manifest.json`, app source, generated tool page | MoonBook + Moondesk |
| Planbook | What should be built and how will we know it worked? | `plan.md`, acceptance criteria, execution log, review notes | MoonBook + Mayor |
| Cookbook | What is the stable state of the town? | canonical docs, definitions, runtime index | MoonBook |

The cookbook is the stable control book. A planbook is a working decision book.
Plans may update the cookbook after they are accepted.

## ToolBook / AppBook Roadmap

A ToolBook is a MoonBook whose durable output includes an interactive web tool,
not only markdown pages. The book still follows document protocol philosophy:
the source of truth is files in the book, and active agents are temporary
workers that update those files through protocols.

Canonical flow:

```text
Moondesk writes an App ToolBook config/request document
  -> Moontown daemon processes the book-template request
  -> MoonBook workspace is created with report, app, manifest, and review files
  -> Moontown registers a standing goal for the book
  -> MoonClaw watches sources, analyzes data, updates app source, validates tool
  -> MoonBook bookkeeper accepts or reviews data/tool changes
  -> Moontown civic building links to the live generated tool and latest report
```

Required durable files:

- `book.json`
- `tool-manifest.json`
- `raw/data/latest.json`
- `wiki/methods/analysis-method.md`
- `wiki/tools/tool-spec.md`
- `wiki/reports/latest-analysis.md`
- `wiki/reviews/tool-review.md`
- `app/index.html`
- `book/site/generated/tool.html`

The template is `app-tool-book` in `templates/books/app-tool-book/`. It is
installed through the same request inbox as other book templates, so a Mayor,
Moondesk, or future planning agent can create one without Codex manually
copying files:

```text
.moontown/book-template-requests.json
  request.template_id = "app-tool-book"
  request.config_path = "<config>.json"
```

PlanBook acceptance rule: if a plan asks for a book-backed usable tool, it must
create or update an App ToolBook request rather than hardcoding a one-off page
inside Moontown. Moontown presents the building and route; MoonBook owns the
tool source and generated page; MoonClaw performs bounded watch/analyze/build
work; Moondesk edits the method/spec and approves durable changes.

## Mayor, Bookkeeper, And Worker Roles

PlanBook must distinguish three kinds of active AI role:

- `Mayor`
  is the town-level supervisor. It is logically long-lived through the daemon
  and owns standing goals, routing, scheduling, escalation, recovery,
  cross-book priority, and civic/building protocol dispatch.
- `MoonBook Bookkeeper`
  is a resident role for one book. It is logically live through scheduled or
  event-driven keeper ticks, not necessarily a continuously burning process. It
  wakes when results arrive, reviews change, projections age, or the operator
  asks the book to act. It owns working memory, durable wiki promotion,
  evidence/source ledgers, review policy, book health, next questions, and
  generated site quality.
- `MoonClaw Worker`
  is a freelance bounded executor. It spawns for one packet, uses tools,
  produces observations/results/artifacts/memory candidates, and exits. It does
  not own durable memory or town policy.

Future plans must say which role is responsible. If a task is about durable
book memory, route it to the bookkeeper. If a task is tool-heavy execution,
spawn a worker. If a task is cross-book priority or cadence, keep it in the
Mayor.

## Stable Watch State

A mature town is not always busy. The desired stable state is:

- daemon healthy
- active workers `0`
- stable waiting reported as `true` in the live autonomy spine
- stable waiting observation streak increasing across consecutive quiet daemon
  observations
- unresolved failures `0`
- PlanBook open gaps `0`
- due standing goals `0`
- MoonBook quality audit includes every live runtime book from the saved town
  snapshot, not only the curated catalog
- review queues visible but not counted as accepted progress
- transient infrastructure failures cleared or deferred without becoming
  durable domain evidence or review debt
- detached MoonClaw startup logs do not count as terminal watcher failure when
  a receipt/run is still pending or has already been confirmed
- scheduler-only deferrals do not count as watcher decisions. If the Mayor
  defers a due standing goal because the per-tick dispatch budget or live
  external-execution cap is full, the goal must remain due until an actual
  watcher cycle writes a durable watcher ledger record.
- transient infrastructure debt visible as its own live-spine metric, separate
  from unresolved failures and no-change cycles
- civic protocol schedules enabled for the next real-world interval
- civic service reconciliation current for protocol-active buildings; review
  gated exchanges should appear as `needs_review`, not accepted facts

Visible review queues do not block the live loop by themselves. They mean the
town has review-gated artifacts waiting for a bookkeeper, operator, or later
AI-review pass. The Mayor should keep watching and dispatching scheduled work
while keeping those queues visible.

For overnight or long-horizon checks, do not infer stability only from the
latest status text. The authoritative evidence is the live autonomy spine:

- `stable_waiting`
- `stable_waiting_observation_streak`
- `stable_waiting_blockers`
- `town-journal.jsonl`

`stable_waiting_blockers` must be empty before the town can claim it is waiting
cleanly. The streak proves that the condition survived repeated daemon
observations rather than one lucky tick.

Weak live books are not allowed to disappear just because they were created by
standing watches rather than hand-registered in the MoonBook catalog. The
book-quality audit merges the saved runtime snapshot into the catalog view, so
research books such as OPC, LLM training, robotics, agents, and hardware are
judged by the same structural and semantic review loop as canonical books.

## Lifecycle

```text
idea / bug / operator voice note / town anomaly
  -> Mayor creates or updates a planbook goal
  -> Planbook gathers codebase, docs, history, and optional web/community context
  -> Planbook writes plans/<date>-<slug>/plan.md
  -> MoonClaw executes against that plan
  -> MoonClaw marks acceptance criteria and writes execution evidence
  -> MoonBook reviews and persists the result
  -> Cookbook is updated only when the stable state changed
```

## Planbook Workspace Layout

```text
.moontown/books/plan-<area>/
  raw/
    inbox/
      <timestamp>-operator-note.md
      <timestamp>-bug-report.md
      <timestamp>-screenshot-note.md
    context/
      codebase-map.md
      recent-decisions.md
      external-research.md
  plans/
    2026-05-29-wenyu-planbook/
      plan.md
      acceptance.md
      execution-log.md
      review.md
      handoff.md
  wiki/
    index.md
    planning/decision-records.md
    planning/open-questions.md
    planning/role-model.md
    planning/quality-gates.md
    history/journey.md
  skills/
    code-plan/SKILL.md
    code-review/SKILL.md
    doc-sync/SKILL.md
.moontown/
  planbook/
    autonomy.json
    autonomy.md
    latest-validation.md
```

MoonBook also seeds a native `planbook` skill for new workspaces at
`skills/planbook/SKILL.md`. When the MoonClaw extension is enabled, MoonBook
exposes dedicated `wiki_planbook_controller` and `wiki_planbook_worker`
profiles. Those profiles use the PlanBook skill and explicitly avoid injecting
research-report or course structure into implementation plans.

The planbook should not store long-term domain research unless that research is
needed for a plan. Domain facts still belong in research books. Beginner
teaching still belongs in course books.

## `plan.md` Contract

Every non-trivial plan should include:

- Problem statement
- Current state, with links to files or docs
- Goal and non-goals
- Document Protocol Fit
- Design decision
- Alternatives considered
- Affected files
- Implementation steps
- Acceptance criteria with checkboxes
- Test and validation commands
- Rollback or recovery path
- Follow-up tasks

Use [templates/planbook/PLAN_TEMPLATE.md](/Users/kq/Workspace/moontown/templates/planbook/PLAN_TEMPLATE.md)
as the default shape.

## Plan Quality Rules

A plan is not ready for execution if:

- it does not name the problem
- it does not identify the durable document/book source of truth
- it treats an agent run as the source of truth instead of a protocol over
  documents
- it does not mention affected files or packages
- it hides unresolved decisions
- it has no acceptance criteria
- it has no validation command
- it changes ownership boundaries between Moontown, MoonBook, MoonClaw, and
  Moondesk without saying so
- it reads like generic advice instead of this repository's situation

## Execution Rules

MoonClaw execution should:

- read the plan first
- update `execution-log.md` as work progresses
- mark acceptance criteria only after validation
- write blockers into `review.md`
- avoid creating `v1`, `v2`, `v3` replacement plans unless the old plan is
  superseded by a clear decision record

The planbook is allowed to evolve a plan in place, but it must preserve a
decision trail.

## Implementation Backlog And Change Log

The live town must have planned work to choose from. That source of future work
is a MoonBook-managed PlanBook document, not a hardcoded MoonBit list:

- `raw/backlog/implementation-backlog.json`
  is the editable backlog. Operators or future MoonBook tools can add, remove,
  reprioritize, pause, or close implementation goals by changing this JSON.
- `wiki/planning/implementation-backlog.md`
  is the generated human-readable projection of that backlog.
- `wiki/planning/backlog-progress.md`
  shows open/completed/blocked counts and the next code-building check cadence.
- `wiki/planning/stop-policy.md`
  defines when a worker should stop instead of generating more code.
- `wiki/history/change-log.md`
  records live PlanBook autonomy and repair events over time.
- `raw/backlog/completed/<id>.md`
  is the completion evidence for an accepted backlog item.

The daemon chooses the highest-priority open backlog item only when no stricter
self-build criterion is already open. This keeps the town active without letting
it invent unbounded work.

Stop conditions are explicit:

- Stop when completion evidence exists for the selected item.
- Stop when the item is `done`, `blocked`, or `paused`.
- Stop when the worker discovers the requested feature is already complete; it
  should update progress/backlog evidence, not create code churn.
- Stop when validation fails or the focused diff would cross ownership
  boundaries.
- Stop and update the plan/backlog first when the plan is stale.

Cadence is also explicit. While open backlog work exists, the town can take the
next bounded task immediately, one at a time. Once the backlog is clear, the
code-building visit decays to a 30-minute check interval.

## Overnight Monitoring Expectations

When the daemon is left running, the next morning review should be able to
answer these questions from durable artifacts rather than chat memory:

- Did the daemon remain healthy, with success count increasing and failure
  count stable?
- Did standing-watch books gain accepted facts, review items, questions, or
  explicit no-change decisions?
- Did civic building protocols add round records and return-home outputs?
- Did PlanBook either close a gap, dispatch a bounded repair, or record a clear
  blocker/no-change decision?
- Did code/test state change only when a PlanBook repair had validation
  evidence and commit readiness?
- Did UI projections read the live state rather than static demo content?

If the answer is no, the correct repair is usually a wiring fix: connect the
existing daemon, schedule, building protocol, MoonBook bookkeeper, MoonClaw
worker, PlanBook evidence, and UI projection surfaces. Do not add a second
hardcoded workflow that bypasses those documents.

## Self-Build And Self-Healing Loop

The current Moontown runtime now has a PlanBook autonomy doctor. It is not a
replacement for MoonBook-native planning, but it is the first live spine for
self-build governance:

```text
daemon tick / manual doctor
  -> inspect PlanBook criteria
  -> write .moontown/planbook/autonomy.json
  -> write .moontown/planbook/autonomy.md
  -> update PlanBook execution evidence and active review pages
  -> update PlanBook backlog projection, progress, stop policy, and live change log
  -> expose open gap count in .moontown/live-autonomy.json
  -> queue one bounded repair packet for the first open gap
  -> Mayor sees active repair work as live next action
```

The doctor checks concrete criteria such as:

- PlanBook workspace exists with plans, skills, and quality gates.
- Live autonomy spine exposes PlanBook open-gap count.
- Operator UI references live autonomy state.
- Standing-watch outputs have a strict result contract.
- AI semantic review results are persisted.
- The daemon has a bounded semantic-review cadence that dispatches at most one
  book-quality review at a time.
- Standing-goal cadence accounting only advances when a real watcher cycle is
  launched and recorded. Budget/cap deferrals remain due and are not allowed to
  make work disappear until the next cadence window.
- Weak semantic-review results are bridged into the owning MoonBook review
  queue and into a bounded standing repair goal, so Mayor supervision can mature
  books without treating failed/no-change review records as accepted evidence.
- PlanBook repair can route repository source patches through Codex ACP instead
  of only asking Codex-in-this-chat to edit files.
- PlanBook has an editable implementation backlog and live change history.
- Validation evidence is recorded.
- MoonBook has a native PlanBook skill and MoonClaw planbook profiles.

This keeps the town honest: open implementation gaps remain visible to the
Mayor and operator until they are implemented, validated, and recorded.
The latest accounting is stricter than earlier versions: ACP route wiring is not
the same as proven self-patching. A PlanBook source-repair criterion must remain
open until an accepted MoonClaw result includes
`planbook.repair.patch_receipt.v1` evidence from a Codex ACP run rooted at the
Moontown source tree. Text-only claims, read-only sandbox attempts,
`files_changed: none`, or review-only ACP runs are useful diagnostics, but they
do not prove that the town patched its own code.
When all criteria are satisfied, the live autonomy spine reports
`planbook_open=0` and stale repair packets no longer count as active work. If
the implementation backlog contains open items, `planbook_open` should remain
above zero and the daemon should dispatch one bounded repair at a time. When a
worker visits the code-building lane and finds the work already done, the correct
output is a plan/progress update plus completion evidence, not more code.

The repair bridge is intentionally bounded. It does not let the town run an
unconstrained generic agent loop. Instead, it writes:

- `.moontown/planbook/repair-task.json`
- `.moontown/planbook/repair-task.md`
- `raw/repair/PLANBOOK_REPAIR_CONTEXT.md`
- `skills/planbook-repair/SKILL.md`
- `plans/self-healing-repair/plan.md`
- `raw/repair/planbook-repair-*.packet.json`

Use the repair commands directly when inspecting or dispatching self-repair:

```bash
moon run cmd/main -- planbook repair
moon run cmd/main -- planbook repair status
moon run cmd/main -- planbook repair --dispatch
```

Without `--dispatch`, Moontown only queues the repair packet and records the
active repair. With `--dispatch`, the packet is imported into MoonClaw using the
PlanBook repair skill and the `planbook.repair.result.v1` output contract.
For Moontown-owned source repairs, the repair profile uses
`execution_mode: acp` and `execution_target: codex-main`; the configured ACP
target runs from the repository source root, not only the PlanBook workspace.
Daemon-created repair dispatches are detached; operator `--dispatch` may still
use inline execution when the environment explicitly enables it for debugging.
That is the intended self-patching path: Mayor/PlanBook choose and bound the
gap, MoonClaw launches Codex ACP as the code executor, Codex patches the repo,
and PlanBook reconciles the result contract after validation, diff inspection,
and commit readiness.
For a source patch, accepted reconciliation also requires a
`planbook.repair.patch_receipt.v1` receipt. The receipt is the durable boundary
between “Codex ACP was configured” and “Codex ACP actually changed, validated,
and accounted for source code.” It must identify the criterion, source root,
execution mode/target, changed files, validation commands, diff hygiene, commit
status/message, and push status. PlanBook rejects accepted source-repair claims
that do not carry this evidence.
If the gap belongs in MoonBook or MoonClaw, the repair worker must return a
precise ownership blocker instead of moving that responsibility into Moontown.

This still must stay bounded. The town should not run an unconstrained generic
agent loop with arbitrary authority. A self-patch must name target files,
acceptance criteria, validation commands, and the durable PlanBook evidence it
will update. An accepted repair must also record the software-engineering
evidence expected from a human-quality code change: validation command results,
`git diff --check`, `git status --short`, a focused diff summary, commit
status/message, and push status. The default policy allows local commit
preparation after validation but does not push unless a future policy explicitly
enables it. For `backlog-*` criteria, the repair worker must also write
completion evidence under `raw/backlog/completed/<id>.md`.
If the repair changes source code that the live daemon depends on, the worker
must also request a clean reload after validation with
`moon run cmd/main -- daemon restart "validated source patch"` and then inspect
fresh live evidence. A packet produced by a pre-reload daemon does not prove the
new code path.

## Relation To Voice And Parallel Work

The desired operator workflow is:

```text
voice note / pasted bug / screenshot
  -> planbook inbox item
  -> plan.md
  -> work execution
  -> validation evidence
  -> accepted stable-state update
```

Multiple planbooks can run in parallel, but each plan should be isolated by
area. Good examples:

- `plan-moontown-core`
- `plan-wenyu-ui`
- `plan-civic-protocols`
- `plan-daemon-reliability`
- `plan-docs-and-cookbook`

Bad examples:

- one global mega-plan for all work
- a research book pretending to be a code plan
- a course book pretending to be an implementation tracker

## Where This Should Be Implemented

Moontown should implement:

- planbook registration and routing
- mayor decision to create, resume, or execute a plan
- daemon-visible plan status
- UI surfaces for active plans and acceptance status

MoonBook should implement:

- native `planbook` workspace template
- `code-plan` skill route
- plan projection pages
- review queue for plan acceptance and drift

MoonClaw should implement:

- role-specific plan writer, implementer, reviewer, and doc-sync skills
- output contracts for plan creation, execution evidence, and review findings

Moondesk should implement:

- human file-manager surface for browsing and editing planbooks
- voice-note capture into `raw/inbox/`
- plan diff/review UI

## Immediate Moontown Rule

Moontown now has a first-class bootstrap for the current planbook workspace:

```bash
moon run cmd/main -- planbook bootstrap
moon run cmd/main -- planbook status
moon run cmd/main -- planbook doctor
moon run cmd/main -- planbook autonomy
moon run cmd/main -- planbook repair
moon run cmd/main -- planbook repair status
```

Use this repository rule:

If a change is larger than a trivial one-line fix, write or update a plan under
`docs/plans/` or a planbook workspace before implementation. The plan should be
good enough for a new Codex/MoonClaw session to continue after context loss.

The remaining upgrade belongs mostly in MoonBook: add a native `planbook`
provider/profile so future plan creation, plan review, and plan repair run
through MoonBook skills instead of only through Moontown bootstrap. Until that
exists, Moontown's PlanBook doctor keeps the gap explicit in live runtime state.
