///|
pub fn cookbook_codebase_overview_markdown() -> String {
  [
    "# Moontown Codebase Describer", "", "This cookbook should help an engineer understand how Moontown works as code. It is not a directory tour. It describes the algorithms, data records, state files, control loops, AI boundaries, and evidence paths that make the town run.",
    "", "## Mental Model", "", "Moontown is a MoonBit control plane built around typed records and restart-readable files. Most behavior follows this pattern:",
    "", "```text", "typed record in memory", "  -> deterministic phase function",
    "  -> JSON or Markdown file boundary", "  -> bounded MoonBook/MoonClaw work",
    "  -> reconcile result into typed record", "  -> projection for operator or UI",
    "```", "", "The key design choice is that AI work is not the data structure. AI is a reducer, reviewer, planner, or worker inside a bounded protocol. The durable structures are MoonBit records, MoonBook pages, JSON ledgers, generated site files, and append-only journals.",
    "", "## Codebase Reading Order", "", "- Start with `wiki/describer/data-structures.md` to learn the records that carry state.",
    "- Then read `wiki/describer/data-flow.md` to see how those records move through files and runtime phases.",
    "- Then read `wiki/describer/algorithms.md` to understand the major loops and reducers.",
    "- Then read `wiki/describer/core-features.md` for feature-by-feature implementation notes.",
    "- Use `skills/cookbook-generation/SKILL.md` when asking an AI maintainer to update this book.",
  ].join("\n")
}

