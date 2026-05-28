# Wenyu Building Protocol Plan

This document corrects the civic-building abstraction.

A Wenyu building is not primarily a research book, a static UI card, or a
single agent. A building is a civic protocol place: it receives people,
agents, requests, facts, proposals, constraints, review decisions, and
runtime signals; it aggregates them; it lets agents exchange information under
module-specific rules; it reduces the noisy inputs into a useful civic output;
and it distributes that output to the right books, agents, UI surfaces, and
review queues.

The closest engineering analogy is map/reduce, but the reducer should not be a
hardcoded algorithm. Moontown should hardcode the envelope, routing,
permissions, ledgers, and safety gates. MoonClaw, guided by building-specific
`SKILL.md` files, should decide how to aggregate, compare, judge, synthesize,
and distribute for each building.

## Current Gap

The current Wenyu civic model has useful pieces:

- `module_mode` distinguishes agent workspaces, exchange places, projection
  surfaces, gateways, and hybrids.
- each module has a canonical `book_id`
- each module has a dedicated skill pack
- each module can seed MoonBook pages, schemas, review queues, and projections
- the viewport can show module health and building interiors

But the model is still incomplete because the building is mostly represented as
a service/workspace binding. It does not yet have first-class protocol state:

- no typed building inbox
- no exchange ledger
- no aggregation/reduction ledger
- no distribution ledger
- no explicit participant roles
- no protocol policy for who can send what to whom
- no AI-mediated “reduce” step that chooses the best civic output from all
  available inputs

That is why the UI can show buildings and workspaces, but the buildings do not
yet feel like real civic places where agents and information gather,
negotiate, transform, and leave with useful results.

## Implemented Slice

As of 2026-05-27, Moontown has the first protocol runtime slice in place.

Implemented:

- `civic/protocols.mbt` defines one `BuildingProtocolDefinition` per enabled
  Wenyu civic building.
- `civic_protocol_registry_runtime.mbt` bootstraps
  `.moontown/civic/protocols.json`; `civic_protocol_status_runtime.mbt`
  projects `.moontown/civic/protocol-status.json`.
- `civic_protocol_store.mbt` owns protocol ledger paths, writes, counts, and
  latest-record reads.
- each civic MoonBook seed now receives
  `raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md`.
- the generic Wenyu civic skill and each module-specific worker prompt now
  tell MoonClaw to read the building protocol contract before acting.
- Social Square has a deterministic proof slice with durable inbox,
  contribution, reduction, outbox, and review ledgers.
- Social Square can run any `CivicSalonScenario` template as a `research-salon`
  communication-pattern proof slice: internal participant workspaces
  contribute domain perspectives, the building asks MoonClaw to reduce them
  into cross-area research ideas, and the output is distributed to a question
  backlog and review queue.
- `research-salon` is one reusable communication pattern. Other civic
  workflows should use patterns such as `signal-watch`, `triage-desk`,
  `review-council`, `match-market`, `learning-cohort`, `story-forge`, and
  `incident-bridge` instead of copying salon logic.
- all 11 Wenyu civic buildings now have default communication-pattern scenario
  templates under `templates/civic-patterns/`, plus a manifest installer that
  copies them into `.moontown/civic/pattern-scenarios/` and staggers recurring
  schedules.
- Research-salon templates publish structural effectiveness metrics: participant count,
  idea reductions, testable research questions, participant-idea links,
  covered home books, and returned idea-home records.
- Each participating internal salon workspace receives
  `wiki/queries/salon-returned-ideas.md`, so reduced ideas do not stay inside
  the Social Square building. They return home for review, refinement, or
  rejection.
- `moon run cmd/main -- civic protocols status` shows protocol state across
  all buildings.
- `moon run cmd/main -- civic protocols pattern-template <path>` runs any valid
  `CivicSalonScenario` template through the same Social Square/building
  protocol envelope. This is the extensibility seam for new domains.
- `moon run cmd/main -- civic protocols schedules status` shows recurring
  communication-pattern schedules from `.moontown/civic/pattern-schedules.json`.
