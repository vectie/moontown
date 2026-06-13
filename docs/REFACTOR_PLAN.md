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

civic communication-pattern runtime
  reusable exchange/review/watch/match/triage patterns and round audit ledgers

src/ui/rabbita-town
  operator console, viewport, module interiors, protocol projection
```

The dependency direction should stay acyclic:

```text
cmd/main -> moontown root facade
moontown root -> scheduler, civic, storage, moonbook, moonclaw adapters
civic protocol/runtime -> civic definitions + MoonBook storage APIs
town_runtime daemon tick orchestration -> daemon_runtime tick/process/log infrastructure
src/ui/rabbita-town -> projection JSON only
```

The UI should not own civic truth. It should render runtime projections emitted
by Moontown and MoonBook.

## Current Structural Debt

- The former `civic_protocol_runtime.mbt` monolith has been split into
  registry/bootstrap, ledger store, status runtime, markdown helpers, Social
  Square fixture, and generic communication-pattern scenario runtime files.
  The research salon code is no longer meant to grow one MoonBit path per
  domain; domains should arrive as templates plus skill rules.
- `research-salon` is now one pattern in the civic communication-pattern
  registry, alongside `signal-watch`, `triage-desk`, `review-council`,
  `match-market`, `learning-cohort`, `story-forge`, and `incident-bridge`.
- The former salon-specific daemon surface has been split into generic
  communication schedule types, paths, schedule persistence, reconciliation,
  and runner files.
- `runtime_status.mbt` now invokes a generic daemon scheduled-job dispatcher,
  but the dispatcher still lives in the root package pending a package split.
- `src/ui/rabbita-town/main/main.mbt` has been split into focused frontend
  files, but some policy/view clusters still need extraction so UI code remains
  a projection layer instead of becoming a civic-policy layer.
- The communication-pattern reducer boundary now exists. Production rounds use MoonClaw to
  emit `CivicCommunicationIdea` JSON from generated skills and participant context;
  deterministic template ideas are isolated behind explicit fixture mode.

## Refactor Stages

### Stage 1: Behavior-Preserving Runtime Split

Status: implemented in this refactor pass.

Goals:

- split the civic communication-pattern daemon into focused files
- add a generic daemon scheduled-job dispatcher
- route communication-pattern execution through scenario definitions instead
  of matching raw schedule ids in the runner
- keep existing CLI commands and generated files stable
- keep `moon test`, `moon check`, `moon fmt`, and `moon info` passing

Acceptance:

- `civic protocols schedules tick` still advances or refreshes the communication-pattern session
- daemon tick still records civic communication-pattern events when a session actually runs
- the Social Square viewport still reads the latest round from projections
- targeted communication-pattern and daemon scheduled-job tests pass

### Stage 2: Protocol Runtime File Split

Status: implemented for root-package file structure.

Goals:

- keep repository root free of implementation source files
- keep `src/` root as a facade-only package with implementation moved into
  named packages
- split the protocol runtime into protocol registry/bootstrap,
  protocol ledger store, protocol status projection, Social Square proof
  fixture, generic civic communication scenario records, scenario runtime, and
  MoonBook projection writer
- keep fixtures explicitly named as fixtures so they are not confused with the
  final MoonClaw reducer architecture
- make domain-specific communication patterns data-driven through scenario templates instead
  of adding new MoonBit branches

Acceptance:

- `./scripts/audit-source-layout.sh` passes
- repo root has no implementation-like MoonBit/JS/TS/CSS source files
- `src/` root contains only `facade.mbt`, `moon.pkg`, and
  `pkg.generated.mbti`
- no file in the root package exceeds roughly 1,200 lines unless there is a
  clear reason
- protocol store tests cover append/read/latest/count behavior
- fixture tests remain separate from runtime tests
- a non-robotics scenario template can seed internal participant workspaces and
  building projection without changing the runner

Current files:

- `civic_protocol_registry_runtime.mbt`: Wenyu protocol registry bootstrap.
- `civic_protocol_store.mbt`: JSONL ledger paths, writes, counts, latest
  record reads.
- `civic_protocol_status_runtime.mbt`: protocol portfolio inspection and
  status projection.
- `civic_protocol_markdown.mbt`: protocol contract markdown rendering.
- `civic_protocol_social_square_fixture.mbt`: Social Square proof-slice seed.
- `civic/communication_scenario_types.mbt`: generic communication scenario, participant, idea,
  metric, and home-return record shapes.
- `civic_communication_scenario_runtime.mbt`: generic scenario template loader,
  MoonBook workspace writes, protocol ledger slice, metrics, and generated
  projection.
- `assets/templates/civic-salons/robotics-mini-salon.json`: copyable scenario
  template proving new domains can be configured without MoonBit code.
- `civic/communication_pattern_registry.mbt`: reusable pattern registry and
  Wenyu civic service-to-pattern mapping.
- `civic/communication_scenario_types.mbt`: reusable communication scenario, participant, idea,
  metric, reduction-mode, and home-return DTOs.
- `civic/communication_scenario_policy.mbt`: reusable scenario pattern resolution,
  pattern-label fallback, building-protocol derivation, and salon protocol
  notes.
- `civic/skill_text.mbt`: reusable generic civic service skill, module skill,
  salon participant skill, and salon reducer skill/contract/input text.
- `civic/workspace_text.mbt`: reusable civic workspace index, service
  contract, building protocol contract, schema/wiki/review seed pages, and
  service/exchange/history ledger text.
- `civic/communication_metrics.mbt`: reusable structural effectiveness and
  return-home metric calculation for communication-pattern rounds.
- `civic/communication_schedule_types.mbt` and `civic/communication_schedule_policy.mbt`:
  reusable schedule/round-record vocabulary and pure transition helpers.
- `civic/status_labels.mbt`: reusable service/protocol status labels, buckets,
  readiness checks, result-proven checks, and health-note semantics.
- `civic/service_reconcile_policy.mbt`: reusable civic service reconciliation
  decision/accounting/current-result/reconcilable-work/result-contract wording
  for converting protocol ledgers into MoonBook service results.
- `civic/protocol_contract_text.mbt`: reusable building protocol contract
  Markdown text for protocol ledger directories.
- `civic/protocol_portfolio.mbt`: reusable protocol portfolio bucket
  predicates, count aggregation, and compact Markdown row rendering.
- `civic/protocol_snapshot.mbt`: reusable snapshot construction from protocol
  definition plus observed ledger counts/summaries.
- `civic_communication_patterns.mbt`: root compatibility facade for rendering
  and existing CLI/tests; it must stay thin.

Current extension rule:

- Wenyu-registered buildings still use the Wenyu civic protocol registry.
- A salon scenario may also define a new building with only
  `building_id`, `building_book_id`, channels, review gate, skill rules, and
  participants.
- If no registry protocol exists, Moontown synthesizes a generic
  exchange-reduce-distribute building protocol from the scenario instead of
  skipping materialization or requiring a MoonBit branch.
- Participant workspaces are internal by projection metadata, not by
  hardcoded frontend id matching.

### Stage 3: Package Split

Goals:

- move civic runtime files into focused packages once file split is stable:
  `civic/workspace`, `civic/protocol_runtime`, and `civic/communication`
- leave root-package wrapper functions for CLI compatibility
- reduce root `pkg.generated.mbti` to high-level public facade APIs
- keep reusable civic communication patterns in `civic/`; root may only adapt
  them into runtime scenario artifacts
- keep reusable scenario DTOs in `civic/`; root may keep aliases during the
  package split, but should not define new scenario record shapes
- keep reusable scenario pattern/protocol derivation in `civic/`; root may
  load templates and persist pages, but should not manually build those
  protocol contracts
- keep civic skill text contracts in `civic/`; root may write `SKILL.md` files
  and reducer contract files, but should not assemble civic service/reducer
  skill text locally
- keep civic workspace seed text in `civic/`; root may select paths and write
  files, but should not assemble service contracts, building protocol
  contracts, schema/wiki/review seeds, or civic ledger templates locally
- keep communication-pattern metric semantics in `civic/`; root may persist,
  render, or dispatch against metrics but should not compute them independently
- keep execute/tend/control loop-lane semantics in `policy/`; downstream
  packages may read serialized lane strings, but `policy/` owns parsing,
  normalization, and lane-based skill selection
- keep default policy output surface/path constants in `policy/`; downstream
  packages may expose compatibility helpers, but they should delegate to policy
  defaults instead of redefining generated-site paths locally
- keep internal-distance semantics in `policy/`; downstream packages may render
  information/recognition/decisiveness plans, but `policy/` owns the mapping
  from execute skills, tend skills, quality gates, and output contracts into
  that growth-vector view
- keep raw MoonClaw run-status normalization in `planbook_policy/`; runtime
  packages may downgrade a completed run when required repair evidence is
  missing, but policy status normalization must not conflate `Succeeded` with
  evidence failure
- keep schedule DTOs and pure transitions in `civic/`; root may store,
  claim/retry, and run schedules but should not define schedule vocabulary
- keep civic service/protocol status semantics in `civic/`; root may inspect
  files and render status, but should not define independent status buckets or
  readiness checks
- keep building-protocol portfolio semantics in `civic/`; root may inspect
  ledgers and write status files, but should not define bucket predicates,
  aggregate counts, or row formatting
- keep building-protocol contract text in `civic/`; root may write contract
  files beside ledgers, but should not assemble reusable protocol contract
  Markdown locally
- keep building-protocol snapshot construction in `civic/`; root may count
  ledger records and read latest summaries, but should not assemble
  `BuildingProtocolSnapshot` records directly
- keep civic service reconciliation policy in `civic/`; root may build and
  persist MoonBook results from observed health, but should not define decision
  vocabulary, accounting, current-result checks, reconcilable-work gates, or
  result-contract wording
- keep editor pipeline DTOs, contract ids, skill policy, stage/status policy,
  selected-style lookup, selected-feature readiness gates, module-placement
  DTOs, movement-loop record policy, placement-diff record policy,
  terrain-layer/reason record policy, canonical Markdown renderer, and style
  metadata in `editor_pipeline/`; root may inspect source/runtime state,
  materialize PlanBook files, dispatch packets, compute evidence paths, load
  module JSON, convert config entries into package DTOs, and read results, but
  should not define editor feature-selection contract ids, feature-rater skill
  text, stage readiness decisions, status Markdown sections,
  selected-style policy, selected-feature readiness gates,
  module-placement policy, terrain-labeling policy, or reusable style metadata
  locally, and should not keep root-local compatibility shims over those
  package APIs
- keep PlanBook self-repair DTOs, validation command policy, repair result
  contracts, ACP patch-receipt validation, repair-decision semantics, and
  MoonClaw run-status bucket policy in `planbook_policy/`; the same package
  owns pure repair layout paths such as repair context/result filenames,
  packet path derivation, skill/plan page paths, target pages, and MoonClaw
  repair index paths, pure repair request task-rule wording, and generated
  `planbook-repair` skill text; root may
  resolve source roots, materialize repair files, dispatch MoonClaw/ACP packets,
  read run outputs, and reconcile filesystem evidence, but should not duplicate
  validation commands, receipt fields, repair paths, repair request rules,
  generated repair skill text, repair decision vocabulary, or lifecycle status
  mapping locally
- keep live-autonomy spine DTOs, journal/probe DTOs, active worker/execution
  metric policy, transient-infrastructure-debt recognition, autonomy tick
  calculation, aggregate metric-count DTO/assembly, stable-waiting blocker
  policy, waiting-streak progression, next-action wording, status
  classification, canonical live-autonomy path derivation, and canonical
  live-status Markdown rendering in
  `live_autonomy_policy/`; root may refresh snapshots, persist journals and
  digests, inspect health, read watcher ledgers, derive latest watcher
  decisions, and sync PlanBook counts, but should not redefine "live", stable
  waiting, transient debt, metric-count shape, live-autonomy file naming, or the
  operator-facing autonomy surface
- keep runtime-status DTOs, empty-status shape, effective execution
  de-duplication, lifecycle ranking, active/review execution-status set
  membership, standing-goal runtime counts, and stable metric-summary/report
  rendering language in `runtime_status_policy/`; root and live-autonomy code
  may load snapshots, daemon state, watcher records, standing goals, template
  request inboxes, and root-only daemon health strings, but should not define
  duplicate runtime status buckets, active/review status lists, standing-goal
  runtime counts, summary wording, or operator report formatting
- keep health anomaly detection and exact-title anomaly counts in `health/`;
  runtime-status and live-autonomy code may consume `HealthReport` values, but
  should not duplicate execution-failed, execution-stale, worker-health, or
  future anomaly title counting semantics
- keep daemon-runtime state/health DTOs, status-mode classification, heartbeat
  staleness rules, durable-worker/supervisor predicates, doctor/start actions,
  worker-spawn predicates, health labels, health summary field ordering,
  canonical daemon path derivation, and pure daemon transition builders in
  `daemon_runtime_policy/`;
  root may supply storage defaults, inspect PIDs, spawn/stop processes, persist
  runtime files, manage PID/stop/restart files, and integrate launchd, but
  should not define duplicate daemon runtime vocabulary, file naming,
  transition semantics, or health interpretation
- keep App ToolBook install/status DTOs, default identity, path/template-copy
  policy, catalog name/tags/skills, catalog-identity-aware config construction,
  config and manifest constructors, readiness gates, history Markdown, site
  index HTML, generated tool HTML, status Markdown, bootstrap/install summary
  wording, and standing-goal construction/list semantics in `app_tool_book/`;
  root may load operator config JSON, resolve file overrides, inspect
  filesystem/catalog/goal state, copy templates, write the package-rendered
  files, adapt package identity into MoonBook catalog entries, and persist
  standing goals, but should not define ToolBook schemas, catalog identity,
  page/status renderers, bootstrap/install summary wording, standing-goal
  semantics, path lists, or readiness policy locally, and should not keep
  root-local default/config/manifest shims
- keep Cookbook DTOs, artifact summary accounting, required-missing drift
  semantics, and operator-facing Cookbook status Markdown in `cookbook/`; root
  may discover artifact existence, register/catalog the MoonBook workspace,
  write generated pages, and expose CLI command facades, but should not define
  duplicate docs/definition/runtime-state counters or Cookbook status wording
- keep generic standing-watch task construction, task kind, prompt/id contract,
  compact id segment formatting, target pages, strict accounting markers,
  marker parsing, MoonBook history block parsing, provider-decision collapse
  policy, material-delta metrics, execution-summary classification,
  effective watcher-record decision selection, terminal-record preference
  ordering, and repair-mode appendix composition in `standing_watch_policy/`;
  root may schedule, route, persist, read/write book history files, append
  watcher ledgers, and reconcile watcher cycles, but should not own the
  reusable standing-watch contract, parser, history collapse semantics,
  accounting policy, no-change/update/deferred/review inference, or terminal
  watcher-record selection
- keep reusable transient external dependency classification in
  `runtime_error_policy/`; root recovery, standing-watch, and PlanBook code may
  consume it, but should not duplicate provider-infrastructure string
  predicates locally
- keep book-template install-success markers and lifecycle classification in
  `book_templates/`; template installers may emit the package-owned success
  marker, but request processing should not infer installed/failed state from
  human-readable PDF/AppTool summary prose or carry raw pending/retry/installed/
  failed status decisions outside package-owned predicates; request-status
  readiness/summary construction and request inbox Markdown rendering are
  package-owned too; registry descriptor and registry-file manifest schemas,
  registry descriptor check-path expansion, descriptor lookup, registry
  readiness, and registry Markdown rendering are package-owned as well;
  request-event identity/DTO construction, event JSONL text normalization/
  append format, event-line parsing, latest-event fallback, unique request-id
  extraction, post-install request-state transitions, terminal-event reconcile
  gates, process-result records, processed/reconciled outcome aggregation,
  empty request-status construction, canonical request/event filenames, path
  derivation, and summary wording are package-owned, with root event files and
  concrete request execution remaining IO/orchestration only; root must not
  keep default path shim functions for book-template registry, request inbox, or
  request-event paths;
  unknown-template and registered-without-installer outcome wording is
  package-owned; concrete template runtime dispatch, request processing,
  request reconciliation, request status rendering, registry rendering, and
  installer dispatch are now package-owned too, while root keeps only
  CLI-compatible wrapper functions
- keep App ToolBook bootstrap/install/status/workspace behavior in
  `app_tool_book/`; root may expose wrappers for existing commands, but should
  not carry generated-tool book runtime implementation
- keep PDF Evidence Watch bootstrap/install/status/workspace behavior in
  `pdf_evidence_watch/`; root may coordinate archive lifecycle events because
  archiving crosses book-template request logs, standing goals, and catalog
  tags
- keep visual projection DTOs, phase semantics, routing labels, building/module
  activity summaries, grid placement, and persistence in `visual_projection/`;
  root may expose compatibility wrappers, but it should not carry visual
  semantics
- keep generic file, JSON, Markdown, HTML, text-label, and runtime-config JSON
  helper implementation in `support/`; root may expose private compatibility
  wrappers, but support code should not remain as many unrelated root files
- keep research readiness and quality-gate semantics in `research_quality/`;
  root may still own mayor/execution mutation for failed gates, but it should
  not own source-depth, report-length, wiki-materialization, or marketing-site
  specificity rules
- keep Wenyu course-book bootstrap, generated course content, course-builder
  skill text, UI-state JSON, and generated course site projection in
  `course_book/`; root should expose only command-compatible wrappers
- keep Moontown-side MoonClaw metadata, run-result lookup, and job-store
  compaction helpers in `moonclaw_runtime/`; root should keep only wrappers
  needed by existing commands and runtime callers

Acceptance:

- lower-level packages do not import the root `vectie/moontown` package
- root package imports runtime packages and exposes stable CLI facade functions
- public API shrink is intentional and reviewed through `moon info`

### Stage 4: Skill-Driven Reducers

Status: first production boundary implemented for civic communication patterns.

Goals:

- replace deterministic fixture output reduction with MoonClaw role packets
- keep the same building protocol envelope and ledgers
- make each civic building choose reductions through generated `SKILL.md`
  plus scenario template context

Acceptance:

- Social Square can run any valid communication scenario through a skill-driven
  MoonClaw reducer and produce reviewable outputs
- a new communication-pattern building can be added by scenario template plus schedule entry
  without changing Moontown MoonBit code
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

Status: partially implemented.

Goals:

- finish extracting remaining frontend clusters into focused files: bootstrap
  sources and parsers, operator console, Wenyu tile map, module
  building/interior renderer, protocol projection panels, standing-watch
  messenger, and small projection-mapping policy helpers
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
