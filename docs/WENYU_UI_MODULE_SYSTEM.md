# Wenyu Valley Modular UI System

This document defines the next UI architecture for the Wenyu Valley viewport.
The goal is to keep the current clean map, while making civic functionality
rich, inspectable, and configurable.

## Product Intent

The Wenyu Valley UI should behave like a living civic town, not a decorative
dashboard. The terrain remains calm and readable. Complexity appears through
optional buildings, interiors, agents, effects, and runtime state.

The proposal document describes the town as:

- a 2D pixel-art game-like gateway
- an always-on AI Agent community platform
- a virtual-real bridge for OPC services
- a 1:1 Wenyu Valley terrain replica
- a set of civic modules that can grow over time

That maps naturally to a modular add-on system:

```text
base terrain
  + enabled civic modules
  + module-specific buildings
  + module-specific interiors
  + MoonBook projection fragments
  + MoonClaw worker activity
  + Moontown mayor supervision
```

## Design Principle

Keep three layers separate:

1. Terrain layer
   Static or slowly changing map: grass, farms, roads, river, lakes, bridges,
   wetlands, haze, and seasonal surface details.

2. Civic module layer
   Configurable buildings that represent product features: Policy Hall, Social
   Square, Talent Avenue, AI Garden, Physical Bridge, and other optional civic
   services.

3. Runtime layer
   Agents, messages, alerts, active runs, daemon ticks, watcher decisions,
   review queues, and MoonBook/MoonClaw status.

The UI should never require code edits just to add, remove, or move one civic
feature building.

## Editor Boundary: Moontown vs Moondesk

The Wenyu town editor is a multi-agent composition tool, not a detailed
single-agent authoring tool.

Moontown owns town-level editing:

- add, remove, enable, disable, and move civic modules
- bind each module to a MoonBook through `book_id`
- validate placement, collision, terrain fit, missing assets, and broken
  MoonBook projection bindings
- assign high-level worker roles and visible routing destinations
- show runtime state, active work, review pressure, and output availability
- export/import module packs that can be shared across towns

Moontown should only support simple agent edits:

- choose a worker role or lane
- choose visible home/destination building
- set basic capacity, cadence, and permission envelope
- attach or detach the worker from a module/book

Moondesk owns detailed human/workspace editing:

- browse and edit MoonBook files, wiki pages, reports, assets, and generated
  outputs through a desktop/file-manager-like workspace
- author detailed single-agent prompts, skill packs, memory rules, and review
  contracts
- inspect one book or one worker deeply without turning the town viewport into
  an IDE
- package the finished workspace, skill pack, asset pack, or agent profile for
  reuse

Portable output from Moondesk should enter Moontown as data, not as hardcoded
UI:

```text
Moondesk edited workspace
  -> MoonBook book folder / projection fragment
  -> skill pack or agent profile manifest
  -> asset pack / module pack
  -> Moontown module registry import
  -> mayor-visible multi-agent runtime
```

This boundary keeps the town viewport legible. Moontown designs the civic
system and supervises groups of agents; Moondesk handles the deep single-book
and single-agent work that would otherwise overload the town map.

## Module Registry

The first config file lives at:

```text
ui/assets/tilemap/modules/wenyu-town-modules.json
```

Each module entry is a town add-on:

```json
{
  "id": "policy-hall",
  "enabled": true,
  "title": "Policy Hall",
  "book_id": "wenyu-policy-hall",
  "district": "central-innovation",
  "building_kind": "policy-hall",
  "grid_x": 108,
  "grid_y": 63,
  "footprint_w": 8,
  "footprint_h": 6,
  "entrance_x": 111,
  "entrance_y": 69,
  "interior_kind": "policy",
  "asset_base": "tilemap/districts/policy_hall.png",
  "asset_roof": "",
  "summary": "Policy quests, eligibility checks, and cited application packets."
}
```

Required fields:

- `id`: stable module id used by the UI and selection state
- `enabled`: whether the module is present on the map
- `title`: user-facing building name
- `book_id`: MoonBook workspace binding
- `district`: semantic area on the map
- `building_kind`: CSS/art variant
- `grid_x`, `grid_y`: isometric tile anchor
- `footprint_w`, `footprint_h`: approximate placement footprint
- `entrance_x`, `entrance_y`: actor routing target
- `interior_kind`: furniture/interior variant
- `asset_base`: visible building sprite
- `asset_roof`: optional separate roof layer for later depth sorting
- `summary`: short inspection copy

## Feature-To-Building Map

| Proposal Feature | Module Building | Owner Split |
|---|---|---|
| 政策发布馆 | Policy Hall | Moontown routes, MoonBook stores policy wiki, MoonClaw researches and drafts |
| 赛事直通车 | Contest Express | Moontown schedules, MoonBook stores readiness records, MoonClaw reviews decks |
| 社交广场 | Social Square | Moontown shows matches, MoonBook stores social graph, MoonClaw drafts introductions |
| 人才星光大道 | Talent Avenue | Moontown projects public cards, MoonBook owns talent graph, MoonClaw verifies evidence |
| 街区活力看板 | Vitality Tower | Moontown owns counters, MoonBook exposes book counters, MoonClaw emits run packets |
| AI 科普花园 | AI Garden | Moontown schedules learning quests, MoonBook stores tutorials, MoonClaw drafts examples |
| 虚实连接器 | Physical Bridge | Moontown gates actions, MoonBook stores venue/robot knowledge, MoonClaw executes approved calls |
| 数字分身 | Resident Twin Homes | Moontown displays projections, MoonBook owns memory, MoonClaw emits candidates |
| 河谷积分 | Valley Market | Moontown projects point flow, MoonBook stores ledger records, MoonClaw drafts reward paths |
| Agent 故事雷达 | Broadcast Tower | Moontown highlights stories, MoonBook stores reviewed stories, MoonClaw summarizes events |

## Civic Module Binding

Every Wenyu module can bind to a canonical civic MoonBook support workspace,
but the building itself is not always a MoonBook. The registry distinguishes:

- `agent-workspace`: agents perform domain work and MoonBook is the primary
  workspace.
- `exchange-place`: the building is mainly a town place for requests, matching,
  consent, ledgers, or exchange; MoonBook stores supporting history/review.
- `projection-surface`: the building mainly displays runtime/accounting state.
- `gateway`: the building gates external/offline action and confirmation.
- `hybrid`: the building combines agent work with a visible civic place.

## Building As Protocol Place

The next abstraction is stronger than module binding. A building should be a
place where agents and information gather, exchange, reduce, and leave through
defined channels.

```text
building inbox
  -> aggregation of packets and local memory
  -> exchange between agents/books/residents under protocol rules
  -> AI-guided reduction into a building-native result
  -> review gate
  -> distribution to MoonBook, UI, mayor, agents, or external handoff
```

This is map/reduce-like, but the reducer is not hardcoded. Moontown should
hardcode the protocol envelope, channels, ledgers, permissions, idempotency, and
review gates. The building-specific `SKILL.md` should guide MoonClaw to decide
what the right reduction is.

Examples:

- Policy Hall reduces policy sources and resident questions into cited
  checklists or uncertainty review items.
- Social Square reduces consent-safe interests and event signals into match
  candidates, consent requests, or no-change follow-ups.
- Vitality Tower reduces daemon, watcher, worker, and projection records into
  a health digest and recovery queue.
- Physical Bridge reduces virtual requests and offline constraints into
  confirmation-gated handoff packets or blockers.
- Valley Market reduces offers, needs, points, and abuse signals into ledger
  updates or redemption review items.

The detailed protocol plan is in
[WENYU_BUILDING_PROTOCOL_PLAN.md](/Users/kq/Workspace/moontown/docs/WENYU_BUILDING_PROTOCOL_PLAN.md).

The current canonical support book ids are:

| Module | Book |
|---|---|
| Town Shell | `wenyu-town-shell` |
| Resident Twin Homes | `wenyu-resident-twins` |
| Policy Hall | `wenyu-policy-hall` |
| Contest Express | `wenyu-contest-express` |
| Social Square | `wenyu-social-square` |
| Talent Avenue | `wenyu-talent-avenue` |
| Vitality Tower | `wenyu-vitality-dashboard` |
| AI Science Garden | `wenyu-ai-garden` |
| Physical Bridge | `wenyu-physical-bridge` |
| Valley Market | `wenyu-valley-market` |
| Story Radar | `wenyu-broadcast-tower` |