- `moon run cmd/main -- civic protocols schedules tick` runs only wall-clock-due
  sessions and appends round records to `.moontown/civic/pattern-runs/`.
- `moon run cmd/main -- civic doctor` projects protocol status into the civic
  service status consumed by the viewport.
- the viewport interior can show Social Square protocol state: `review`, one
  or more inbox packets, reductions, outbox records, and review items.

This is not the complete civic runtime yet. Social Square has the first full
live ledger proof slices; the other buildings now have protocol definitions,
MoonBook/MoonClaw contracts, and installable scenario packets, but most still
need repeated real reducer runs, accepted/rejected MoonBook persistence, and UI
history.

The first implementation was intentionally direct so the protocol loop could be
validated end to end. The follow-up refactor is documented in
[REFACTOR_PLAN.md](/Users/kq/Workspace/moontown/docs/REFACTOR_PLAN.md). The
current refactor pass moved the salon runtime to a scenario-template boundary:
domain behavior is described by `CivicSalonScenario` JSON, while Moontown keeps
the reusable schedule, ledger, MoonBook write, metrics, and projection
envelope. See
[CIVIC_SALON_TEMPLATES.md](/Users/kq/Workspace/moontown/docs/CIVIC_SALON_TEMPLATES.md).

## Salon Template Test

The current high-quality building test uses Social Square as a generic domain
exchange place. The scenario is intentionally multi-book rather than
single-agent, but the domain comes from JSON:

```bash
moon run cmd/main -- civic protocols pattern-template templates/civic-salons/robotics-mini-salon.json
moon run cmd/main -- civic protocols pattern-manifest templates/civic-patterns/wenyu-civic-patterns.json
```

Each participant receives a small internal workspace, a salon skill, a current
perspective page, and an open-question page. The building receives perspective
packets through the protocol inbox, maps them into contributions, asks the
MoonClaw reducer to turn cross-area tensions into research ideas, and
distributes the results to the template-defined backlog path.

The template evaluates protocol effectiveness with a structural metric, not a
truth metric:

- participants in
- reduced ideas out
- testable research questions
- cross-pollination edges
- home books covered
- returned idea-home records
- exchange-reduce-distribute completion score

The score only proves that Social Square performed the protocol loop and wrote
the outputs back to the participating books. It does not mean the research
ideas are correct or ready for publication. The review queue still decides what
becomes accepted long-horizon research work.

This is now a reusable template pattern, not a robotics-only MoonBit path.
To propagate it to another domain, create a scenario JSON that names the
building, participant workspaces, skill rules, output paths, review gate, and
optional fixture examples. The same runtime will run a MoonClaw reducer, write
internal participant workspaces, run the protocol ledgers, compute structural metrics,
and return ideas home.

## Template-Driven Salon Runtime

Recurring salon schedules load scenario files from:

```text
.moontown/civic/pattern-scenarios/<session-id>.json
```

One-off salon runs can load any template file:

```bash
moon run cmd/main -- civic protocols pattern-template templates/civic-salons/robotics-mini-salon.json
```

The template controls:

- participant workspace roster and perspectives
- generated salon `SKILL.md` behavior
- quality rules for the round
- protocol channel and reduction kind
- output paths for backlog, synthesis, metrics, reviews, and home returns
- review gate, review owner, and review reason

Moontown should not grow one MoonBit branch per domain or civic service. If a
robotics, education, policy, finance, healthcare, market, story, or bridge
workflow needs different behavior, the first move is a new scenario template
and stronger skill rules. MoonBit changes are reserved for new protocol
capabilities, not new topic names.

## 24/7 Salon Loop

The salon loop is part of the daemon path, but there is no built-in default
domain. Operators create schedules explicitly:

```json
{
  "id": "my-domain-social-square",
  "building_id": "social-square",
  "interval_ms": 1800000,
  "enabled": true
}
```

