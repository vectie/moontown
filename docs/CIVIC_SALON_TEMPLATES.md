# Civic Salon Scenario Templates

Last updated: 2026-05-27

The civic salon runtime is template-driven. A domain should not require a new
MoonBit runner. A building gets a scenario template, the template names its
participant MoonBooks, skill rules, protocol channels, output paths, review
gate, and optional fixture idea examples, and Moontown runs the same
exchange-reduce-distribute envelope for every scenario.

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
`raw/bootstrap/civic-salon-ideas.json` using the same `CivicSalonIdea`
contract that Moontown materializes into MoonBook pages, protocol ledgers,
reviews, and UI projections. Template ideas are no longer production reducer
input.

## Runtime Files

- [civic_salon_scenario_types.mbt](/Users/kq/Workspace/moontown/civic_salon_scenario_types.mbt)
  defines `CivicSalonScenario`, participant books, ideas, metrics, and
  home-return records.
- [civic_salon_scenario_runtime.mbt](/Users/kq/Workspace/moontown/civic_salon_scenario_runtime.mbt)
  loads scenario templates, materializes MoonClaw reducer output into
  participant MoonBooks, runs the protocol ledger slice, and writes the
  building projection.
- [civic_salon_reducer.mbt](/Users/kq/Workspace/moontown/civic_salon_reducer.mbt)
  owns the reducer modes: `MoonClawReducer` for production,
  `PersistedReducer` for stale projection refresh, and `FixtureReducer` for
  deterministic tests/smoke demos.
- [civic_salon_runner.mbt](/Users/kq/Workspace/moontown/civic_salon_runner.mbt)
  runs due schedules by loading the matching scenario template.
- [civic_salon_reconcile.mbt](/Users/kq/Workspace/moontown/civic_salon_reconcile.mbt)
  refreshes stale projections from the same scenario template.
- [templates/civic-salons/robotics-mini-salon.json](/Users/kq/Workspace/moontown/templates/civic-salons/robotics-mini-salon.json)
  is a small copyable example.

## Where Templates Live

Recurring schedules load templates from:

```text
.moontown/civic/salon-scenarios/<salon-id>.json
```

No scenario is auto-seeded. Recurring salons are explicit: create a schedule in
`.moontown/civic/salons.json` and create a matching template at this path. New
domains should arrive as data and skills, not new MoonBit branches.

One-off runs can use any template path:

```bash
moon run cmd/main -- civic protocols salon-template templates/civic-salons/robotics-mini-salon.json
```

## Template Contract

Required high-level fields:

- `id`: stable salon id; for recurring jobs this must match the schedule id.
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
- `participants`: participant MoonBooks and their current perspectives.
- `ideas`: fixture examples only. Production rounds must use MoonClaw output
  from `raw/bootstrap/civic-salon-ideas.json`; stale projection refreshes use
  the last persisted reducer output.

The key extensibility rule is that future domains should change these fields,
not add `if domain == ...` branches to Moontown.

## Adding A New Domain

1. Copy `templates/civic-salons/robotics-mini-salon.json`.
2. Rename `id`, `title`, `domain_label`, `topic`, and all output paths.
3. Add participant books that represent independent perspectives, not duplicate
   researchers.
4. Write `skill_rules` that tell the agents how to behave in the building.
5. Add `ideas` only if you need deterministic fixture/smoke data. Do not rely
   on them for production reduction; the generated skill should guide
   MoonClaw to produce round-specific ideas.
6. For recurring use, add or edit `.moontown/civic/salons.json` so the schedule
   id matches the template file name.
7. Run `moon run cmd/main -- civic protocols salons tick` or wait for the
   daemon.

## Reducer Modes

- `MoonClawReducer` is the default production path. It writes a reducer
  workspace, generated `SKILL.md`, participant JSON, reducer contract, and
  `moonclaw.jobs.json`; imports a MoonClaw proposal; then requires a valid,
  non-empty `CivicSalonIdea` JSON output before materialization.
- `PersistedReducer` is used only for stale projection refresh. It replays the
  latest persisted `raw/bootstrap/civic-salon-ideas.json` and never falls back
  to template ideas.
- `FixtureReducer` is reserved for tests and explicit smoke demos. It is the
  only mode allowed to consume template `ideas`.
- Template quality matters. Bad participant perspectives or vague skill rules
  will produce weak salon rounds even if the runtime is correct.
