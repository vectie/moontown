# Moontown Refactor Plan

Last updated: 2026-05-27

This plan aligns the implementation with the intended product model:
Moontown is the always-on mayor/control plane, MoonBook owns durable
workspaces, MoonClaw owns skill-driven execution, and Wenyu civic buildings are
protocol places where agents and information aggregate, exchange, reduce,
review, and distribute.

## Target Boundaries

```text
moontown root package
  public CLI facade, mayor loop, daemon runtime, persisted town checkpoint

scheduler
  pure tick planning, standing-goal due calculation, scheduled job metadata

civic
  civic service definitions and building protocol schemas

civic workspace runtime
  MoonBook workspace bootstrap, schemas, review queues, projections

civic protocol runtime
  building inbox/contribution/reduction/outbox/review ledgers

civic salon runtime
  recurring multi-book exchange schedules and salon round audit ledgers

ui/rabbita-town
  operator console, viewport, module interiors, protocol projection
```

The dependency direction should stay acyclic:

```text
cmd/main -> moontown root facade
moontown root -> scheduler, civic, storage, moonbook, moonclaw adapters
civic protocol/runtime -> civic definitions + MoonBook storage APIs
ui/rabbita-town -> projection JSON only
```

The UI should not own civic truth. It should render runtime projections emitted
by Moontown and MoonBook.

## Current Structural Debt

- The former `civic_protocol_runtime.mbt` monolith has been split into
  registry/bootstrap, ledger store, status runtime, markdown helpers, Social
  Square fixture, and generic civic salon scenario runtime files. The salon
  code is no longer meant to grow one MoonBit path per domain; domains should
  arrive as `CivicSalonScenario` templates plus skill rules.
- The former `civic_salon_daemon.mbt` has been split into schedule types,
  paths, schedule persistence, reconciliation, and runner files.
- `runtime_status.mbt` now invokes a generic daemon scheduled-job dispatcher,
  but the dispatcher still lives in the root package pending a package split.
- `ui/rabbita-town/main/main.mbt` is a monolithic 10k-line frontend package.
- The salon reducer boundary now exists. Production rounds use MoonClaw to
  emit `CivicSalonIdea` JSON from generated skills and participant context;
  deterministic template ideas are isolated behind explicit fixture mode.

## Refactor Stages

### Stage 1: Behavior-Preserving Runtime Split

Status: implemented in this refactor pass.

Goals:

- split the civic salon daemon into focused files
- add a generic daemon scheduled-job dispatcher
- route salon execution through salon definitions and scenario kinds instead
  of matching raw schedule ids in the runner
- keep existing CLI commands and generated files stable
- keep `moon test`, `moon check`, `moon fmt`, and `moon info` passing

Acceptance:

- `civic protocols salons tick` still advances or refreshes the salon
- daemon tick still records civic salon events when a salon actually runs
- the Social Square viewport still reads the latest round from projections
- targeted salon and daemon scheduled-job tests pass

### Stage 2: Protocol Runtime File Split

Status: implemented for root-package file structure.

Goals:

- split the protocol runtime into protocol registry/bootstrap,
  protocol ledger store, protocol status projection, Social Square proof
  fixture, generic civic salon scenario records, scenario runtime, and
  MoonBook projection writer
- keep fixtures explicitly named as fixtures so they are not confused with the
  final MoonClaw reducer architecture
- make domain-specific salons data-driven through scenario templates instead
  of adding new MoonBit branches

Acceptance:

- no file in the root package exceeds roughly 1,200 lines unless there is a
  clear reason
- protocol store tests cover append/read/latest/count behavior
- fixture tests remain separate from runtime tests
- a non-robotics scenario template can seed participant MoonBooks and building
  projection without changing the runner

Current files:

- `civic_protocol_registry_runtime.mbt`: Wenyu protocol registry bootstrap.
- `civic_protocol_store.mbt`: JSONL ledger paths, writes, counts, latest
  record reads.
- `civic_protocol_status_runtime.mbt`: protocol portfolio inspection and
  status projection.
- `civic_protocol_markdown.mbt`: protocol contract markdown rendering.
- `civic_protocol_social_square_fixture.mbt`: Social Square proof-slice seed.
- `civic_salon_scenario_types.mbt`: generic salon scenario, participant, idea,
  metric, and home-return record shapes.
- `civic_salon_scenario_runtime.mbt`: generic scenario template loader,
  MoonBook workspace writes, protocol ledger slice, metrics, and generated
  projection.
- `templates/civic-salons/robotics-mini-salon.json`: copyable scenario
  template proving new domains can be configured without MoonBit code.

### Stage 3: Package Split

Goals:

- move civic runtime files into focused packages once file split is stable:
  `civic/workspace`, `civic/protocol_runtime`, and `civic/salon`
- leave root-package wrapper functions for CLI compatibility
- reduce root `pkg.generated.mbti` to high-level public facade APIs

Acceptance:

- lower-level packages do not import the root `vectie/moontown` package
- root package imports runtime packages and exposes stable CLI facade functions
- public API shrink is intentional and reviewed through `moon info`

### Stage 4: Skill-Driven Reducers

Status: first production boundary implemented for civic salons.

Goals:

- replace deterministic salon idea reduction with MoonClaw role packets
- keep the same building protocol envelope and ledgers
- make each civic building choose reductions through generated `SKILL.md`
  plus scenario template context

Acceptance:

- Social Square can run any valid salon scenario through a skill-driven
  MoonClaw reducer and produce reviewable outputs
- deterministic fixture mode is retained only for tests and explicit smoke
  demos
- stale projection refresh replays persisted reducer output and never consumes
  template ideas
- invalid or missing reducer output blocks and retries the round instead of
  falling back to examples
- no building-specific reasoning is hardcoded in the daemon
- adding a new domain means adding a scenario template and schedule entry, not
  writing a new MoonBit branch

### Stage 5: Frontend Modularization

Goals:

- split `ui/rabbita-town/main/main.mbt` into focused frontend files: bootstrap
  sources and parsers, operator console, Wenyu tile map, module
  building/interior renderer, protocol projection panels, and standing-watch
  messenger
- keep the frontend rendering projection JSON only

Acceptance:

- the viewport has no direct civic business logic beyond projection mapping
- module interiors render protocol state from `civic-status.json`
- frontend smoke checks validate view, editor, and output modes

## Non-Goals

- Do not move single-agent deep editing into Moontown. That belongs in
  Moondesk.
- Do not turn every civic building into a generic research book.
- Do not hardcode civic reasoning in Moontown. Moontown owns protocol
  envelopes, routing, ledgers, review gates, and projection; MoonClaw chooses
  building-native reductions from skills.