///|
pub fn cookbook_algorithms_markdown() -> String {
  [
    "# Algorithms Used In Moontown", "", "Moontown mostly uses explicit orchestration algorithms over typed records. The important algorithms are phase pipelines, reconciliation loops, map/reduce-style civic protocols, due-schedule checks, and projection derivations.",
    "", "## 1. Town State Mutation Algorithm", "", "Core files: `core/town_state_types.mbt`, `core/types.mbt`, `core/execution_types.mbt`.",
    "", "Moontown keeps a `TownState` record with arrays of books, workers, tasks, executions, and events. Updates are intentionally simple and inspectable:",
    "", "- `register_book`, `register_worker`, `enqueue_task`, and `record_event` append records.",
    "- `replace_task` scans by `task.id`; if found, it overwrites that array slot, otherwise it appends.",
    "- `replace_execution` scans by `task_id`; if found, it overwrites that execution, otherwise it appends.",
    "- `set_worker_status` scans by worker id and rewrites only the matching worker record.",
    "- `find_task` and `find_execution` are linear lookups over the arrays.", "",
    "This is not optimized for database scale. It is optimized for local determinism, clear JSON persistence, easy tests, and readable reconciliation.",
    "", "## 2. Daemon Tick Phase Pipeline", "", "Core files: `daemon_tick_context.mbt`, `daemon_tick_saved_town.mbt`, `daemon_run_loop.mbt`.",
    "", "The daemon tick is a deterministic phase pipeline:", "", "```text", "prepare context",
    "  -> supervision phase", "  -> standing-goal phase", "  -> scheduled-jobs phase",
    "  -> planbook phase", "  -> projection phase", "```", "", "The context loader reads the MoonBook catalog, standing goals, saved town snapshot, daemon state, watcher records, and tick floor. The tick floor prevents the daemon sequence from moving backward when watcher ledgers or saved state already imply a later tick.",
    "", "The run loop wraps this tick in heartbeat management. It marks worker start, touches heartbeat while ticking, handles stop/restart markers, appends daemon logs, and sleeps between iterations.",
    "", "## 3. Standing-Watch Dispatch And Reconciliation", "", "Core files: `standing_watch_cycle_execution.mbt`, `goal_execution.mbt`, `goal_supervision_core.mbt`.",
    "", "Standing watch turns long-horizon goals into bounded book-local tasks:",
    "", "```text", "due goal", "  -> Mayor route decision", "  -> BookTask and keeper packet",
    "  -> MoonClaw import or detached import", "  -> TaskExecutionRecord", "  -> replace task/execution",
    "  -> sync worker state", "  -> append event and watcher ledger", "```", "",
    "The algorithm protects cadence by allowing detached MoonClaw imports. A tick can record `RunConfirmed` or `Running` and later ticks reconcile the real result. Transient infrastructure failures become deferred operational debt instead of accepted domain progress.",
    "", "## 4. Civic Building Protocol Map/Reduce", "", "Core files: `civic/protocol_types.mbt`, `civic/protocols.mbt`, `civic_protocol_store.mbt`, `civic_salon_scenario_runtime.mbt`.",
    "", "Civic buildings use a map/reduce-like protocol envelope:", "", "```text",
    "BuildingInputPacket", "  -> BuildingContribution", "  -> BuildingReductionResult",
    "  -> BuildingDistributionRecord", "  -> BuildingReviewGateRecord", "  -> BuildingProtocolSnapshot",
    "```", "", "Moontown hardcodes envelope, ledgers, idempotency keys, privacy labels, review status, and allowed destinations. MoonClaw supplies the AI-guided reduction inside the building skill. MoonBook owns accepted building pages, review queues, generated projections, and durable support workspaces.",
    "", "## 5. Civic Scenario Materialization", "", "Core files: `civic_salon_scenario_runtime.mbt`, `civic_salon_scenario_workspace.mbt`, `civic_salon_scenario_protocol_outputs.mbt`.",
    "", "A recurring or one-off civic scenario runs as:", "", "```text", "load scenario template",
    "  -> choose reducer mode", "  -> run MoonClaw reducer or persisted/fixture reducer",
    "  -> validate non-empty typed outputs", "  -> merge participant books into catalog",
    "  -> write participant workspaces", "  -> seed protocol ledgers", "  -> write building pages",
    "  -> refresh protocol and civic status projections", "```", "", "The important guard is that invalid or empty reducer output blocks the round. The runtime writes a blocker instead of pretending template examples are real civic intelligence.",
    "", "## 6. Book Template Request Processing", "", "Core files: `book_templates_request_processing.mbt`, `book_templates_request_ledger.mbt`, `app_tool_book_workspace.mbt`.",
    "", "Book templates are installed through a request ledger. Pending or retry requests call `install_book_template_config`; other requests reconcile existing work. Every processed request appends an event with request id, template id, status, summary, tick, and generation timestamp.",
    "", "This lets Moondesk, Mayor, or future AI plans ask for new durable books without hardcoding one-off copy steps into the daemon.",
    "", "## 7. Live Autonomy Derivation", "", "Core files: `live_autonomy_builder.mbt`, `live_autonomy_derived_state.mbt`, `live_autonomy_metric_counts.mbt`.",
    "", "The live autonomy spine is a derived-state algorithm. It gathers saved town state, standing goals, watcher records, daemon tick summary, PlanBook status, template request status, and prior stable-waiting streak. It computes metrics, waiting state, summary text, blockers, and next actions, then writes a compact JSON spine for operators and UI.",
    "", "## 8. Visual Projection Derivation", "", "Core files: `visual_projection_buildings.mbt`, `visual_projection_agents.mbt`, `visual_projection_grid.mbt`.",
    "", "Visual projection maps runtime records into town-visible agents and buildings. It counts worker phases per book, derives building status/effects, strips the `wenyu-` prefix to map book ids to module ids, and emits messages such as active worker count or blocked building count. The UI reads this projection; it does not invent runtime truth.",
  ].join("\n")
}

