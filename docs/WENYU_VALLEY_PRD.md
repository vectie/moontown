# Wenyu Valley Product Requirements

This document turns the Wenyu Valley vision into a programmable product plan for
the `moontown -> moonbook -> moonclaw` system.

The goal is not to make `moontown` a standalone game. The goal is to build an
always-on AI town where `moontown` supervises, `moonbook` remembers, and
`moonclaw` executes.

## 1. Product Positioning

### One-Line Product

Wenyu Valley is a pixel-art AI innovation town for one-person companies, where
residents, civic services, memory, agents, quests, and offline bridges are
operated by an always-on mayor loop.

### Target Users

- OPC founders evaluating whether to settle in the district.
- Existing residents needing policy help, events, social matches, talent
  exposure, and AI tool education.
- District operators monitoring settlement, retention, service quality, and
  community health.
- Visitors, media, and VIP tour audiences who need a clear, emotionally
  memorable view of the district.

### Core Promise

The town should make an innovation district playable, livable, and growable:

- Playable: civic services are expressed as quests, places, agents, and visible
  progress.
- Livable: residents have persistent digital twins with memory and plans.
- Growable: the system can run 24/7, recover from failures, and improve its
  knowledge through MoonBook and MoonClaw.

### Current Delivery Distance

The current implementation is a real prototype, not yet a complete civic
operating system. The latest scorecard is maintained in
[WENYU_TOWN_STATUS.md](/Users/kq/Workspace/moontown/docs/WENYU_TOWN_STATUS.md).

In product terms:

- the visual town shell is usable
- the module add-on architecture has started
- the daemon/watch seam exists locally
- research workflows can persist through MoonBook/MoonClaw
- Wenyu civic modules now have a MoonTown-side service registry and bootstrap
  command that creates seeded MoonBook workspaces, schemas, review queues,
  projections, and MoonClaw skill contracts
- civic services still need repeated end-to-end module workflows before the
  town can be called fully functioning

## 2. Responsibility Split

### MoonTown

MoonTown is the always-on town control plane.

MoonTown owns:

- Mayor supervision.
- Town loop and daemon checkpoints.
- Multi-book routing.
- Global health, recovery, and escalation.
- Cross-book synthesis.
- Operator and pixel-town UI.
- Runtime projection contract consumed by the browser.
- The Wenyu civic protocol registry and temporary local bootstrap bridge for
  creating civic support workspaces until MoonBook owns native templates.

MoonTown must not own:

- Durable civic-domain wiki content.
- Raw long-running execution tools.
- Book-local memory promotion decisions.

### MoonBook

MoonBook is the durable workspace and memory layer.

MoonBook owns:

- Durable support workspaces for civic protocols when the building needs
  accepted records, ledgers, review queues, private memory, or projections.
- Resident memory streams.
- Domain wiki pages.
- Quest records and review queues.
- Talent graph and social matching records.
- Generated website projections for public or operator surfaces.
- Persistence decisions for MoonClaw result packets.
- Native civic workspace templates once the bootstrap contract stabilizes.

MoonBook must expose:

- Book summary.
- Coverage/readiness.
- Active quests.
- Memory snapshots.
- Generated site paths.
- Review gaps.
- Projection JSON for MoonTown UI.

### MoonClaw

MoonClaw is the agent execution substrate.

MoonClaw owns:

- Mayor, keeper, and worker role runtimes.
- Tool-heavy execution.
- Research, browsing, reading, synthesis, and action attempts.
- Result packets.
- Memory candidates.
- Tool journals and execution logs.
- Role-specific civic module execution through bounded skill/output contracts.

MoonClaw must not directly own durable town memory. It emits candidates and
artifacts; MoonBook decides what is persisted.

## 3. Product Modules

### 3.1 Town Shell

Purpose:

Render Wenyu Valley as a living town, not an admin dashboard.

Required features:

- Pixel-art overview map.
- North, Central, and South district zones.
- City Hall for Mayor.
- Civic buildings whose protocols may bind to MoonBook support workspaces.
- Worker yard for MoonClaw agents.
- Anomaly/recovery area.
- Day-night, season, and weather state.
- Resident avatars and worker avatars.
- Operator controls for pause, step, recovery, and inspection.

MoonTown implementation:

- Extend `TownState` projection with `TownRuntimeProjection`.
- Add season, weather, day phase, and civic counters.
- Render Rabbita UI from projection data rather than synthetic local state.

MoonBook implementation:

- Provide per-book projection fragments for each civic module.

MoonClaw implementation:

- Emit status and activity events that make workers visibly move between town
  places.

Acceptance criteria:

- The UI shows a complete town scene at first load.
- No broken assets.
- No false degradation warnings during normal lifecycle states.
- Operator can inspect a resident, worker, place, quest, and module.
- `moon run src/cmd/main -- civic bootstrap` can create the civic protocol support
  workspaces required by the viewport bindings.

Implementation note:

- Civic functions should be implemented as configurable map modules, not
  hardcoded viewport decorations. See
  [WENYU_UI_MODULE_SYSTEM.md](/Users/kq/Workspace/moontown/docs/WENYU_UI_MODULE_SYSTEM.md).
- A town designer should be able to add, remove, or move feature buildings by
  editing `src/ui/assets/tilemap/modules/wenyu-town-modules.json`.
- The clean terrain layer should remain separate from service buildings,
  interiors, agents, and runtime effects.
- The MoonTown editor should stay at the multi-agent system level: module
  composition, MoonBook binding, worker-lane assignment, placement validation,
  and output availability. It may expose simple per-agent controls, but deep
  single-agent prompts, skill authoring, file browsing, and book/workspace
  editing belong in `../moondesk`.
- MoonDesk should export portable artifacts back to MoonTown: MoonBook folders,
  projection fragments, skill packs, agent profiles, asset packs, and module
  packs. MoonTown should import those artifacts as data/config rather than
  duplicating MoonDesk's desktop/editor responsibilities.

### 3.2 Resident Digital Twins

Purpose:

Each resident should have a visible agent-backed identity, memory, needs, and
current plan.

Required features:

- Resident profile.
- Venture and domain.
- Current need.
- Mood or confidence state.
- Memory stream summary.
- Reflection summary.
- Daily plan.
- Consent and privacy scope.
- Agent goals and recent agent actions.

MoonTown implementation:

- Display resident cards and map avatars.
- Track high-level town counters only.
- Route resident requests to the right civic MoonBook.

MoonBook implementation:

- Persist resident memory streams.
- Store resident profile pages.
- Promote memory candidates into durable notes.
- Generate resident-safe projection records for UI.

MoonClaw implementation:

- Execute resident agent tasks.
- Produce memory candidates.
- Produce plan/reflection outputs using role-specific skills.

Acceptance criteria:

- At least 3 seed residents are visible.
- Each resident has memory, reflection, and plan fields.
- Resident memory is sourced from MoonBook, not hardcoded UI state.
- Sensitive resident data has an explicit projection scope.

### 3.3 Policy Release Hall

Purpose:

Turn policy reading into guided quests and actionable checklists.

Required features:

- Policy source library.
- Agent interpretation.
- Eligibility matching.
- Scenario comparison.
- Application checklist generation.
- One-click packet preparation for later human confirmation.
- Source citations and confidence labels.

MoonTown implementation:

- Route policy requests to Policy Hall book.
- Show policy quest status in the town UI.
- Escalate low-confidence or high-risk answers.

MoonBook implementation:

- Own policy wiki.
- Own source ingestion and policy page structure.
- Persist eligibility templates and checklists.
- Review and publish generated policy explanations.

MoonClaw implementation:

- Fetch/read approved policy sources.
- Extract requirements.
- Draft interpretation and checklist packets.
- Return evidence-linked outputs.

Acceptance criteria:

- A resident can ask a policy question.
- A policy quest is created.
- MoonClaw produces a cited interpretation packet.
- MoonBook persists a reviewed policy page.
- UI shows quest stage and checklist readiness.

### 3.4 Contest Express

Purpose:

Turn contest participation into a nurturing workflow instead of a form-filling
event.

Required features:

- Contest calendar.
- Countdown.
- Application completeness check.
- Mock roadshow judge.
- Deck and project intro review.
- Reminder schedule.
- Champion wall and replay links.

MoonTown implementation:

- Schedule contest-related task batches.
- Show contest progress and town broadcasts.

MoonBook implementation:

- Persist contest workspace.
- Store participant materials, review notes, and readiness scores.

MoonClaw implementation:

- Analyze contest rules.
- Review decks and materials.
- Generate mock judge feedback.
- Package revision tasks.

Acceptance criteria:

- Contest page exists in MoonBook.
- At least one resident has a contest readiness record.
- UI shows stage, deadline, and next action.

### 3.5 Social Square

Purpose:

Convert weak ties into useful relationships without forcing awkward social
network behavior.

Required features:

- Interest graph.
- Complementarity matching.
- Cafe introduction proposals.
- Event initiation from one sentence.
- RSVP and reminder plan.
- Post-event reflection and follow-up.

MoonTown implementation:

- Show social matches and events.
- Escalate match proposals that require human approval.

MoonBook implementation:

- Persist social graph.
- Store event pages, follow-up notes, and match evidence.

MoonClaw implementation:

- Analyze resident profiles and memory candidates.
- Draft introductions, event plans, and follow-up notes.

Acceptance criteria:

- At least two residents are matched with a reason and confidence score.
- Match is linked to resident needs and skills.
- Follow-up is persisted in MoonBook.

### 3.6 Talent Star Avenue

Purpose:

Make talent density visible for residents, visitors, and district operators.

Required features:

- Talent cards.
- Skill heatmap.
- Achievement broadcasts.
- Reception route generation.
- VIP tour notes.
- Talent graph export.

MoonTown implementation:

- Render public-safe talent cards and heatmap signals.
- Show achievement broadcasts.

MoonBook implementation:

- Own talent wiki.
- Persist achievements and verification status.
- Generate talent graph projection.

MoonClaw implementation:

- Summarize achievements.
- Verify evidence when sources are available.
- Generate tour scripts and reception reports.

Acceptance criteria:

- Talent graph has at least 3 entities.
- Each talent card has domain, skills, recent activity, and evidence status.
- Operator can generate a reception summary.

### 3.7 District Vitality Dashboard

Purpose:

Make the district feel alive and measurable.

Required features:

- Resident joins.
- Active quests.
- Events today.
- Valley points issued/redeemed.
- Achievement broadcasts.
- Service response time.
- Agent action count.
- Retention and return signals.

MoonTown implementation:

- Own town-wide counters and health model.
- Persist daemon ticks and summary events.
- Show operator dashboard.

MoonBook implementation:

- Provide per-book counters.
- Provide review/publish state.

MoonClaw implementation:

- Emit run/event packets with task outcomes.

Acceptance criteria:

- Dashboard values update over ticks.
- Normal lifecycle states do not create degradation warnings.
- Failed/stale/offline states create visible recovery actions.

### 3.8 AI Science Garden

Purpose:

Make AI capability adoption easy and non-threatening.

Required features:

- Daily AI tip.
- Tool trial station.
- Scenario templates.
- Creator workshop.
- Tutorial quests.
- Before/after output comparisons.

MoonTown implementation:

- Schedule daily AI learning quests.
- Show active tutorial and completion state.

MoonBook implementation:

- Own AI Garden wiki and tutorial library.
- Persist workshop notes and resident learning progress.

MoonClaw implementation:

- Research tools.
- Draft tutorials.
- Generate examples and comparisons.

Acceptance criteria:

- Daily AI tip is generated with a concrete scenario.
- Tutorial page is persisted in MoonBook.
- UI shows current learning quest and resident uptake.

