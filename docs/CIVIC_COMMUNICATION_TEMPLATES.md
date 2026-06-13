# Civic Communication Pattern Templates

Last updated: 2026-05-28

The research salon is one reusable civic communication pattern. The same
template runner now covers the other Wenyu civic patterns as well: signal
watch, triage desk, review council, match market, learning cohort, story forge,
and incident bridge.

The runtime is template-driven. A domain or civic building should not require a
new MoonBit runner. A building gets a scenario template, the template names its
internal participant workspaces, communication pattern, skill rules, protocol
channels, output paths, review gate, and optional fixture examples, and
Moontown runs the same schedule, reducer, ledger, MoonBook, and projection
envelope for every scenario.

For the broader pattern taxonomy, see
[CIVIC_COMMUNICATION_PATTERNS.md](/Users/kq/Workspace/moontown/docs/CIVIC_COMMUNICATION_PATTERNS.md).

## Design Goal

Moontown owns only the civic protocol envelope:

- schedule and due checks
- building lookup
- inbox, contribution, reduction, outbox, home-return, and review ledgers
- MoonBook workspace writes
- UI projection writes
- structural metrics

The scenario owns the domain:

- title and topic
- participant book roster
- participant perspectives
- skill name, skill description, and skill rules
- quality rules
- output page paths
- review gate and owner
- fixture idea/research-question examples for deterministic tests only

The production reducer reads the generated `SKILL.md`, participant context,
and reducer contract, then asks MoonClaw to emit
`raw/bootstrap/civic-communication-results.json` using the same `CivicCommunicationIdea`
contract that Moontown materializes into MoonBook pages, protocol ledgers,
reviews, and UI projections. Template ideas are no longer production reducer
input.

## Runtime Files

- [civic_communication_scenario_types.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_communication_scenario_types.mbt)
  defines the `CivicCommunicationScenario` runtime surface, participant
  workspaces, ideas, metrics, and home-return records.
- [civic_communication_scenario_runtime.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_communication_scenario_runtime.mbt)
  loads scenario templates, materializes MoonClaw reducer output into
  intermediate participant workspaces, runs the protocol ledger slice, and
  writes the public building projection.
- [civic_communication_reducer.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_communication_reducer.mbt)
  owns the reducer modes: `MoonClawReducer` for production,
  `PersistedReducer` for stale projection refresh, and `FixtureReducer` for
  deterministic tests/smoke demos.
- [civic_communication_runner.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_communication_runner.mbt)
  runs due schedules by loading the matching scenario template.
- [civic_communication_reconcile.mbt](/Users/kq/Workspace/moontown/src/civic_runtime/civic_communication_reconcile.mbt)
  refreshes stale projections from the same scenario template.
- [assets/templates/civic-salons/robotics-mini-salon.json](/Users/kq/Workspace/moontown/assets/templates/civic-salons/robotics-mini-salon.json)
  is a small copyable research-salon example.
- [assets/templates/civic-patterns/wenyu-civic-patterns.json](/Users/kq/Workspace/moontown/assets/templates/civic-patterns/wenyu-civic-patterns.json)
  installs the default scenario set for all 11 Wenyu civic buildings.

## Where Templates Live

Recurring schedules load templates from:

```text
.moontown/civic/pattern-scenarios/<session-id>.json
```

No scenario is auto-seeded by domain-specific MoonBit code. Recurring
communication sessions are explicit data: create a schedule in
`.moontown/civic/pattern-schedules.json` and create a matching template at this
path. New domains should arrive as data and skills, not new MoonBit branches.

One-off runs can use any template path. A successful `pattern-template` run also
copies the scenario into `.moontown/civic/pattern-scenarios/` and upserts a
30-minute recurring schedule, so the same pattern can continue under the daemon:

```bash
moon run src/cmd/main -- civic protocols pattern-template assets/templates/civic-salons/robotics-mini-salon.json
moon run src/cmd/main -- civic protocols pattern-template assets/templates/civic-salons/embodied-robotics-social-square.json
```

To install recurring Wenyu civic patterns without immediately running every
MoonClaw reducer, use the manifest installer:

```bash
moon run src/cmd/main -- civic protocols pattern-manifest assets/templates/civic-patterns/wenyu-civic-patterns.json
```

The manifest copies each scenario into `.moontown/civic/pattern-scenarios/` and
creates staggered 30-minute schedules. It does not materialize MoonBook outputs
until the daemon or `civic protocols schedules tick` reaches a due session.

## Template Contract

Required high-level fields:

- `id`: stable salon id; for recurring jobs this must match the schedule id.
- `communication_pattern_id`: one of the pattern ids from
  `civic communication patterns`, for example `triage-desk`,
  `match-market`, or `story-forge`.