///|
pub fn cookbook_data_structures_markdown() -> String {
  [
    "# Moontown Data Structures", "", "Moontown's main data model is a set of MoonBit records that can be serialized to JSON and reconciled after restart. The cookbook should teach these records before it teaches directories.",
    "", "## Town Runtime Records", "", "| Record | Key Fields | Purpose | Mutation Pattern |",
    "| --- | --- | --- | --- |", "| `TownConfig` | `id`, `name`, `heartbeat_seconds`, `max_concurrent_tasks` | Global town settings. | Constructed at bootstrap and saved in `TownState`. |",
    "| `BookRef` | `id`, `workspace_root`, `memory_scope`, `tags` | Runtime reference to a MoonBook workspace. | Registered into `TownState.books`. |",
    "| `WorkerRef` | `id`, `book_id`, `role`, `capabilities`, `status` | Visible worker lane or role binding. | Registered and later status-updated by execution reconciliation. |",
    "| `TownTask` | `id`, `book_id`, `prompt`, `domain`, `required_role`, `status` | Town-level task envelope. | Enqueued, then replaced by id as execution changes. |",
    "| `TaskExecutionRecord` | `task_id`, `packet_path`, `proposal_id`, `run_id`, `status`, `result_decision`, `requires_review` | The durable bridge from a task to MoonClaw/MoonBook work. | Replaced by `task_id`; stale/retry/review fields guide later ticks. |",
    "| `TownEvent` | `kind`, `detail`, related ids | Append-only operator trail. | Always appended. |",
    "", "## Execution Status Model", "", "`TaskExecutionStatus` is the execution state machine vocabulary:",
    "", "```text", "PacketReady -> ProposalImported -> RunConfirmed -> Running",
    "Running -> AwaitingPersistence -> ReviewQueued -> Completed", "Running -> Stale",
    "any active phase -> Failed", "```", "", "The status does not by itself mean the work changed the town. `result_decision`, `requires_review`, `notify_town`, watcher ledgers, and MoonBook persistence decide whether the output is accepted progress, review debt, no-change evidence, or an operational failure.",
    "", "## Standing Goal Records", "", "`StandingGoal` records long-horizon watch policy: `target_book_id`, `cadence_ticks`, `next_due_tick`, `last_run_tick`, `enabled`, `source_policy`, and `quality_threshold`. The daemon compares these fields with the current tick to decide what should dispatch.",
    "", "`WatcherDecisionKind` classifies the result as `Update`, `NoChange`, `NeedsReview`, `Failed`, or `Deferred`. This prevents retries or quiet cycles from being counted as domain growth.",
    "", "## Civic Protocol Records", "", "| Record | Meaning | Durable Evidence |",
    "| --- | --- | --- |", "| `BuildingProtocolDefinition` | Static contract for a civic building: roles, channels, policies, review gates, skill packs, projection contract. | `.moontown/civic/protocols.json` |",
    "| `BuildingInputPacket` | Raw request, fact, schedule claim, resident signal, or source packet entering a building. | `inbox.jsonl` |",
    "| `BuildingContribution` | Mapped/normalized contribution derived from one or more inputs. | `contributions.jsonl` |",
    "| `BuildingReductionResult` | AI-guided or deterministic building-native output with changed pages, accepted records, review items, and distribution targets. | `reductions.jsonl` |",
    "| `BuildingDistributionRecord` | Where a reduced output went: book, UI projection, review queue, resident, or external handoff. | `outbox.jsonl` |",
    "| `BuildingReviewGateRecord` | Why a gate accepted, blocked, or queued a sensitive output. | `reviews.jsonl` |",
    "| `BuildingProtocolSnapshot` | UI/operator summary of counts, latest reduction, latest distribution, status, and readiness. | `.moontown/civic/protocol-status.json` |",
    "", "## Book And Cookbook Records", "", "The cookbook itself uses `MoontownCookbookManifest`, `CookbookArtifact`, and `MoontownCookbookStatus`. These records describe what source docs, definitions, and runtime-state files are expected, whether required paths exist, and whether the generated book workspace is ready.",
    "", "The manifest is deliberately a stable-state index, not a replacement data model. The actual codebase data structures remain the MoonBit records above and the MoonBook/civic files they write.",
  ].join("\n")
}

