# Moontown Planbook

The planbook is the third durable MoonBook book type in Moontown.

Research books answer "what is true or changing?"
Course books teach "how should a beginner learn this?"
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

## Book Types

| Book type | Primary question | Durable output | Main owner |
| --- | --- | --- | --- |
| Research book | What is true, new, or uncertain? | sources, evidence, synthesis, reports | MoonBook |
| Course book | How should someone learn this? | lessons, exercises, checkpoints | MoonBook |
| Planbook | What should be built and how will we know it worked? | `plan.md`, acceptance criteria, execution log, review notes | MoonBook + Mayor |
| Cookbook | What is the stable state of the town? | canonical docs, definitions, runtime index | MoonBook |

The cookbook is the stable control book. A planbook is a working decision book.
Plans may update the cookbook after they are accepted.

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
    planning/quality-gates.md
    history/journey.md
  skills/
    code-plan/SKILL.md
    code-review/SKILL.md
    doc-sync/SKILL.md
```

The planbook should not store long-term domain research unless that research is
needed for a plan. Domain facts still belong in research books. Beginner
teaching still belongs in course books.

## `plan.md` Contract

Every non-trivial plan should include:

- Problem statement
- Current state, with links to files or docs
- Goal and non-goals
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

Until first-class planbook automation exists, use this repository rule:

If a change is larger than a trivial one-line fix, write or update a plan under
`docs/plans/` or a planbook workspace before implementation. The plan should be
good enough for a new Codex/MoonClaw session to continue after context loss.