The schedule is stored in `.moontown/civic/pattern-schedules.json`, and a matching
template must exist at `.moontown/civic/pattern-scenarios/<session-id>.json`. Each
daemon tick calls the civic salon due-check, compares real wall-clock time with
`next_due_ms`, runs due salons, advances `round_count`, sets the next due time,
and appends a round record under `.moontown/civic/pattern-runs/`. This makes the
Social Square pattern long-running: participant workspaces periodically meet,
ideas are reduced, and relevant outputs return to the home workspaces.

The recurring runner now defaults to `MoonClawReducer`. A due round writes the
building reducer workspace, generated `SKILL.md`, participant JSON, reducer
contract, and `moonclaw.jobs.json`; imports a MoonClaw proposal; waits for a
valid `raw/bootstrap/civic-salon-ideas.json`; then materializes those ideas
into ledgers, participant workspaces, review queues, and projections. If MoonClaw
does not produce a valid non-empty `CivicSalonIdea` contract, the round is
recorded as blocked and retried later instead of silently falling back to
template examples.

Refactor rule: deterministic idea data is a fixture, not the civic
intelligence layer. `FixtureReducer` may consume template ideas only in tests
or explicit smoke demos. Stale projection refreshes use `PersistedReducer` and
replay the last persisted MoonClaw reducer output; they do not start another
worker and do not consume template examples.

## Correct Model

```text
resident / operator / mayor / watcher / book / worker / external source
  -> building protocol inbox
  -> AI-guided aggregation
  -> building-specific exchange
  -> AI-guided reduction
  -> review / safety gate
  -> distribution to books, agents, UI, queues, or external handoff
```

The building is the social and protocol boundary. MoonBook is the durable
memory and review substrate. MoonClaw is the reasoning/execution substrate.
Moontown is the mayor, router, runtime supervisor, and projection owner.

## Protocol Envelope

Every enabled civic building should eventually have a
`BuildingProtocolDefinition` or equivalent config record.

Required fields:

- `building_id`
- `title`
- `social_responsibility`
- `protocol_mode`
- `participant_roles`
- `input_channels`
- `output_channels`
- `aggregation_policy`
- `exchange_policy`
- `reduction_policy`
- `distribution_policy`
- `review_gates`
- `privacy_scope`
- `moonbook_role`
- `skill_packs`
- `projection_contract`

The important rule is that these fields define the operating boundary, not a
fixed algorithm. The AI uses the policy and skills to decide the best next
aggregation and reduction behavior.

Example shape:

```json
{
  "building_id": "social-square",
  "title": "Social Square",
  "social_responsibility": "Consent-aware community matching and weak-tie exchange",
  "protocol_mode": "exchange-reduce-distribute",
  "participant_roles": ["resident", "matchmaker_agent", "reviewer", "mayor"],
  "input_channels": ["resident_request", "profile_projection", "event_signal"],
  "output_channels": ["consent_request", "match_candidate", "event_plan", "review_item"],
  "aggregation_policy": "Group compatible interests and needs without exposing private memory.",
  "exchange_policy": "Only exchange resident-identifying details after explicit consent.",
  "reduction_policy": "Let the matchmaker skill choose the smallest useful introduction or no-change digest.",
  "distribution_policy": "Send consent requests to residents, review items to MoonBook, public summaries to projection.",
  "review_gates": ["external_introduction", "sensitive_profile_change"],
  "privacy_scope": "projection-safe by default",
  "moonbook_role": "consent-ledger-and-social-graph",
  "skill_packs": ["wenyu-civic-service", "civic-social-matchmaker"],
  "projection_contract": "wenyu.civic.social_matching.v1"
}
```

## Map/Reduce Interpretation

The map/reduce analogy is useful if it remains flexible:

- map
  converts incoming raw signals into typed contributions, such as a policy
  source, resident request, talent claim, market offer, contest deadline, or
  bridge handoff request.

- shuffle/group
  groups contributions by building, topic, resident, project, deadline,
  consent state, or risk class.