///|
pub fn cookbook_data_flow_markdown() -> String {
  [
    "# Moontown Data Flow", "", "Moontown data flow is file-backed and phase-driven. The same facts usually appear in three forms: a MoonBit record while a command is running, a JSON/Markdown file for restart and review, and a projection for UI or operators.",
    "", "## Goal Execution Flow", "", "```text", "operator / standing goal / daemon schedule",
    "  -> TownTask", "  -> MayorDispatchPacket", "  -> MoonBook keeper packet", "  -> MoonClaw proposal/run",
    "  -> TaskExecutionRecord", "  -> TownState replacement", "  -> watcher/event/live-autonomy projection",
    "```", "", "Important files:", "", "- `.moontown/town.json`: saved `TownState`.",
    "- `.moontown/standing-goals.json`: standing watch policy.", "- `.moontown/watchers/<goal-id>.jsonl`: watch history and decisions.",
    "- book-local MoonClaw job stores: proposal/run receipts and result JSON.", "",
    "## Daemon Flow", "", "```text", "daemon run loop", "  -> mark worker heartbeat",
    "  -> run daemon tick", "  -> supervision and reconciliation", "  -> scheduled civic/book jobs",
    "  -> planbook repair/autonomy checks", "  -> visual projection + live autonomy spine",
    "  -> daemon log and journal", "```", "", "Important files:", "", "- `.moontown/daemon.json`: tick state.",
    "- `.moontown/daemon-runtime.json`: supervisor and worker process state.", "- `.moontown/daemon.log`: phase and health trail.",
    "- `.moontown/live-autonomy.json`: compact operator spine.", "- `.moontown/town-journal.jsonl`: append-only live-state journal.",
    "", "## Civic Building Flow", "", "```text", "resident/source/schedule/operator signal",
    "  -> building inbox packet", "  -> contribution ledger", "  -> MoonClaw reducer or deterministic reducer",
    "  -> reduction result", "  -> review gate", "  -> outbox distribution", "  -> MoonBook support workspace and projection",
    "```", "", "Important files:", "", "- `.moontown/civic/protocols.json`: building protocol definitions.",
    "- `.moontown/civic/protocols/<building-id>/*.jsonl`: protocol ledgers.", "- `.moontown/civic/protocol-status.json`: protocol portfolio projection.",
    "- `.moontown/civic/status.json`: civic service status projection.", "- `.moontown/books/<book-id>/wiki/...`: accepted or review-gated support pages.",
    "", "## Book Template Flow", "", "```text", "Moondesk / Mayor / PlanBook request",
    "  -> .moontown/book-template-requests.json", "  -> process pending or retry request",
    "  -> install template config", "  -> write book workspace", "  -> append request event",
    "  -> register standing goal when needed", "```", "", "This flow is the extensibility path for new books and tools. It avoids hardcoding every future book inside Moontown source.",
    "", "## Projection Flow", "", "```text", "TownState + civic protocol status + daemon state + MoonBook outputs",
    "  -> visual agent/building projection", "  -> live autonomy spine", "  -> generated site/UI-state JSON",
    "  -> Rabbita viewport / Moondesk / operator command output", "```", "", "Projection files are read models. They are allowed to summarize, count, and label, but not to become the source of truth for accepted civic facts or book memory.",
  ].join("\n")
}