### 3.9 Virtual-Physical Connector

Purpose:

Bridge online town behavior to offline district services.

Required features:

- Robot service requests.
- Venue booking workflow.
- Offline event attendance check-in.
- Remote proxy attendance.
- Physical space digital twin signals.
- Human confirmation gate for risky actions.

MoonTown implementation:

- Route bridge requests.
- Track request lifecycle.
- Enforce approval and escalation rules.

MoonBook implementation:

- Persist venue/robot service knowledge.
- Store robot interaction summaries.
- Store event attendance notes.

MoonClaw implementation:

- Execute approved tool calls.
- Package robot/venue request results.
- Never bypass confirmation gates.

Acceptance criteria:

- UI shows robot calls and bridge state.
- Request lifecycle is visible from planned to completed or blocked.
- Any external transmission or booking confirmation is gated.

## 4. Runtime Data Contracts

### 4.1 Town Runtime Projection

MoonTown should publish a browser-consumable projection:

```json
{
  "town": {
    "id": "wenyu-valley",
    "name": "Wenyu Valley / AI Innovation Town",
    "tick": 123,
    "phase": "Cafe matching",
    "season": "Spring code festival",
    "weather": "River breeze",
    "health": {
      "budget": 74,
      "energy": 81,
      "pressure": 42,
      "stability": 88
    }
  },
  "residents": [],
  "books": [],
  "workers": [],
  "quests": [],
  "matches": [],
  "talent_signals": [],
  "bridge_events": [],
  "alerts": []
}
```

Initial implementation options:

- Generated static file: `.moonsuite/products/moontown/town-runtime.json`.
- Local endpoint: `GET /api/town-runtime`.
- MoonBook projection merge: one JSON fragment per civic book.

### 4.2 Resident Projection

```json
{
  "id": "resident-li",
  "display_name": "Li / Edge AI OPC",
  "venture": "Low-power vision module studio",
  "domain": "edge-ai",
  "need": "rental subsidy eligibility",
  "mood": "curious",
  "memory_summary": "Concerned about compute vouchers and demo timing.",
  "reflection_summary": "Prefers clear checklist before applying.",
  "plan_summary": "Policy quest, cafe intro, evening reflection.",
  "privacy_scope": "operator_demo"
}
```

Owner:

- MoonBook stores the full memory stream.
- MoonTown receives only the projected summary.

### 4.3 Quest Projection

```json
{
  "id": "quest-policy-rent-subsidy",
  "book_id": "wenyu-policy-hall",
  "title": "Rental subsidy walkthrough",
  "stage": "checklist_ready",
  "resident_id": "resident-li",
  "worker_run_id": "run-123",
  "evidence_count": 5,
  "requires_review": true,
  "reward": "80 Valley XP + application packet"
}
```

Owner:

- MoonTown routes and supervises.
- MoonBook persists.
- MoonClaw executes stage work.

## 5. Always-On Daemon Requirements

### 5.1 Durable Loop

The daemon must run the following loop:

```text
load checkpoint
acquire lease
hydrate town projection
poll active MoonClaw runs
ask Mayor for patrol decision
dispatch due tasks
run due standing-watch tasks through target MoonBooks
record watcher decisions and next due ticks
persist town checkpoint
publish town-runtime projection
sleep until next tick
```

### 5.2 Recovery

The daemon must recover from:

- process restart
- stale run heartbeat
- missing MoonBook projection
- missing MoonClaw result packet
- failed task
- partial write
- old lease

Acceptance criteria:

- Restarting the daemon does not duplicate active jobs.
- Failed jobs produce visible recovery actions.
- Normal review queues do not become degraded health.
- `.moonsuite/products/moontown/daemon.json` records lease, tick, heartbeat,
  and last action.
- `.moonsuite/products/moontown/watchers/*.jsonl` records topic watcher
  decisions, including update/no-change/review/failure outcomes and next due
  tick.

## 6. Implementation Milestones

### Milestone 0: Current Prototype

