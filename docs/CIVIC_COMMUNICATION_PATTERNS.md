# Civic Communication Patterns

Last updated: 2026-05-28

Moontown buildings should not be hardcoded as one-off workflows. A building is
a place that runs a communication protocol pattern: it receives packets from
MoonBook workspaces, lets MoonClaw reduce or route them with a skill contract,
writes ledgers, and distributes reviewable outputs back to the right homes.

The old "salon" naming is now treated as one pattern: `research-salon`.
Research salons are useful for knowledge work, but other civic tasks need
different patterns and different `SKILL.md` contracts.

## Runtime Rule

Moontown owns:

- pattern registry and protocol envelope
- schedule and wall-clock due checks
- inbox, contribution, reduction, outbox, return-home, and review ledgers
- projection metadata and UI-safe summaries

MoonBook owns:

- building workspaces
- participant/home workspaces
- wiki pages, review queues, generated sites, and durable memory

MoonClaw owns:

- role-specific reduction, matching, review, triage, or synthesis work
- the output contract required by the selected pattern

## Pattern Registry

The registry lives in
[civic_communication_patterns.mbt](/Users/kq/Workspace/moontown/civic_communication_patterns.mbt).

| Pattern | Use It For | Typical Output |
| --- | --- | --- |
| `research-salon` | multiple specialists exchange perspectives and create non-obvious questions | research ideas, open questions, next experiments |
| `signal-watch` | periodic long-horizon monitoring | change/no-change digest, accepted facts, rejected facts |
| `triage-desk` | request intake and routing | owner, priority, escalation, missing-input decision |
| `review-council` | artifact quality gates | accept/revise/reject decision and fixes |
| `match-market` | needs/offers/talent/resource matching | consent-safe introductions or deal rooms |
| `learning-cohort` | education and workshop loops | lesson plan, exercise, assessment queue |
| `story-forge` | public-safe narrative synthesis | story draft, claims, consent review |
| `incident-bridge` | real-world coordination and physical gateways | status, escalation, recovery plan |

## Scenario Contract

A scenario template can declare:

```json
{
  "communication_pattern_id": "research-salon",
  "communication_pattern_label": "Research Salon"
}
```

If the fields are absent, the current civic exchange runtime defaults to
`research-salon` because the compatibility materializer still uses the
`CivicSalonIdea` record shape. The scenario skill now treats that record as a
generic reviewable pattern-output contract: for non-research patterns,
`research_questions` means follow-up/review questions, and `next_experiment`
means the smallest useful next action, artifact, drill, lesson, match review,
or story draft.

Default Wenyu civic pattern scenarios live under
[templates/civic-patterns](/Users/kq/Workspace/moontown/templates/civic-patterns)
and are installed together by
[wenyu-civic-patterns.json](/Users/kq/Workspace/moontown/templates/civic-patterns/wenyu-civic-patterns.json).

## Civic Mapping

Current recommended Wenyu mappings:

- `town-shell`: `triage-desk`
- `resident-twins`: `review-council`
- `policy-hall`: `triage-desk`
- `contest-express`: `review-council`
- `social-square`: `match-market`
- `talent-avenue`: `match-market`
- `vitality-dashboard`: `signal-watch`
- `ai-garden`: `learning-cohort`
- `physical-bridge`: `incident-bridge`
- `valley-market`: `match-market`
- `broadcast-tower`: `story-forge`

## Implementation Direction

The current runtime has one shared compatibility materializer that can run all
eight pattern ids from scenario data. Do not add a MoonBit branch per civic
building. Extract or replace the compatibility type only when the pattern needs
new structural fields that cannot be expressed through the current generic
output shape.

Shared envelope steps:

- load scenario
- resolve pattern
- create reducer workspace
- import MoonClaw packet
- validate output contract
- write protocol ledgers
- update MoonBook pages
- update projection

Each pattern should provide only:

- output contract
- generated `SKILL.md`
- validation rule
- materialization writer
- pattern-specific effectiveness metrics