///|
pub fn cookbook_core_features_markdown() -> String {
  [
    "# Core Features In Code",
    "",
    "This page explains core Moontown features as implementation behavior: entry points, state records, algorithms, AI boundaries, and proof files.",
    "",
    cookbook_core_feature(
      "Saved Town Runtime",
      "Keeps books, workers, tasks, executions, and events in one restart-readable `TownState`.",
      ["core/town_state_types.mbt", "moontown.mbt", "moontown_snapshot.mbt"],
      [
        "Commands load or create `.moontown/town.json`.", "Runtime code mutates arrays through register/replace helpers.",
        "Execution reconciliation updates task, execution, worker, and event records together.",
      ],
      "No AI owns this state. AI outputs must pass through task/execution records and book persistence before they affect the saved town.",
      [".moontown/town.json", "runtime status command output"],
    ),
    cookbook_core_feature(
      "Mayor Supervision",
      "Routes due work, reconciles active executions, and keeps the town from confusing activity with accepted progress.",
      [
        "roles/mayor.mbt", "goal_supervision_core.mbt", "daemon_tick_saved_town.mbt",
      ],
      [
        "Derive or receive a tick number.", "Inspect current executions and tasks.",
        "Route work into book-local or civic lanes.", "Classify stale, review, failed, and completed work.",
      ],
      "Mayor planning can be AI-shaped, but Moontown code owns dispatch budget, stale windows, retry status, and operator-visible accounting.",
      [
        ".moontown/daemon.json", ".moontown/watchers/*.jsonl", ".moontown/live-autonomy.json",
      ],
    ),
    cookbook_core_feature(
      "MoonBook/MoonClaw Execution Bridge",
      "Turns a book task into a keeper packet, imports it into MoonClaw, then records proposal/run status back into Moontown.",
      [
        "goal_execution.mbt", "adapters/moonclaw/import.mbt", "adapters/moonclaw/run_polling.mbt",
      ],
      [
        "Mayor prepares a keeper packet with context pages, skill paths, and output contract.",
        "MoonClaw import returns proposal id, optional run id, status, and command.",
        "Polling reads result payload and maps it to `TaskExecutionRecord` fields.",
      ],
      "MoonClaw may execute tools and synthesize results. The bridge guards review status, result decision, and stale retry semantics.",
      [
        "book-local `moonclaw.jobs.json`", "book-local `.moonclaw/jobs/...`", "TaskExecutionRecord",
      ],
    ),
    cookbook_core_feature(
      "Civic Building Protocols",
      "Models Wenyu buildings as protocol places instead of UI cards or single agents.",
      [
        "civic/protocol_types.mbt", "civic/protocols.mbt", "civic_protocol_status_runtime.mbt",
      ],
      [
        "Generate one protocol definition per civic service.", "Persist protocol registry and ledgers.",
        "Summarize counts and latest records into protocol status.", "Project protocol state into civic status and viewport-safe output.",
      ],
      "AI is a building reducer. It decides the module-native output inside policy, channel, privacy, and review-gate constraints.",
      [
        ".moontown/civic/protocols.json", ".moontown/civic/protocol-status.json",
        ".moontown/civic/protocols/<building-id>/*.jsonl",
      ],
    ),
    cookbook_core_feature(
      "Communication Pattern Runtime",
      "Runs reusable civic scenarios such as research salon, match market, triage desk, signal watch, review council, and incident bridge.",
      [
        "civic_communication_patterns.mbt", "civic_salon_scenario_runtime.mbt", "civic_salon_scenario_protocol_outputs.mbt",
      ],
      [
        "Load a scenario JSON template.", "Create participant workspaces and reducer workspace.",
        "Run MoonClaw or persisted reducer mode.", "Validate output contract.", "Write ledgers, returned-home pages, metrics, and review queues.",
      ],
      "The reducer can be AI-guided, but empty or invalid output blocks the round. Fixture output is only a test/smoke path.",
      [
        "assets/templates/civic-patterns/*.json", ".moontown/civic/pattern-runs/",
        "participant `wiki/queries/salon-returned-ideas.md`",
      ],
    ),
    cookbook_core_feature(
      "Live Autonomy Spine",
      "Summarizes whether the town is active, stable waiting, blocked, reviewing, or carrying transient infrastructure debt.",
      [
        "live_autonomy_builder.mbt", "live_autonomy_derived_state.mbt", "live_autonomy_journal.mbt",
      ],
      [
        "Gather current town state, standing goals, watcher records, PlanBook status, and template request status.",
        "Compute metrics and stable-waiting blockers.", "Write compact JSON plus journal/digest paths.",
      ],
      "AI may interpret next actions, but the spine is generated from observed runtime evidence.",
      [
        ".moontown/live-autonomy.json", ".moontown/town-journal.jsonl", ".moontown/live-autonomy-digest.md",
      ],
    ),
    cookbook_core_feature(
      "Visual And UI Projection",
      "Converts runtime and civic status into visible agents, buildings, effects, and messages for the town viewport.",
      [
        "visual_projection_buildings.mbt", "visual_projection_agents.mbt", "ui/dashboard_town_map_places.mbt",
      ],
      [
        "Count execution phases by book and worker.", "Derive building effects and module status.",
        "Resolve assets and map places from scene layout.", "Emit projection messages and UI-safe records.",
      ],
      "AI may write summaries that become projection text after review, but browser-local UI state is never authoritative town state.",
      [
        ".moontown/visual-projection.json", "ui/assets/tilemap/modules/wenyu-town-modules.json",
      ],
    ),
    cookbook_core_feature(
      "PlanBook And Cookbook Control",
      "Keeps active implementation plans separate from accepted stable-state description.",
      [
        "planbook_repair.mbt", "planbook_autonomy.mbt", "cookbook.mbt", "cookbook_workspace.mbt",
      ],
      [
        "PlanBook tracks open criteria, repair tasks, validation commands, and engineering digests.",
        "Cookbook bootstrap writes stable-state manifest, wiki describer pages, generated HTML, and its own skill.",
        "The daemon can surface PlanBook gaps without counting them as accepted implementation progress.",
      ],
      "AI can propose repairs and cookbook updates, but accepted descriptions must cite code paths, data structures, flows, and validation evidence.",
      [
        ".moontown/books/plan-moontown-quality/", ".moontown/books/moontown-cookbook/",
        ".moontown/cookbook/stable-state.json",
      ],
    ),
  ].join("\n")
}