Status:

- Rabbita town UI exists.
- Wenyu-style modules are visible.
- Resident, quest, matching, talent, and bridge panels are simulated.
- Mayor recovery prevents synthetic collapse.

Exit criteria:

- Build passes.
- Browser shows no console errors.
- Tests pass.

### Milestone 1: Projection Contract

Build:

- `TownRuntimeProjection` type in MoonTown.
- Static `town-runtime.json` exporter.
- Rabbita source mode loads projection data.
- Snapshot mode stops being a placeholder.

Acceptance criteria:

- UI can render from generated JSON.
- Demo simulation and projection mode are visually distinguishable.
- JSON projection has stable tests.

### Milestone 2: Civic Module Support Workspaces

Status:

- Implemented on the MoonTown side as a civic protocol/service registry and
  bootstrap bridge.
- The registry now distinguishes module mode, persistence mode, and MoonBook
  support role:
  `agent-workspace`, `exchange-place`, `projection-surface`, `gateway`, and
  `hybrid`; plus `workspace-backed`, `ledger-backed`, `projection-backed`,
  `handoff-ledger-backed`, and `mixed-memory-backed`.

Implemented civic protocol support workspaces:

- `wenyu-town-shell`
- `wenyu-resident-twins`
- `wenyu-policy-hall`
- `wenyu-contest-express`
- `wenyu-social-square`
- `wenyu-talent-avenue`
- `wenyu-vitality-dashboard`
- `wenyu-ai-garden`
- `wenyu-physical-bridge`
- `wenyu-valley-market`
- `wenyu-broadcast-tower`

Acceptance criteria:

- Each support workspace has the durable substrate required by its persistence
  mode: wiki root when needed, dedicated skill pack, ledgers, projection
  fragment, and readiness summary. Implemented for seeded workspaces.
- MoonTown can bootstrap all civic support workspaces. Implemented with
  `moon run src/cmd/main -- civic bootstrap`.
- MoonBook generated site exposes module pages. Implemented as seeded
  `book/site/generated/index.html`; MoonBook-native templates are still the
  long-term target.

### Milestone 3: MoonClaw Execution Packs

Status:

- Implemented as generated MoonBook-local skill packs and MoonTown worker
  context contracts.

Role-specialized packs:

- policy researcher
- contest coach
- social matchmaker
- talent graph curator
- AI garden tutor
- robot bridge operator
- mayor patrol
- resident keeper
- vitality analyst
- market keeper
- story editor

Acceptance criteria:

- Each pack has `SKILL.md`. Implemented by civic bootstrap.
- Each pack emits a strict result packet. Contract text exists; real MoonClaw
  contract parsing is still pending.
- Each packet has evidence, summary, memory candidates, next actions, and
  review flags. Required by skills; needs repeated live execution validation.

### Milestone 4: Resident Memory

Build:

- Resident profile model.
- MoonBook memory stream pages.
- Reflection and plan records.
- Privacy projection rules.

Acceptance criteria:

- Resident card data comes from MoonBook.
- Memory candidates from MoonClaw become reviewable MoonBook updates.
- UI shows memory and plan summaries.

### Milestone 5: Real Civic Workflows

Build:

- Policy question to checklist.
- Contest readiness review.
- Social match proposal.
- Talent card generation.
- AI tutorial generation.
- Robot/venue bridge dry run.

Acceptance criteria:

- Each workflow produces persisted MoonBook artifacts.
- Each workflow is visible in MoonTown.
- Each workflow can be re-run without corrupting prior state.

### Milestone 6: Durable 24/7 Service

Build:

- Long-running daemon.
- Lease and lock model.
- Run reconciliation.
- Projection publisher.
- Health/recovery dashboard.

Acceptance criteria:

- Runs for 24 hours in a local soak test.
- Survives restart.
- No duplicate job dispatch after restart.
- UI continues to update from persisted state.

## 7. Non-Goals For Early Versions

