///|
pub fn cookbook_index_markdown(
  entry : @moonbook.BookCatalogEntry,
  manifest : MoontownCookbookManifest,
) -> String {
  [
    "# MoonTown Stable-State Cookbook",
    "",
    "This MoonBook is the generated operating cookbook for MoonTown. It indexes canonical docs, machine-readable definitions, and restart-readable runtime state so the town has one stable control surface.",
    "",
    "## Ownership",
    "",
    "- MoonBook generates and stores the cookbook workspace.",
    "- MoonDesk manages the human editing, review, and packaging surface.",
    "- MoonTown consumes the cookbook manifest for stable-state checks and operator guidance.",
    "- MoonClaw can update sections only through bounded skills and review contracts.",
    "",
    "## Book",
    "",
    "- Book id: `\{entry.id}`",
    "- Workspace: `\{entry.workspace_root}`",
    "- Manifest: `\{manifest.manifest_path}`",
    "",
    "## Start Here",
    "",
    "- `wiki/definitions/stable-state.md`",
    "- `wiki/definitions/ownership.md`",
    "- `wiki/definitions/book-types.md`",
    "- `wiki/definitions/runtime-boundaries.md`",
    "- `wiki/definitions/live-autonomy-spine.md`",
    "- `wiki/describer/overview.md`",
    "- `wiki/describer/algorithms.md`",
    "- `wiki/describer/data-structures.md`",
    "- `wiki/describer/data-flow.md`",
    "- `wiki/describer/core-features.md`",
    "- `wiki/describer/feature-guide.md`",
    "- `wiki/describer/content-rules.md`",
    "- `skills/cookbook-generation/SKILL.md`",
    "- `wiki/operating-procedures/doctor.md`",
    "- `wiki/operating-procedures/book-governance.md`",
    "- `raw/bootstrap/COOKBOOK_CONTRACT.md`",
  ].join("\n")
}

///|
pub fn cookbook_stable_state_markdown(
  manifest : MoontownCookbookManifest,
) -> String {
  let rows : Array[String] = [
    "|Path|Kind|Owner|Required|Exists|Role|", "| --- | --- | --- | ---: | ---: | --- |",
  ]
  for artifact in manifest.artifacts {
    rows.push(
      "|\{artifact.path}|\{artifact.kind}|\{artifact.owner}|\{artifact.required}|\{artifact.exists}|\{artifact.stable_role}|",
    )
  }
  [
    "# Stable-State Manifest",
    "",
    "The cookbook does not replace source files. It names the canonical files and records whether they currently exist so the Mayor, MoonDesk, and human operator can discuss the same stable state.",
    "",
    rows.join("\n"),
  ].join("\n")
}

///|
pub fn cookbook_ownership_markdown() -> String {
  [
    "# Cookbook Ownership", "", "## MoonBook", "", "MoonBook owns the durable cookbook workspace, generated site, wiki pages, definitions index, review queue, and stable-state projection.",
    "", "## MoonDesk", "", "MoonDesk should present the cookbook as the human desktop for browsing, editing, reviewing, and exporting stable town definitions. It should not become the daemon, scheduler, or worker executor.",
    "", "## MoonTown", "", "MoonTown owns the live control plane. It reads cookbook definitions, checks drift, routes work, supervises daemons, and renders operator-visible state.",
    "", "## MoonClaw", "", "MoonClaw performs bounded cookbook maintenance tasks such as summarizing drift, proposing doc updates, or checking whether a runtime state matches a declared contract.",
  ].join("\n")
}

///|
pub fn cookbook_book_types_markdown() -> String {
  [
    "# Book Types", "", "The cookbook records book-type boundaries so future agents do not collapse every workspace into a research report.",
    "", "| Type | Managed By | Intended Output | Not Allowed To Become |", "| --- | --- | --- | --- |",
    "| Research book | MoonBook + MoonClaw researcher | source-backed reports, evidence matrix, findings, standing watch | generic task log |",
    "| Course book | MoonBook course profile | lessons, exercises, checkpoints, learner artifacts | research report |",
    "| Civic protocol support workspace | MoonBook support profile | schemas when needed, ledgers, review queues, service results, projection-safe state | static UI card, generic report, or the civic place itself |",
    "| Planbook | MoonBook planning profile | implementation plans, acceptance gates, execution evidence, review notes | chat transcript or vague roadmap |",
    "| Cookbook | MoonBook stable-state profile | definitions, operating procedures, runtime boundaries, manifest | source of live daemon authority |",
    "| Operational book | MoonBook keeper profile | private operating memory and review rules | public projection or domain evidence store |",
  ].join("\n")
}

