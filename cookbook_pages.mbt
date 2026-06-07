///|
fn cookbook_index_markdown(
  entry : @moonbook.BookCatalogEntry,
  manifest : MoontownCookbookManifest,
) -> String {
  [
    "# Moontown Stable-State Cookbook",
    "",
    "This MoonBook is the generated operating cookbook for Moontown. It indexes canonical docs, machine-readable definitions, and restart-readable runtime state so the town has one stable control surface.",
    "",
    "## Ownership",
    "",
    "- MoonBook generates and stores the cookbook workspace.",
    "- Moondesk manages the human editing, review, and packaging surface.",
    "- Moontown consumes the cookbook manifest for stable-state checks and operator guidance.",
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
    "- `wiki/operating-procedures/doctor.md`",
    "- `wiki/operating-procedures/book-governance.md`",
    "- `raw/bootstrap/COOKBOOK_CONTRACT.md`",
  ].join("\n")
}

///|
fn cookbook_stable_state_markdown(
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
    "The cookbook does not replace source files. It names the canonical files and records whether they currently exist so the Mayor, Moondesk, and human operator can discuss the same stable state.",
    "",
    rows.join("\n"),
  ].join("\n")
}

///|
fn cookbook_ownership_markdown() -> String {
  [
    "# Cookbook Ownership", "", "## MoonBook", "", "MoonBook owns the durable cookbook workspace, generated site, wiki pages, definitions index, review queue, and stable-state projection.",
    "", "## Moondesk", "", "Moondesk should present the cookbook as the human desktop for browsing, editing, reviewing, and exporting stable town definitions. It should not become the daemon, scheduler, or worker executor.",
    "", "## Moontown", "", "Moontown owns the live control plane. It reads cookbook definitions, checks drift, routes work, supervises daemons, and renders operator-visible state.",
    "", "## MoonClaw", "", "MoonClaw performs bounded cookbook maintenance tasks such as summarizing drift, proposing doc updates, or checking whether a runtime state matches a declared contract.",
  ].join("\n")
}

///|
fn cookbook_book_types_markdown() -> String {
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
fn cookbook_runtime_boundaries_markdown() -> String {
  [
    "# Runtime Boundaries", "", "## Moontown", "", "Moontown owns supervision, scheduling, routing, daemon heartbeats, civic protocol ledgers, and town UI projection. It should ask books for work and state, not store domain truth itself.",
    "", "## MoonBook", "", "MoonBook owns each durable workspace: wiki pages, schemas, skills, review queues, generated site projections, and book-local memory rules.",
    "", "## MoonClaw", "", "MoonClaw executes bounded work and returns results, memory candidates, artifacts, blockers, and review requests. It should not own long-term book state.",
    "", "## Moondesk", "", "Moondesk is the human desktop surface for browsing, editing, exporting, and curating MoonBook-controlled workspaces. It should not become the daemon or worker executor.",
  ].join("\n")
}

///|
fn cookbook_live_autonomy_spine_markdown() -> String {
  [
    "# Live Autonomy Spine", "", "The live autonomy spine is the current control-plane contract that makes the town feel alive instead of merely configured.",
    "", "## Runtime Artifacts", "", "- `.moontown/live-autonomy.json`: current status, accepted updates, no-change cycles, blocked work, due goals, visual projection path, and next actions.",
    "- `.moontown/town-journal.jsonl`: append-only journal of live spine refreshes and daemon ticks.",
    "- `.moontown/visual-projection.json`: task-to-agent and task-to-building visual projection consumed by the town UI.",
    "", "## Lifecycle", "", "```text", "Mayor daemon tick", "-> standing goals and civic schedules",
    "-> MoonClaw/MoonBook work", "-> accepted/no-change/review/blocked accounting",
    "-> visual projection", "-> live autonomy spine", "-> town journal", "-> operator UI",
    "```", "", "## Rule", "", "The spine reports activity; it does not create domain truth. Accepted domain or civic records still belong in MoonBook and must pass the relevant review gates.",
  ].join("\n")
}

///|
fn cookbook_stable_state_ledger_markdown(
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
fn cookbook_doctor_markdown() -> String {
  [
    "# Cookbook Doctor Procedure", "", "Run the cookbook doctor whenever docs, civic protocols, daemon settings, or Moondesk handoff formats change.",
    "", "```bash", "moon run cmd/main -- cookbook bootstrap", "moon run cmd/main -- cookbook status",
    "moon run cmd/main -- civic protocols doctor", "moon run cmd/main -- civic doctor",
    "```", "", "A clean cookbook means the control book exists, the stable-state manifest exists, and every required source doc or definition is present. Optional runtime files may be absent before the daemon or civic schedules have been started.",
  ].join("\n")
}

///|
fn cookbook_book_governance_markdown() -> String {
  [
    "# Book Governance Procedure", "", "Use this when deciding whether a book is healthy enough to trust.",
    "", "## Steps", "", "1. Run `moon run cmd/main -- books bootstrap` to ensure canonical registered books have workspaces.",
    "2. Run `moon run cmd/main -- books doctor` to check structural readiness.",
    "3. Generate semantic review packets only when human-quality judgment matters.",
    "4. Promote accepted stable definitions back into this cookbook.", "", "## Important Rule",
    "", "Structural readiness is not quality. A book can have every required file and still be shallow, wrong-genre, or not useful.",
  ].join("\n")
}

///|
fn cookbook_contract_markdown() -> String {
  [
    "# Cookbook Contract", "", "The cookbook is the stable-state control book for Moontown.",
    "", "## Rules", "", "- Do not hardcode domain research or civic behavior into the cookbook.",
    "- Treat docs, registries, schemas, and runtime state as separate artifact classes.",
    "- Record missing required artifacts as drift, not as research progress.", "- Let MoonBook generate durable pages; let Moondesk manage human curation; let Moontown consume the manifest.",
    "- Any AI rewrite must preserve ownership boundaries and link back to the source artifact it summarizes.",
  ].join("\n")
}

///|
fn cookbook_schema_markdown() -> String {
  [
    "# Stable-State Manifest Schema", "", "Each artifact row contains:", "", "- `path`: repo or `.moontown` path.",
    "- `kind`: `doc`, `definition`, or `runtime-state`.", "- `owner`: project responsible for changing the artifact.",
    "- `stable_role`: why the artifact belongs in the cookbook.", "- `required`: whether missing path blocks a clean cookbook.",
    "- `exists`: generated existence check at bootstrap time.",
  ].join("\n")
}