- No real payment or financial transaction automation.
- No unsupervised final submission of applications.
- No robot booking finalization without user/operator confirmation.
- No sensitive personal data projection without explicit scope.
- No attempt to make Rabbita a full game engine before the runtime is real.
- No copying MoonBook or MoonClaw logic into MoonTown.

## 8. Safety and Compliance

The product must treat the following as high-risk:

- personal resident data
- company confidential details
- financial data
- legal or policy application submissions
- bookings and offline service requests
- public posts or broadcasts

Rules:

- MoonClaw can draft and prepare.
- MoonBook can persist reviewable records.
- MoonTown can route and escalate.
- User/operator confirmation is required before external submission,
  publication, booking, or sensitive data transmission.

## 9. Engineering Backlog

### MoonTown Backlog

- Keep `TownRuntimeProjection` and visual module projections aligned with the
  civic service registry.
- Add a building protocol registry so each civic building is a protocol place
  with inbox, aggregation, exchange, reduction, distribution, review gates, and
  projection status.
- Add append-only building protocol ledgers under
  `.moonsuite/products/moontown/civic/protocols/`
  for inbox, contributions, reductions, outbox, and reviews.
- Route resident/operator/mayor/book/worker signals into building inboxes
  before dispatching MoonClaw reducers.
- Keep only the protocol envelope, channels, safety gates, idempotency, and
  distribution destinations hardcoded; let building `SKILL.md` files guide the
  AI reducer behavior.
- Keep projection JSON writer and Rabbita source mode stable.
- Keep civic module book bootstrap aligned with MoonBook as templates migrate
  upstream.
- Add resident/quest/match/talent/bridge models.
- Continue hardening daemon loop, restart-safe lease handling, and multi-day
  soak evidence.
- Add mayor patrol decisions for Wenyu modules.
- Add town-level editor import/export for module packs, asset packs, worker
  lane profiles, and MoonBook projection bindings.
- Keep MoonTown editor changes scoped to multi-agent/town composition, not
  detailed single-agent or file/workspace editing.

### MoonBook Backlog

- Promote the current civic workspace seed contract into native MoonBook civic
  workspace templates.
- Add native schemas for building protocol records: input packet,
  contribution, reduction result, distribution packet, and review gate.
- Persist accepted building reductions as module-native civic records rather
  than generic research evidence.
- Add resident memory stream schema.
- Add quest schema and review queue.
- Add talent graph schema.
- Add social graph projection.
- Add Wenyu generated site template.
- Add projection fragment export.

### MoonClaw Backlog

- Promote generated Wenyu civic role skill packs into native MoonClaw skill
  packs where appropriate.
- Add building protocol reducer skills that can map incoming packets into
  contributions, reduce them into module-native outputs, and distribute them
  through allowed channels.
- Add strict packet schemas for each `wenyu.civic.*.v1` contract.
- Add policy source workflow.
- Add contest coach workflow.
- Add social match workflow.
- Add talent graph curator workflow.
- Add AI tutorial workflow.
- Add robot bridge dry-run workflow.

## 10. Success Metrics

### Product Metrics

- Average session duration.
- Return visits.
- Quest completion.
- Policy comprehension.
- Contest readiness improvement.
- Social match acceptance.
- Event participation.
- Talent card views.
- Robot service requests.

### Runtime Metrics

- Daemon uptime.
- Tick latency.
- Active run count.
- Failed run count.
- Recovery success rate.
- Projection freshness.
- MoonBook persistence success.
- MoonClaw packet validity.

### Quality Metrics

- Evidence-backed policy answers.
- Review queue age.
- Memory promotion precision.
- Duplicate dispatch count.
- UI console errors.
- Broken asset count.
- Accessibility and responsive layout pass rate.

## 11. Immediate Next Step

The next implementation should be Milestone 1:

```text
TownRuntimeProjection
  -> JSON export
  -> Rabbita projection source
  -> tests
```

This is the hinge between the current rich prototype and the real
MoonBook/MoonClaw-backed Wenyu Valley system.