///|
pub fn cookbook_runtime_boundaries_markdown() -> String {
  [
    "# Runtime Boundaries", "", "## MoonTown", "", "MoonTown owns supervision, scheduling, routing, daemon heartbeats, civic protocol ledgers, and town UI projection. It should ask books for work and state, not store domain truth itself.",
    "", "## MoonBook", "", "MoonBook owns each durable workspace: wiki pages, schemas, skills, review queues, generated site projections, and book-local memory rules.",
    "", "## MoonClaw", "", "MoonClaw executes bounded work and returns results, memory candidates, artifacts, blockers, and review requests. It should not own long-term book state.",
    "", "## MoonDesk", "", "MoonDesk is the human desktop surface for browsing, editing, exporting, and curating MoonBook-controlled workspaces. It should not become the daemon or worker executor.",
  ].join("\n")
}

///|
pub fn cookbook_live_autonomy_spine_markdown() -> String {
  [
    "# Live Autonomy Spine",
    "",
    "The live autonomy spine is the current control-plane contract that makes the town feel alive instead of merely configured.",
    "",
    "## Runtime Artifacts",
    "",
    "- \{cookbook_product_path_code("live-autonomy.json")}: current status, accepted updates, no-change cycles, blocked work, due goals, visual projection path, and next actions.",
    "- \{cookbook_product_path_code("town-journal.jsonl")}: append-only journal of live spine refreshes and daemon ticks.",
    "- \{cookbook_product_path_code("visual-projection.json")}: task-to-agent and task-to-building visual projection consumed by the town UI.",
    "",
    "## Lifecycle",
    "",
    "```text",
    "Mayor daemon tick",
    "-> standing goals and civic schedules",
    "-> MoonClaw/MoonBook work",
    "-> accepted/no-change/review/blocked accounting",
    "-> visual projection",
    "-> live autonomy spine",
    "-> town journal",
    "-> operator UI",
    "```",
    "",
    "## Rule",
    "",
    "The spine reports activity; it does not create domain truth. Accepted domain or civic records still belong in MoonBook and must pass the relevant review gates.",
  ].join("\n")
}

///|
pub fn cookbook_stable_state_ledger_markdown(
  manifest : MoontownCookbookManifest,
) -> String {
  [
    "# Stable-State Ledger",
    "",
    "This ledger records the latest bootstrap view of stable-state artifacts. A future MoonClaw reviewer can turn this into richer change history without changing the manifest schema.",
    "",
    "- Generated by: `\{manifest.generated_by}`",
    "- Managed by: `\{manifest.managed_by}`",
    "- Consumed by: `\{manifest.consumed_by}`",
    "- Artifact count: `\{manifest.artifacts.length()}`",
    "",
    "## Current Entry",
    "",
    "- Bootstrap refreshed the cookbook manifest.",
    "- Required docs and definitions are checked as stable-state dependencies.",
    "- Optional runtime files are allowed to appear only after daemon/civic workflows run.",
  ].join("\n")
}

///|
pub fn cookbook_doctor_markdown() -> String {
  [
    "# Cookbook Doctor Procedure", "", "Run the cookbook doctor whenever docs, civic protocols, daemon settings, or MoonDesk handoff formats change.",
    "", "```bash", "moon run src/cmd/main -- cookbook bootstrap", "moon run src/cmd/main -- cookbook status",
    "moon run src/cmd/main -- civic protocols doctor", "moon run src/cmd/main -- civic doctor",
    "```", "", "A clean cookbook means the control book exists, the stable-state manifest exists, and every required source doc or definition is present. Optional runtime files may be absent before the daemon or civic schedules have been started.",
  ].join("\n")
}

///|
pub fn cookbook_book_governance_markdown() -> String {
  [
    "# Book Governance Procedure", "", "Use this when deciding whether a book is healthy enough to trust.",
    "", "## Steps", "", "1. Run `moon run src/cmd/main -- books bootstrap` to ensure canonical registered books have workspaces.",
    "2. Run `moon run src/cmd/main -- books doctor` to check structural readiness.",
    "3. Generate semantic review packets only when human-quality judgment matters.",
    "4. Promote accepted stable definitions back into this cookbook.", "", "## Important Rule",
    "", "Structural readiness is not quality. A book can have every required file and still be shallow, wrong-genre, or not useful.",
  ].join("\n")
}