- reduce
  asks a role-specific MoonClaw skill to synthesize a building-native output,
  such as a checklist, match proposal, readiness plan, health digest, handoff
  packet, learning quest, points ledger update, or public story draft.

- distribute
  sends the reduced result to the correct destinations: MoonBook durable pages,
  review queues, UI projection, mayor alerts, worker tasks, resident messages,
  or confirmation-gated external handoff.

What should not be hardcoded:

- exact ranking formula for matches
- exact policy interpretation style
- exact coaching plan shape
- exact synthesis structure for stories
- exact no-change reasoning

What should be hardcoded:

- packet envelope
- channel names
- review gates
- privacy gates
- ledger persistence
- idempotency keys
- retry behavior
- projection schema
- allowed destinations

## Ownership Split

### Moontown

Moontown owns:

- building protocol registry
- routing into building inboxes
- mayor-level scheduling and supervision
- protocol ledgers under `.moontown`
- idempotency and retry accounting
- UI projection of building activity
- operator approval gates

Moontown should not own:

- deep domain memory
- detailed single-agent editing
- final civic judgment beyond policy/safety/routing gates

### MoonBook

MoonBook owns:

- durable building memory
- schemas for accepted building records
- review queues
- generated civic projections
- accepted/rejected record accounting
- long-lived wiki pages for the module

MoonBook should not own:

- town-wide routing
- cross-building scheduling
- worker process supervision

### MoonClaw

MoonClaw owns:

- AI-guided map/reduce behavior inside the allowed envelope
- source discovery when the building skill requires it
- synthesis, comparison, judgment, drafting, and packaging
- module-specific output contracts

MoonClaw should not own:

- durable civic truth
- public projection policy
- external action authority

### Moondesk

Moondesk should later own:

- detailed inspection and editing of building books
- file-manager-like access to civic workspaces
- authoring and packaging custom building protocol packs
- detailed single-agent and skill editing

Moontown should consume Moondesk outputs as portable building packs, not become
the deep workspace editor.

## Civic Building Protocol Examples

| Building | Social Responsibility | Aggregates | Reduces Into | Distributes To |
|---|---|---|---|---|
| Policy Hall | Help residents understand policy opportunities safely | official sources, questions, eligibility context | cited checklist or uncertainty review | policy book, review queue, resident answer |
| Contest Express | Improve competition readiness | contest calls, team status, submission drafts | readiness plan and mock-judge feedback | contest book, team view, review queue |
| Social Square | Enable consent-aware weak-tie exchange | interests, needs, events, consent state | match candidate or event plan | residents, social graph, review queue |
| Talent Avenue | Maintain trustworthy talent/project graph | profiles, claims, project needs, evidence | talent card, skill edge, project match | talent book, public card, operator review |
| Vitality Tower | Separate real progress from activity noise | daemon, watcher, worker, projection records | health digest and recovery queue | mayor, UI status, operations book |
| AI Science Garden | Turn AI learning needs into quests | learner questions, skill gaps, examples | tutorial, exercise, quest path | education book, learner surface |
| Physical Bridge | Gate virtual-to-real handoffs | venue requests, robot status, confirmations | handoff packet or blocker | operator queue, bridge book, device layer |
| Valley Market | Govern value exchange and rewards | offers, needs, points, abuse signals | ledger update or redemption review | market book, resident projection |
| Story Radar | Convert verified town activity into public narrative | achievements, events, reviewed facts | story draft or redaction task | broadcast book, public projection |

## Implementation Plan

### Phase 1: Protocol Registry

Add a first-class building protocol registry beside the existing civic service
registry.

Deliverables:

- `BuildingProtocolDefinition` model
- one protocol definition per current Wenyu building
- JSON export for the viewport and future designer tooling
- tests proving every enabled module has protocol fields, channels, review
  gates, and skill packs

Expected code locations:

- `civic/protocols.mbt`
- `civic/protocols_wbtest.mbt`
- `ui/assets/tilemap/modules/wenyu-town-modules.json`
- `.moontown/civic/protocols.json`

### Phase 2: Building Packet Envelope