- `communication_pattern_label`: human-facing label for that pattern.
- `building_id`: target civic building, for example `social-square`.
- `building_book_id`: central building MoonBook, for example
  `wenyu-social-square`.
- `domain_label`, `topic`, `cadence`: projection and skill context.
- `skill_name`, `skill_description`, `skill_rules`: generated `SKILL.md`
  behavior contract.
- `quality_rules`: round quality bar shown in contracts and projections.
- `protocol_channel`, `reduction_kind`, `output_channel`: protocol envelope
  labels.
- `review_gate`, `review_owner`, `review_reason`: review routing.
- `backlog_path`, `synthesis_path`, `metrics_path`, `review_path`,
  `returned_ideas_path`, `participant_contract_path`: MoonBook output paths.
- `participants`: internal participant workspaces and their current
  perspectives.
- `ideas`: fixture examples only. Production rounds must use MoonClaw output
  from `raw/bootstrap/civic-communication-results.json`; stale projection refreshes use
  the last persisted reducer output.

The key extensibility rule is that future domains and civic services should
change these fields, not add `if domain == ...` branches to Moontown.

Participant workspaces are internal salon workspaces by default. The durable
surface book is the building book, such as `wenyu-social-square`; participant
workspaces may keep return-home pages for audit and follow-up, but they are not
promoted into the public MoonBook catalog unless a future product decision makes
that participant workspace a first-class standing book.

Generated projections make that boundary explicit. Building books emit
`projection_scope: public`; participant workspaces emit
`projection_scope: internal` plus tags such as `participant-workspace`. The
Rabbita bridge filters by those metadata fields and by
`.moontown/book-projection-policy.json`, not by domain-specific MoonBit code.

## Building Protocol Resolution

Salon templates are extensible at the building level:

- If `building_id` matches an existing Wenyu civic building, Moontown uses the
  registered protocol definition.
- If `building_id` is not registered, Moontown creates a generic
  exchange-reduce-distribute protocol from the scenario fields.
- The fallback protocol uses `building_book_id` as the public MoonBook surface,
  `protocol_channel` as the inbox, `output_channel` as the outbox, and
  `review_gate` as the required review boundary.

This keeps the MoonBit layer responsible for protocol envelopes, ledgers, and
idempotent materialization, while the scenario `SKILL.md` controls domain
reasoning and reducer quality.

## Adding A New Domain

1. Copy a close template from `assets/templates/civic-patterns/` or
   `assets/templates/civic-salons/robotics-mini-salon.json`.
2. Rename `id`, `title`, `domain_label`, `topic`, and all output paths.
3. Add participant workspaces that represent independent perspectives, not
   duplicate researchers.
4. Write `skill_rules` that tell the agents how to behave in the building.
5. Add `ideas` only if you need deterministic fixture/smoke data. Do not rely
   on them for production reduction; the generated skill should guide
   MoonClaw to produce round-specific ideas.
6. For recurring use, add or edit `.moontown/civic/pattern-schedules.json` so the schedule
   id matches the template file name.
7. Run `moon run src/cmd/main -- civic protocols schedules tick` or wait for the
   daemon.

## Reducer Modes

- `MoonClawReducer` is the default production path. It writes a reducer
  workspace, generated `SKILL.md`, participant JSON, reducer contract, and
  `moonclaw.jobs.json`; imports a MoonClaw proposal; then requires a valid,
  non-empty `CivicCommunicationIdea` JSON output before materialization.
- `PersistedReducer` is used only for stale projection refresh. It replays the
  latest persisted `raw/bootstrap/civic-communication-results.json` and never falls back
  to template ideas.
- `FixtureReducer` is reserved for tests and explicit smoke demos. It is the
  only mode allowed to consume template `ideas`.
- Template quality matters. Bad participant perspectives or vague skill rules
  will produce weak salon rounds even if the runtime is correct.

## Default Wenyu Pattern Set

The default set is data, not code:

| Building | Pattern | Template |
| --- | --- | --- |
| Town Shell | `triage-desk` | `town-shell-triage-desk.json` |
| Resident Twin Homes | `review-council` | `resident-twins-review-council.json` |
| Policy Hall | `triage-desk` | `policy-hall-triage-desk.json` |
| Contest Express | `review-council` | `contest-express-review-council.json` |
| Social Square | `match-market` | `social-square-match-market.json` |
| Talent Avenue | `match-market` | `talent-avenue-match-market.json` |
| Vitality Tower | `signal-watch` | `vitality-dashboard-signal-watch.json` |
| AI Garden | `learning-cohort` | `ai-garden-learning-cohort.json` |
| Physical Bridge | `incident-bridge` | `physical-bridge-incident-bridge.json` |
| Valley Market | `match-market` | `valley-market-match-market.json` |
| Broadcast Tower | `story-forge` | `broadcast-tower-story-forge.json` |