///|
pub fn cookbook_contract_markdown() -> String {
  [
    "# Cookbook Contract", "", "The cookbook is the stable-state control book for MoonTown.",
    "", "## Rules", "", "- Do not hardcode domain research or civic behavior into the cookbook.",
    "- Treat docs, registries, schemas, and runtime state as separate artifact classes.",
    "- Record missing required artifacts as drift, not as research progress.", "- Let MoonBook generate durable pages; let MoonDesk manage human curation; let MoonTown consume the manifest.",
    "- Any AI rewrite must preserve ownership boundaries and link back to the source artifact it summarizes.",
  ].join("\n")
}

///|
pub fn cookbook_schema_markdown() -> String {
  [
    "# Stable-State Manifest Schema",
    "",
    "Each artifact row contains:",
    "",
    "- `path`: repo or \{cookbook_product_home_code()} path.",
    "- `kind`: `doc`, `definition`, or `runtime-state`.",
    "- `owner`: project responsible for changing the artifact.",
    "- `stable_role`: why the artifact belongs in the cookbook.",
    "- `required`: whether missing path blocks a clean cookbook.",
    "- `exists`: generated existence check at bootstrap time.",
  ].join("\n")
}

///|
pub fn cookbook_describer_overview_markdown() -> String {
  cookbook_codebase_overview_markdown()
}

///|
pub fn cookbook_content_rules_markdown() -> String {
  [
    "# Content-Specific Description Rules", "", "The cookbook should describe different content in different ways. A source document, a runtime state file, a protocol ledger, and a product feature do not need the same narrative shape.",
    "", "## Canonical Docs", "", "Describe docs by intent, stable doctrine, owner, downstream readers, and which implementation files or commands prove the doctrine is live. Link back to the source doc instead of copying it wholesale.",
    "", "## Machine Definitions", "", "Describe definitions as contracts: schema shape, required ids, generated path, bootstrap command, consumer, and drift behavior when the file is missing or stale.",
    "", "## Runtime State", "", "Describe runtime state as a lifecycle: who writes it, when it changes, what fields the UI/operator trusts, what is only telemetry, and how recovery treats missing or stale data.",
    "", "## Civic Features", "", "Describe civic features as building protocols. Each section should name the resident-facing job, the building protocol pattern, the MoonBook support workspace, the MoonClaw skill behavior, ledgers, review gates, and UI projection.",
    "", "## AI Work", "", "Describe AI as bounded protocol work. The AI may classify, compare, synthesize, reduce, draft, or review inside an allowed envelope. It does not become durable truth until MoonBook or a review gate accepts the result.",
    "", "## Procedures", "", "Describe procedures as commands, preconditions, expected files, success evidence, failure evidence, and safe follow-up. A procedure page should be short enough to run during an incident.",
  ].join("\n")
}