Bootstrap the civic workspaces with:

```bash
moon run cmd/main -- civic bootstrap
```

That command updates `.moontown/moonbooks.json` and creates a seeded support
workspace for each civic module that needs durable state. Each workspace
receives:

- `raw/bootstrap/CIVIC_SERVICE_CONTRACT.md`
- `raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md`
- `wiki/index.md`
- canonical `wiki/schemas/*` pages
- module-specific `wiki/civic/*`, `wiki/sources/*`, `wiki/entities/*`,
  `wiki/concepts/*`, `wiki/queries/*`, or `wiki/synthesis/*` pages
- module-specific `wiki/reviews/*` queues
- `skills/wenyu-civic-service/SKILL.md`
- one dedicated skill pack such as `skills/civic-policy-researcher/SKILL.md`,
  `skills/civic-social-matchmaker/SKILL.md`, or
  `skills/civic-bridge-operator/SKILL.md`
- `book/moonbook-ui-state.json`
- `book/Home.html`
- `book/site/generated/index.html`
- `moonclaw.jobs.json` with the `wenyu_civic_service_worker` profile

Bootstrap and inspect the building protocol runtime with:

```bash
moon run cmd/main -- civic protocols bootstrap
moon run cmd/main -- civic protocols status
moon run cmd/main -- civic protocols patterns
moon run cmd/main -- civic protocols pattern-template templates/civic-salons/robotics-mini-salon.json
moon run cmd/main -- civic protocols pattern-template templates/civic-salons/robotics-mini-salon.json
moon run cmd/main -- civic doctor
```

The protocol bootstrap writes the town-level protocol registry under
`.moontown/civic/protocols.json` and per-building protocol ledgers under
`.moontown/civic/protocols/<building-id>/`. Social Square has a protocol proof
slice and can run additional `research-salon` communication-pattern scenarios
from `CivicSalonScenario` JSON templates. A research salon creates the
internal participant workspaces declared by the template,
receives perspective packets, reduces them into cross-area research ideas, and
projects the result through the same module interior counters. It also writes
template-defined metrics in the Social Square book and returns relevant ideas
to each participant home book at
`wiki/queries/salon-returned-ideas.md`.

The research-salon projection is now fed by generic `CivicSalonScenario`
templates.
There is no domain-specific default proof scenario in MoonBit; new domains
arrive as template JSON and generated skill rules instead of frontend or
MoonBit branches.

This is a Moontown-side bootstrap bridge. Long term, MoonBook should own the
native civic workspace templates, and Moontown should request them through a
book creation API instead of writing every seed file directly.

Do not route all modules through a generic research skill. Policy Hall needs
policy intelligence, Contest Express needs coaching, Social Square needs
consent-aware matchmaking, Vitality Tower needs observability/accounting,
Physical Bridge needs confirmation-gated handoff, Valley Market needs ledger
keeping, and Story Radar needs public story editing.

## Visual Richness Without Clutter

The current map is clean, which is valuable. Do not solve richness by filling
every tile. Add detail where it communicates state.

Recommended upgrades:

- River depth: darker river centers, lighter banks, reed clusters, bridge
  shadows, and shallow edge highlights.
- Water reflection: subtle, slow shimmer strips near bridges and civic
  buildings. These should be CSS/runtime overlays, not destructive edits to the
  base raster.
- Buildings: each civic module gets a distinct silhouette and roof language.
- Interiors: clicking a module switches to an interior scene with furniture
  matched to the module function.
- Agents: working agents appear outside and move toward their active module;
  idle or finished agents stay inside relevant buildings.
- Labels: building info stays hidden by default and appears on hover/focus.
- Seasonal detail: flowers, window glow, weather, and day phase should be
  driven by real-world time and config, not random virtual time.

## Runtime Binding

Each module binds to a MoonBook through `book_id`.

