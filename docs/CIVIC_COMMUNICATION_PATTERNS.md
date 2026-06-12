# Civic Communication Patterns

Last updated: 2026-05-28

Moontown buildings should not be hardcoded as one-off workflows. A building is
a place that runs a communication protocol pattern: it receives packets from
MoonBook workspaces, lets MoonClaw reduce or route them with a skill contract,
writes ledgers, and distributes reviewable outputs back to the right homes.

This follows the document protocol philosophy: durable truth lives in
documents/books, active behavior is protocol execution over those documents,
and agents are temporary workers inside the protocol. See
[DOCUMENT_PROTOCOL_PHILOSOPHY.md](/Users/kq/Workspace/moontown/docs/DOCUMENT_PROTOCOL_PHILOSOPHY.md).

The old "salon" naming is now treated as one pattern: `research-salon`.
Research salons are useful for knowledge work, but other civic tasks need
different patterns and different `SKILL.md` contracts.

## Runtime Rule

Moontown owns:

- pattern registry and protocol envelope
- schedule and wall-clock due checks
- inbox, contribution, reduction, outbox, return-home, and review ledgers
- projection metadata and UI-safe summaries
- protocol document-pack conventions such as `charter.md`, `protocol.md`,
  `agenda/current.md`, `ledger.jsonl`, `outbox/`, `review/`, and `state.json`

MoonBook owns:

- building workspaces
- participant/home workspaces
- wiki pages, review queues, generated sites, and durable memory

MoonClaw owns:

- role-specific reduction, matching, review, triage, or synthesis work
- the output contract required by the selected pattern

## Pattern Registry

The registry lives in
[civic_communication_patterns.mbt](/Users/kq/Workspace/moontown/src/civic/communication_pattern_registry.mbt).

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
- load or create the building document protocol pack
- create reducer workspace
- import MoonClaw packet
- validate output contract
- write protocol ledgers
- update MoonBook pages
- update projection

The proof of exchange is not the existence of a building card. A healthy round
must leave durable evidence in the building protocol and in participant homes:

- inbox packet or schedule claim
- participant contribution packets
- reducer output with participating books
- review gate record
- outbox/distribution record
- return-home record or review item in each affected MoonBook
- projection update that references the latest round

If a pattern cannot write these artifacts, it should report a blocker instead
of producing generic ideas.

## Service-Result Reconciliation

Protocol rounds and civic service results are separate layers.

- Protocol rounds prove that a building exchanged information: inbox,
  contributions, reductions, outbox, review, and return-home ledgers.
- Civic service results prove that the building's MoonBook support workspace
  has reconciled that exchange into its service contract.
- Review-gated protocol outputs must reconcile as `needs_review`, not as
  accepted facts.

The daemon runs a generic `civic-service` scheduled job after protocol rounds.
That job calls `reconcile_wenyu_civic_service_results`, reads the service
registry and protocol ledgers, and writes
`.moontown/book-results/goal-<book-id>-civic-service.json` through MoonBook.
This is intentionally registry-driven: adding a future building should require
a service definition and pattern scenario, not a new MoonBit branch.

Each pattern should provide only:

- output contract
- generated `SKILL.md`
- validation rule
- materialization writer
- pattern-specific effectiveness metrics