///|
pub fn cookbook_feature_guide_markdown() -> String {
  [
    "# MoonTown Feature Guide",
    "",
    "This page is the cookbook's feature-level description of MoonTown. It explains the visible feature, the internal protocol, and how AI is allowed to help.",
    "",
    cookbook_feature_section(
      "Town Shell",
      "A pixel-art civic gateway that makes Wenyu Valley inspectable as places, residents, workers, modules, alerts, and output surfaces.",
      "MoonTown owns the terrain/module registry, runtime projection, placement validation, town counters, and operator controls. MoonBook contributes per-book projection fragments; MoonClaw contributes activity packets that can become visible worker motion or review pressure.",
      [
        "Load module config from `ui/assets/tilemap/modules/wenyu-town-modules.json`.",
        "Combine saved town state, civic status, protocol status, live autonomy, and visual projection.",
        "Render the Rabbita viewport from projection data instead of making browser state the source of truth.",
        "Expose view, editor, and output modes for presentation, module validation, and generated-output browsing.",
      ],
      "AI can propose module descriptions, placement review notes, and output summaries, but durable placement/config still lives in module files and MoonBook projections.",
    ),
    cookbook_feature_section(
      "Mayor And Daemon",
      "The always-on town supervisor that turns goals, schedules, and failures into bounded work or explicit no-change decisions.",
      "MoonTown owns cadence, dispatch budget, daemon health, standing-goal routing, stale execution reconciliation, and restart-readable state under \{cookbook_product_home_code()}.",
      [
        "A tick loads \{cookbook_product_path_code("town.json")}, \{cookbook_product_path_code("service.json")}, and standing-goal registries.",
        "The Mayor dispatches due goals to book-local watcher lanes and records running executions without blocking the tick on long MoonClaw work.",
        "Later ticks reconcile receipts, MoonBook watcher markers, run results, failures, and next due times.",
        "Supervisor state, heartbeat, restart markers, and logs make recovery inspectable after process failure.",
      ],
      "AI appears through Mayor planning and worker proposals, but scheduling authority and final runtime accounting stay in MoonTown state files.",
    ),
    cookbook_feature_section(
      "MoonBook Workspace Layer",
      "The durable memory and publishing layer for research books, course books, PlanBooks, ToolBooks, civic support workspaces, and this cookbook.",
      "MoonBook owns book folders, wiki pages, raw inputs, schemas, generated sites, review queues, memory rules, and projection JSON. MoonTown registers and consumes these books.",
      [
        "Catalog entries identify book id, workspace root, purpose, memory scope, tags, and skills.",
        "Bootstrap commands create required folder shapes and seed contracts.", "Bookkeepers review worker results and decide what is accepted, rejected, or queued.",
        "Generated sites and UI-state JSON become safe surfaces for MoonDesk and the town viewport.",
      ],
      "AI can summarize, draft, research, or maintain book pages through bounded packets; MoonBook decides which outputs become durable book state.",
    ),
    cookbook_feature_section(
      "MoonClaw Worker Layer",
      "The temporary execution layer for tool-heavy research, synthesis, reduction, review, and repair work.",
      "MoonClaw owns role runtimes, skill execution, tool use, result packets, memory candidates, and execution journals. It does not own durable civic truth.",
      [
        "MoonTown or MoonBook creates a bounded task packet with context, skill rules, and output expectations.",
        "MoonClaw imports or runs the proposal and writes structured outputs or blockers.",
        "MoonTown reconciles operational status; MoonBook reviews durable memory candidates and artifacts.",
        "Failed or missing outputs become visible blockers rather than silent progress.",
      ],
      "AI behavior is strongest here: classify, compare, synthesize, reduce, draft, and inspect. The contract keeps it temporary and reviewable.",
    ),
    cookbook_civic_feature_sections(),
    cookbook_feature_section(
      "Live Autonomy Spine",
      "The compact live-state spine that tells the operator whether the town is active, waiting, blocked, or drifting.",
      "MoonTown writes \{cookbook_product_path_code("live-autonomy.json")}, \{cookbook_product_path_code("town-journal.jsonl")}, and \{cookbook_product_path_code("visual-projection.json")} from daemon and civic runtime facts.",
      [
        "Collect recent daemon ticks, active workers, accepted updates, no-change cycles, due goals, blockers, and projection paths.",
        "Separate stable waiting from unresolved failures, transient debt, and review queues.",
        "Append journal entries so long-running behavior is auditable across restarts.",
        "Feed the viewport and operator status without turning the UI into source of truth.",
      ],
      "AI may interpret blockers or propose next actions, but the spine reports accepted runtime evidence and explicit no-change accounting.",
    ),
    cookbook_feature_section(
      "PlanBook And Cookbook",
      "PlanBook controls active implementation decisions; the cookbook records accepted stable state and explains how the system works.",
      "MoonBook generates both book types. MoonTown consumes their manifests, plans, audits, and review status. MoonDesk is the intended human editing surface.",
      [
        "PlanBook stores active plans, acceptance criteria, execution evidence, review notes, and document-protocol fit.",
        "Accepted implementation changes may update source, tests, docs, and then cookbook stable-state pages.",
        "The cookbook indexes docs, definitions, runtime state, ownership boundaries, and feature internals.",
        "Cookbook doctor refreshes the workspace and manifest so drift is visible.",
      ],
      "AI can write plans, review packets, and describer drafts, but promotion to cookbook state should preserve source links and ownership boundaries.",
    ),
  ].join("\n")
}