///|
fn cookbook_core_feature(
  title : String,
  purpose : String,
  code_paths : Array[String],
  behavior : Array[String],
  ai_boundary : String,
  evidence : Array[String],
) -> String {
  [
    "## \{title}",
    "",
    "Purpose: \{purpose}",
    "",
    "Code paths:",
    markdown_bullets(code_paths),
    "",
    "Implementation behavior:",
    markdown_bullets(behavior),
    "",
    "AI boundary: \{ai_boundary}",
    "",
    "Evidence to inspect:",
    markdown_bullets(evidence),
  ].join("\n")
}

///|
pub fn cookbook_skill_markdown() -> String {
  [
    "---",
    "name: cookbook-generation",
    "description: Maintain the Moontown cookbook as a codebase describer that explains algorithms, data structures, data flow, core features, AI boundaries, and stable-state evidence rather than merely listing directories.",
    "---",
    "",
    "# Moontown Cookbook Generation",
    "",
    "Use this skill when updating the `moontown-cookbook` MoonBook or asking an AI maintainer to describe Moontown.",
    "",
    "## Primary Rule",
    "",
    "The cookbook must explain how the codebase works. Do not write a directory tour. Every substantial section should name at least one algorithm, record type, data-flow boundary, command, state file, review gate, or projection artifact.",
    "",
    "## Required Description Layers",
    "",
    "- Algorithms: daemon tick phases, standing-watch dispatch, task/execution reconciliation, civic map/reduce protocols, scenario materialization, template request processing, live autonomy derivation, and visual projection.",
    "- Data structures: `TownState`, `BookRef`, `WorkerRef`, `TownTask`, `TaskExecutionRecord`, `StandingGoal`, civic protocol packet/reduction/distribution/review records, and cookbook manifest records.",
    "- Data flow: operator or schedule input, Mayor routing, MoonBook packet creation, MoonClaw execution, MoonBook persistence, Moontown reconciliation, runtime state files, and UI projections.",
    "- Core features: saved town runtime, Mayor supervision, MoonBook/MoonClaw bridge, civic building protocols, communication patterns, live autonomy, visual projection, PlanBook, and cookbook.",
    "- AI boundaries: what AI may reduce, draft, review, or repair; what MoonBit records and MoonBook review gates must accept before it becomes durable truth.",
    "",
    "## Update Workflow",
    "",
    "1. Inspect current MoonBit source before editing generated cookbook text.",
    "2. Prefer code-path evidence over vague product language.",
    "3. Update generator functions in the repo, not only generated `.moontown` files.",
    "4. Keep generated wiki pages linked from `wiki/index.md`, `book/moonbook-ui-state.json`, and generated HTML.",
    "5. Run `moon check`, focused cookbook tests, `moon info`, and `moon fmt`.",
    "6. Regenerate the book with `moon run src/cmd/main -- cookbook bootstrap`.",
    "",
    @skill_quality.exploration_quality_contract_section(),
    "",
    "## Acceptance Checklist",
    "",
    "- A new engineer can identify the main records that carry Moontown state.",
    "- The daemon, standing-watch, civic protocol, and projection algorithms are described as step-by-step flows.",
    "- Data files under `.moontown` are tied to the records and phases that read/write them.",
    "- Every AI description includes its durable owner and review/persistence boundary.",
    "- The cookbook skill remains present at `skills/cookbook-generation/SKILL.md`.",
  ].join("\n")
}