```text
module.book_id
  -> MoonBook projection fragment
  -> module-projections.json bridge
  -> Moontown runtime projection
  -> viewport building status
  -> actor destination
  -> interior worker roster
  -> generated output links
```

The visual state should come from real runtime data when available:

- active runs -> building pulse and visible workers
- review queues -> amber review light
- failed/stale runs -> recovery marker
- no work due -> calm/idle building
- projection missing -> explicit integration-gap panel inside the module

## Implementation Stages

Current implementation status is tracked in
[WENYU_TOWN_STATUS.md](/Users/kq/Workspace/moontown/docs/WENYU_TOWN_STATUS.md).
Use that document as the readiness checklist before claiming the town is fully
functioning.

### Stage 1: Configurable Buildings

- Load `wenyu-town-modules.json` in the Rabbita bootstrap.
- Parse enabled modules in MoonBit.
- Render module buildings as a separate layer above the raster terrain.
- Clicking a module opens a module-specific interior.
- Hover/focus reveals the building info panel.

### Stage 2: Visual Water System

- Add a water-effect layer over the base map.
- Add depth, bank glow, bridge shadow, and shimmer overlays.
- Keep effects pointer-transparent and cheap to animate.

### Stage 3: Agent Routing

- Route visible agents to `entrance_x` and `entrance_y` from the module config.
- Show only working or blocked agents outside.
- Keep idle, waiting, and completed agents inside buildings unless a user opens
  that building.

Current status:

- active visual agents now route to a matched module entrance when their
  book/task maps to a configured module
- idle, completed, and absent module agents do not create fake overworld badges
- the remaining gap is projection coverage: each Wenyu civic workflow still
  needs to emit module-specific book/task/run fragments

### Stage 4: Runtime Projection

- Extend Moontown projection JSON with module status.
- Merge MoonBook projection fragments by `book_id`.
- Bind building lights, counters, badges, and messages to real data.

Current status:

- the viewport uses visual projection data first, direct execution records
  second, and config fallback last
- module lights distinguish running, waiting, review, alert, complete,
  projected, unbound, and calm states
- module interiors show runtime source, status counters, validation state, and
  active worker roster slots
- `visual-projection.json` now includes first-class `modules[]` status objects
  keyed by normalized module id
- the Vite bridge now scans `.moontown/books/*/book/moonbook-ui-state.json`
  and publishes `module-projections.json`
- book projection visibility is explicit: public building books use
  `projection_scope: public`, internal salon workspaces use
  `projection_scope: internal`, and operators can adjust policy in
  `.moontown/book-projection-policy.json` without frontend code changes
- module interiors now show MoonBook summary, chips, metrics, readiness,
  review queue, page families, output links, and latest journey when a bound
  book fragment exists
- `moon run cmd/main -- civic bootstrap` can populate each Wenyu feature
  building with a seeded MoonBook projection, schemas, review queues, and
  service skills
- the remaining gap is execution maturity: every civic service needs repeated
  MoonClaw runs, accepted MoonBook updates, review history, and projection
  freshness before it can be considered reliable

### Stage 5: Asset Pipeline

- Generate missing building variants with image generation.
- Keep prompts in `ui/assets/tilemap/prompts/`.
- Slice assets into transparent PNG sprites.
- Register assets in `manifest.json`.
- Never bake text into building sprites.

### Stage 6: Designer Tooling

- Validate module JSON before rendering.
- Detect buildings placed on water or blocked roads.
- Preview changed modules without rebuilding MoonBit code.
- Report missing assets, oversized sprites, non-transparent backgrounds, and
  broken `book_id` bindings.
- Export a placement diff that can be reviewed before committing map changes.

Current status:

- viewport runtime validation catches missing `book_id`, missing assets, invalid
  footprints, building anchors on blocked terrain, and entrances on water
- bridge/river/harbor modules can opt into water or bridge placement
- editor mode now shows the town/Moondesk boundary, the handoff manifest, and
  recent bridge records next to module validation
- `tilemap/modules/moondesk-handoff.json` defines the portable artifact lanes
  that can be imported without changing viewport code