///|
fn cookbook_civic_feature_sections() -> String {
  [
    cookbook_civic_feature_section(
      "Resident Digital Twins", "Visible resident identities with memory summaries, needs, plans, consent scope, and recent agent activity.",
      "review-council / mixed-memory-backed", "Resident requests and memory candidates enter resident-home or review channels; MoonBook stores private memory and projection-safe summaries; MoonClaw drafts reflections, plans, and profile updates for review.",
      "memory candidate -> resident review -> accepted private note or projection-safe field -> UI avatar/card update",
    ),
    cookbook_civic_feature_section(
      "Policy Hall", "Policy reading becomes cited eligibility help, scenario comparison, and application checklists.",
      "triage-desk / workspace-backed", "Official sources and resident questions enter a policy inbox; MoonClaw extracts requirements and uncertainties; MoonBook persists reviewed policy pages, checklists, and low-confidence review items.",
      "question -> source packet -> cited interpretation -> review gate -> checklist or uncertainty queue",
    ),
    cookbook_civic_feature_section(
      "Contest Express", "Contest participation becomes a readiness workflow with deadlines, material checks, mock-judge feedback, and reminders.",
      "review-council / workspace-backed", "Contest calls and participant materials are grouped by deadline/project; MoonClaw reviews decks and rules; MoonBook stores readiness scores, revision tasks, and champion-wall candidates.",
      "contest call + materials -> completeness check -> mock review -> revision plan -> readiness projection",
    ),
    cookbook_civic_feature_section(
      "Social Square", "Weak ties become consent-aware matches, event plans, follow-ups, or explicit no-change notes.",
      "match-market / ledger-backed", "Profiles, needs, interests, and event signals enter exchange ledgers; MoonClaw reduces them into match candidates or event plans; review gates protect consent and sensitive identity details.",
      "interest packets -> contribution ledger -> AI match reduction -> consent/review gate -> resident or event outbox",
    ),
    cookbook_civic_feature_section(
      "Talent Avenue", "Talent density becomes public-safe cards, skill graph signals, reception notes, and evidence-backed achievements.",
      "match-market / mixed-memory-backed", "Claims, project needs, skills, and evidence are aggregated; MoonClaw verifies or summarizes; MoonBook stores talent graph records and public projection fields only after review.",
      "claim/evidence -> skill edge draft -> verification review -> talent card or operator note",
    ),
    cookbook_civic_feature_section(
      "Vitality Dashboard", "Town activity becomes a health digest that separates real progress from noise.",
      "signal-watch / projection-backed", "Daemon, watcher, worker, projection, and review records are reduced into counters, stale-state warnings, recovery queues, and stable-waiting evidence.",
      "runtime records -> signal digest -> recovery or no-change decision -> operator dashboard",
    ),
    cookbook_civic_feature_section(
      "AI Science Garden", "AI learning becomes tutorial quests, tool trials, examples, workshops, and before/after comparisons.",
      "learning-cohort / workspace-backed", "Learner needs and tool questions enter cohort workspaces; MoonClaw drafts examples and exercises; MoonBook stores tutorials, assessments, progress, and review queues.",
      "learning need -> lesson draft -> exercise/checkpoint -> review -> learner projection",
    ),
    cookbook_civic_feature_section(
      "Physical Bridge", "Virtual requests become confirmation-gated venue, robot, attendance, or offline handoff packets.",
      "incident-bridge / handoff-ledger-backed", "Requests, constraints, device/venue status, and operator approvals move through bridge ledgers; MoonClaw may prepare approved calls or blocker reports but cannot bypass confirmation gates.",
      "request -> risk/constraint check -> human gate -> handoff packet or blocker -> bridge status",
    ),
    cookbook_civic_feature_section(
      "Valley Market", "Needs, offers, points, and rewards become governed exchanges with abuse checks and redemption review.",
      "match-market / ledger-backed", "Offer and need packets are grouped with point ledgers and risk signals; MoonClaw proposes matches or ledger updates; MoonBook records accepted exchanges and review items.",
      "offer/need -> match or points proposal -> abuse/review gate -> ledger update",
    ),
    cookbook_civic_feature_section(
      "Story Radar", "Verified town activity becomes public-safe narratives, achievement broadcasts, or redaction tasks.",
      "story-forge / mixed-memory-backed", "Achievements, events, reviewed facts, and consent labels enter story workspaces; MoonClaw drafts narratives; MoonBook stores claim evidence, redactions, and publishable projections.",
      "reviewed facts -> story draft -> claim/consent review -> broadcast projection",
    ),
  ].join("\n")
}

///|
fn cookbook_feature_section(
  title : String,
  purpose : String,
  ownership : String,
  internal_steps : Array[String],
  ai_behavior : String,
) -> String {
  [
    "## \{title}",
    "",
    "Purpose: \{purpose}",
    "",
    "Ownership: \{ownership}",
    "",
    "Internal flow:",
    markdown_bullets(internal_steps),
    "",
    "AI behavior: \{ai_behavior}",
  ].join("\n")
}

///|
fn cookbook_civic_feature_section(
  title : String,
  purpose : String,
  pattern : String,
  internal_protocol : String,
  evidence_flow : String,
) -> String {
  [
    "## \{title}",
    "",
    "Resident-facing job: \{purpose}",
    "",
    "Protocol shape: \{pattern}.",
    "",
    "Internal protocol: \{internal_protocol}",
    "",
    "Evidence flow:",
    "",
    "```text",
    evidence_flow,
    "```",
    "",
    "AI behavior: MoonClaw uses the building skill to reduce inputs into a module-native output, while MoonTown enforces envelope, schedule, ledgers, privacy, review gates, and allowed destinations.",
  ].join("\n")
}