Define typed packets flowing through buildings.

Minimum packet types:

- `BuildingInputPacket`
- `BuildingContribution`
- `BuildingReductionRequest`
- `BuildingReductionResult`
- `BuildingDistributionPacket`
- `BuildingReviewGate`

Each packet needs:

- stable id
- building id
- source kind
- target channel
- privacy label
- review status
- idempotency key
- related book/run/task ids

### Phase 3: Protocol Ledgers

Persist protocol state so the town can run for days and recover.

Suggested files:

```text
.moontown/civic/protocols/<building-id>/inbox.jsonl
.moontown/civic/protocols/<building-id>/contributions.jsonl
.moontown/civic/protocols/<building-id>/reductions.jsonl
.moontown/civic/protocols/<building-id>/outbox.jsonl
.moontown/civic/protocols/<building-id>/reviews.jsonl
```

Rules:

- append-only first
- idempotency by packet id and reduction id
- no UI-only state as source of truth
- no private memory in public projection files

### Phase 4: AI-Guided Reducer Skill

Upgrade the generic civic skill and each building skill with a protocol section.

The skill must tell the model:

- read the building protocol contract first
- classify incoming packets into contributions
- decide whether enough signal exists to reduce
- choose the module-native output, not a generic research report
- distribute only to allowed channels
- create review items for unsafe or uncertain outputs
- return strict markers for the ledgers

The framework should not prescribe a fixed ranking or synthesis method. The
skill should ask the model to use judgment, imagination, curiosity, and safety.

### Phase 5: Mayor Routing

Teach the Mayor to route work into building protocols.

Examples:

- resident asks for policy help -> Policy Hall inbox
- watcher finds a new policy source -> Policy Hall inbox
- team uploads pitch deck -> Contest Express inbox
- daemon detects repeated failures -> Vitality Tower inbox
- output is ready for public story -> Story Radar inbox

The Mayor decides destination, urgency, isolation, and review gate. The building
skill decides the reduction.

### Phase 6: MoonBook Persistence

MoonBook should persist accepted reductions as building-native records.

Examples:

- Policy Hall: policy source, eligibility check, cited answer
- Social Square: consent state, match candidate, follow-up outcome
- Physical Bridge: handoff packet, confirmation, blocker
- Vitality Tower: health digest, recovery item, false-progress note

This should replace generic “research evidence” accounting for civic modules.

### Phase 7: UI Projection

The viewport should show protocol life, not just workspace health.

Building exterior:

- inbox pressure
- active aggregation
- reducing now
- waiting for review
- distribution completed
- blocked by consent/safety

Building interior:

- recent input packets
- grouped contributions
- current reduction question
- outgoing distributions
- pending review gates
- linked MoonBook pages
- working agents and their protocol roles

### Phase 8: End-to-End Validation

Create one scenario per building.

Examples:

- Policy Hall receives one resident question and one policy source, then emits a
  cited checklist plus review item.
- Social Square receives two consent-safe interest packets, then emits a match
  candidate without exposing private memory.
- Physical Bridge receives an offline request, then emits a blocker until
  operator confirmation exists.
- Vitality Tower receives daemon retries and a true domain update, then counts
  only the domain update as progress.

Acceptance:

- every building has protocol definition
- every test scenario writes inbox, reduction, outbox, and review/accounting
  records
- every output lands in the correct MoonBook role
- UI shows protocol status without inventing fake activity
- no building defaults to generic research unless its skill explicitly chooses
  source research as the correct method

## New Definition Of Done

A civic building is functioning when:

- it has a protocol definition
- it has durable inbox/outbox/reduction ledgers
- it has a dedicated skill that explains how to aggregate, reduce, and
  distribute for its social responsibility
- it can route at least one real input packet to a MoonClaw reducer
- MoonBook accepts or rejects the result with module-native accounting
- the viewport shows the protocol state
- restart/retry does not duplicate reductions or distributions

Until then, a building is only a configured module with seeded workspace
support, not yet a real civic place.