- `moondesk-bridge.json` scans real `.moontown/moondesk-*` and
  `.moontown/book-results` files for recent portable records
- standalone write-back editing, schema validation, and richer designer preview
  tooling are still pending

### Stage 7: Civic Runtime Integration

- Require every enabled module to bind to a populated MoonBook projection
  fragment.
- Require every active worker avatar to derive from a MoonClaw run or standing
  watcher record.
- Show output links, review gaps, and last accepted knowledge changes in the
  interior view.
- Keep decorative animation separate from truth-bearing runtime status.

Current status:

- the civic registry defines one service contract per enabled civic building
- Mayor decomposition uses that registry to create isolated service lanes
- civic protocol support workspaces route directly to the service workflow first, rather than through
  the Wenyu research/bootstrap gate used by product-build books
- worker context enrichment adds generic and module-specific civic skill files
- each civic output contract uses explicit markers such as
  `civic_service_decision`, `book_changed`, `wiki_pages_changed_count`,
  `accepted_facts_count`, `review_items_created_count`,
  `projection_updated`, and `next_check_hint`

Remaining:

- run and inspect each service lane end to end
- parse the civic result markers into structured service ledgers
- show accepted changes and pending review items in each module interior
- move reusable civic templates into MoonBook as the canonical owner

### Stage 8: Building Protocol Runtime

- Add protocol definitions for every enabled building.
- Persist building inbox, contribution, reduction, outbox, and review ledgers.
- Route resident/operator/mayor/book/worker signals into building inboxes.
- Let MoonClaw reducers choose the module-native aggregation/reduction strategy
  from the building `SKILL.md`, rather than forcing a generic research or fixed
  procedural workflow.
- Persist accepted reductions into the building's MoonBook role.
- Project protocol state into the viewport: inbox pressure, active reduction,
  pending review, outgoing distributions, blocked handoffs, and recent accepted
  results.

Acceptance for this stage:

- a building can receive at least one real input packet
- the packet is grouped into a building-native contribution
- a MoonClaw skill reduces the contributions into a module-native output
- MoonBook accepts or rejects that output with civic accounting
- the UI shows the protocol state without inventing fake activity
- restart/retry does not duplicate reductions or distributions

Current status:

- protocol definitions exist for all 11 enabled Wenyu civic buildings
- civic workspaces include `BUILDING_PROTOCOL_CONTRACT.md`
- worker prompts and civic skills explicitly treat buildings as protocol
  places rather than generic research books
- Social Square has a first durable protocol proof slice and appears in the
  viewport as a consent-gated protocol review
- generic Social Square salon templates now measure idea yield, research
  question yield, cross-book links, home-book coverage, and return-home
  records instead of only counting packets
- generic salon templates can feed the same projection path for future
  domains without changing the viewport

Remaining:

- add one real scenario template and reducer path for each other civic building
- route mayor/operator/resident/watch signals into protocol inboxes
- persist accepted/rejected reductions into the correct MoonBook pages
- show recent protocol history, not just current counters, inside interiors

## Acceptance Criteria

- A designer can remove a building by setting `enabled` to `false`.
- A designer can move a building by changing `grid_x` and `grid_y`.
- A designer can move its door and road endpoint by changing `entrance_x` and
  `entrance_y`.
- A designer can size the module using `footprint_w`, `footprint_h`,
  `display_w`, and `display_h` without changing renderer code.
- A designer can bind behavior using `protocol_pattern`, `use_case`, and
  `agent_flow`; the interior panel must show these fields.
- A designer can add a new building by adding one JSON object and one asset.
- The viewport still loads if a module asset is missing.
- Hover/focus reveals building information; labels are hidden otherwise.
- The base terrain remains visually calm.
- River depth/reflection is visible but not noisy.
- The UI builds with `npm run build`.
- MoonBit checks pass with `moon check`.
- Runtime labels distinguish configured modules from real active work.
- Worker avatars are not shown as busy unless a real task/run/watch record says
  they are busy.
- Civic buildings show protocol state, not only workspace health.
- A building is not considered fully functioning until it has durable inbox,
  reduction, outbox, and review/accounting records.
