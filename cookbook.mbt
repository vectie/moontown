///|
pub struct CookbookArtifact {
  path : String
  kind : String
  owner : String
  stable_role : String
  required : Bool
  exists : Bool
} derive(Debug, Eq, ToJson)

///|
pub struct MoontownCookbookManifest {
  book_id : String
  title : String
  generated_by : String
  managed_by : String
  consumed_by : String
  workspace_root : String
  manifest_path : String
  artifacts : Array[CookbookArtifact]
} derive(Debug, Eq, ToJson)

///|
pub struct MoontownCookbookStatus {
  book_id : String
  workspace_root : String
  manifest_path : String
  docs_count : Int
  definition_count : Int
  runtime_state_count : Int
  required_missing_count : Int
  required_missing_paths : Array[String]
  ready : Bool
} derive(Debug, Eq, ToJson)

///|
pub fn default_cookbook_book_id() -> String {
  "moontown-cookbook"
}

///|
pub fn default_cookbook_workspace_root() -> String {
  @moonbook.default_workspace_root(default_cookbook_book_id())
}

///|
pub fn default_cookbook_manifest_path() -> String {
  ".moontown/cookbook/stable-state.json"
}

///|
pub async fn bootstrap_moontown_cookbook(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  workspace_root? : String = default_cookbook_workspace_root(),
  manifest_path? : String = default_cookbook_manifest_path(),
) -> String {
  let entry = cookbook_book_entry(workspace_root)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  @moonbook.save_catalog_file(
    book_catalog_path,
    merge_cookbook_catalog(catalog, entry),
  )
  let manifest = cookbook_manifest(workspace_root, manifest_path)
  write_text_file(manifest_path, manifest.to_json().stringify(indent=2))
  write_cookbook_workspace(entry, manifest)
  let status = inspect_moontown_cookbook(workspace_root~, manifest_path~)
  "Bootstrapped MoonBook cookbook `\{entry.id}` at \{workspace_root}; wrote \{manifest_path}; required_missing=\{status.required_missing_count}."
}

///|
pub async fn inspect_moontown_cookbook(
  workspace_root? : String = default_cookbook_workspace_root(),
  manifest_path? : String = default_cookbook_manifest_path(),
) -> MoontownCookbookStatus {
  let manifest = cookbook_manifest(workspace_root, manifest_path)
  let required_missing : Array[String] = []
  let mut docs_count = 0
  let mut definition_count = 0
  let mut runtime_state_count = 0
  for artifact in manifest.artifacts {
    match artifact.kind {
      "doc" => docs_count += 1
      "definition" => definition_count += 1
      "runtime-state" => runtime_state_count += 1
      _ => ()
    }
    if artifact.required && !artifact.exists {
      required_missing.push(artifact.path)
    }
  }
  let workspace_ready = @fs.exists("\{workspace_root}/wiki/index.md") &&
    @fs.exists("\{workspace_root}/book/moonbook-ui-state.json")
  {
    book_id: default_cookbook_book_id(),
    workspace_root,
    manifest_path,
    docs_count,
    definition_count,
    runtime_state_count,
    required_missing_count: required_missing.length(),
    required_missing_paths: required_missing,
    ready: workspace_ready && @fs.exists(manifest_path),
  }
}

///|
pub async fn render_moontown_cookbook_status(
  workspace_root? : String = default_cookbook_workspace_root(),
  manifest_path? : String = default_cookbook_manifest_path(),
) -> String {
  let status = inspect_moontown_cookbook(workspace_root~, manifest_path~)
  let missing = if status.required_missing_paths.is_empty() {
    "- none"
  } else {
    markdown_bullets(status.required_missing_paths)
  }
  [
    "# Moontown Cookbook Status",
    "",
    "- Book: `\{status.book_id}`",
    "- Workspace: `\{status.workspace_root}`",
    "- Manifest: `\{status.manifest_path}`",
    "- Ready: `\{status.ready}`",
    "- Docs tracked: `\{status.docs_count}`",
    "- Definitions tracked: `\{status.definition_count}`",
    "- Runtime states tracked: `\{status.runtime_state_count}`",
    "- Required missing: `\{status.required_missing_count}`",
    "",
    "## Required Missing Paths",
    "",
    missing,
  ].join("\n")
}

///|
fn cookbook_book_entry(workspace_root : String) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id=default_cookbook_book_id(),
    name="MoonBook / Moontown Cookbook",
    purpose="Canonical generated operating cookbook for Moontown docs, definitions, stable state, and runtime contracts. Moondesk can curate it as the human desktop surface; Moontown consumes it as a stable-state index.",
    workspace_root~,
    memory_scope=@core.MemoryScope::BookPrivate,
    tags=["cookbook", "stable-state", "definitions", "moondesk", "operator"],
    skills=["cookbook-generation", "definition-index", "stable-state-review"],
  )
}

///|
fn merge_cookbook_catalog(
  catalog : Array[@moonbook.BookCatalogEntry],
  cookbook : @moonbook.BookCatalogEntry,
) -> Array[@moonbook.BookCatalogEntry] {
  let merged : Array[@moonbook.BookCatalogEntry] = []
  for entry in catalog {
    if entry.id != cookbook.id {
      merged.push(entry)
    }
  }
  merged.push(cookbook)
  merged
}

///|
async fn cookbook_manifest(
  workspace_root : String,
  manifest_path : String,
) -> MoontownCookbookManifest {
  {
    book_id: default_cookbook_book_id(),
    title: "Moontown Stable-State Cookbook",
    generated_by: "MoonBook",
    managed_by: "Moondesk",
    consumed_by: "Moontown",
    workspace_root,
    manifest_path,
    artifacts: cookbook_artifacts(),
  }
}

///|
async fn cookbook_artifacts() -> Array[CookbookArtifact] {
  [
    cookbook_artifact(
      "docs/ARCHITECTURE.md", "doc", "moontown", "layer boundaries and runtime ownership",
      true,
    ),
    cookbook_artifact(
      "docs/USAGE.md", "doc", "moontown", "operator commands and recovery procedures",
      true,
    ),
    cookbook_artifact(
      "docs/WENYU_VALLEY_PRD.md", "doc", "moontown", "product scope and civic town roadmap",
      true,
    ),
    cookbook_artifact(
      "docs/WENYU_BUILDING_PROTOCOL_PLAN.md", "doc", "moontown", "building-as-protocol design",
      true,
    ),
    cookbook_artifact(
      "docs/WENYU_UI_MODULE_SYSTEM.md", "doc", "moontown", "viewport module and output-mode design",
      true,
    ),
    cookbook_artifact(
      "docs/CIVIC_SALON_TEMPLATES.md", "doc", "moontown", "template-driven salon protocol guide",
      true,
    ),
    cookbook_artifact(
      "docs/CIVIC_COMMUNICATION_PATTERNS.md", "doc", "moontown", "reusable civic communication-pattern registry",
      true,
    ),
    cookbook_artifact(
      "docs/TILED_MAP_PIPELINE.md", "doc", "moontown", "tile-map asset and placement pipeline",
      true,
    ),
    cookbook_artifact(
      ".moontown/moonbooks.json", "definition", "moonbook", "book catalog and workspace registry",
      true,
    ),
    cookbook_artifact(
      ".moontown/civic/protocols.json", "definition", "moontown", "building protocol registry",
      true,
    ),
    cookbook_artifact(
      ".moontown/civic/pattern-schedules.json", "definition", "moontown", "recurring communication-pattern schedule registry",
      false,
    ),
    cookbook_artifact(
      ".moontown/standing-goals.json", "definition", "moontown", "long-horizon watcher registry",
      false,
    ),
    cookbook_artifact(
      ".moontown/civic/protocol-status.json", "runtime-state", "moontown", "latest civic protocol status projection",
      false,
    ),
    cookbook_artifact(
      ".moontown/civic/status.json", "runtime-state", "moontown", "latest civic workspace status projection",
      false,
    ),
    cookbook_artifact(
      ".moontown/daemon.json", "runtime-state", "moontown", "daemon tick and heartbeat state",
      false,
    ),
    cookbook_artifact(
      ".moontown/daemon-runtime.json", "runtime-state", "moontown", "daemon supervisor and worker process state",
      false,
    ),
    cookbook_artifact(
      ".moontown/live-autonomy.json", "runtime-state", "moontown", "current live autonomy spine for UI/operator decisions",
      false,
    ),
    cookbook_artifact(
      ".moontown/town-journal.jsonl", "runtime-state", "moontown", "append-only town journal for daemon ticks and live-state transitions",
      false,
    ),
  ]
}

///|
async fn cookbook_artifact(
  path : String,
  kind : String,
  owner : String,
  stable_role : String,
  required : Bool,
) -> CookbookArtifact {
  { path, kind, owner, stable_role, required, exists: @fs.exists(path) }
}

///|
async fn write_cookbook_workspace(
  entry : @moonbook.BookCatalogEntry,
  manifest : MoontownCookbookManifest,
) -> Unit {
  let root = entry.workspace_root
  write_text_file(
    "\{root}/wiki/index.md",
    cookbook_index_markdown(entry, manifest),
  )
  write_text_file(
    "\{root}/wiki/definitions/stable-state.md",
    cookbook_stable_state_markdown(manifest),
  )
  write_text_file(
    "\{root}/wiki/definitions/ownership.md",
    cookbook_ownership_markdown(),
  )
  write_text_file(
    "\{root}/wiki/definitions/book-types.md",
    cookbook_book_types_markdown(),
  )
  write_text_file(
    "\{root}/wiki/definitions/runtime-boundaries.md",
    cookbook_runtime_boundaries_markdown(),
  )
  write_text_file(
    "\{root}/wiki/definitions/live-autonomy-spine.md",
    cookbook_live_autonomy_spine_markdown(),
  )
  write_text_file(
    "\{root}/wiki/history/stable-state-ledger.md",
    cookbook_stable_state_ledger_markdown(manifest),
  )
  write_text_file(
    "\{root}/wiki/operating-procedures/doctor.md",
    cookbook_doctor_markdown(),
  )
  write_text_file(
    "\{root}/wiki/operating-procedures/book-governance.md",
    cookbook_book_governance_markdown(),
  )
  write_text_file(
    "\{root}/raw/bootstrap/COOKBOOK_CONTRACT.md",
    cookbook_contract_markdown(),
  )
  write_text_file(
    "\{root}/schemas/stable-state-manifest.schema.md",
    cookbook_schema_markdown(),
  )
  write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    cookbook_ui_state_json(entry, manifest),
  )
  let html = cookbook_generated_site_html(entry, manifest)
  write_text_file("\{root}/book/Home.html", html)
  write_text_file("\{root}/book/site/generated/index.html", html)
}

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

///|
fn cookbook_ui_state_json(
  entry : @moonbook.BookCatalogEntry,
  manifest : MoontownCookbookManifest,
) -> String {
  let docs = manifest.artifacts.filter(fn(item) { item.kind == "doc" }).length()
  let definitions = manifest.artifacts
    .filter(fn(item) { item.kind == "definition" })
    .length()
  let runtime = manifest.artifacts
    .filter(fn(item) { item.kind == "runtime-state" })
    .length()
  let missing = manifest.artifacts
    .filter(fn(item) { item.required && !item.exists })
    .length()
  let docs_value = json_string("\{docs}")
  let definitions_value = json_string("\{definitions}")
  let runtime_value = json_string("\{runtime}")
  let missing_value = json_string("\{missing}")
  let manifest_path_value = json_string(manifest.manifest_path)
  let builder = StringBuilder::new()
  builder.write_string("{\n")
  builder.write_string("  \"book_id\": \{json_string(entry.id)},\n")
  builder.write_string("  \"title\": \"Moontown Stable-State Cookbook\",\n")
  builder.write_string(
    "  \"summary\": \"Generated control book for docs, definitions, runtime state, and ownership contracts.\",\n",
  )
  builder.write_string("  \"status_chips\": [\n")
  builder.write_string("    {\"label\":\"cookbook\",\"tone\":\"healthy\"},\n")
  builder.write_string(
    "    {\"label\":\"moonbook generated\",\"tone\":\"info\"},\n",
  )
  builder.write_string(
    "    {\"label\":\"moondesk managed\",\"tone\":\"info\"},\n",
  )
  builder.write_string(
    "    {\"label\":\"moontown consumed\",\"tone\":\"review\"}\n",
  )
  builder.write_string("  ],\n")
  builder.write_string("  \"metrics\": [\n")
  builder.write_string(
    "    {\"label\":\"Docs\",\"value\":\{docs_value},\"note\":\"canonical documents\",\"tone\":\"healthy\"},\n",
  )
  builder.write_string(
    "    {\"label\":\"Definitions\",\"value\":\{definitions_value},\"note\":\"machine-readable registries\",\"tone\":\"healthy\"},\n",
  )
  builder.write_string(
    "    {\"label\":\"Runtime state\",\"value\":\{runtime_value},\"note\":\"restart-readable state files\",\"tone\":\"info\"},\n",
  )
  builder.write_string(
    "    {\"label\":\"Missing required\",\"value\":\{missing_value},\"note\":\"drift to repair\",\"tone\":\"review\"}\n",
  )
  builder.write_string("  ],\n")
  builder.write_string("  \"readiness\": [\n")
  builder.write_string(
    "    {\"title\":\"Stable-state manifest\",\"detail\":\{manifest_path_value},\"meta\":\"Generated\"},\n",
  )
  builder.write_string(
    "    {\"title\":\"Cookbook contract\",\"detail\":\"raw/bootstrap/COOKBOOK_CONTRACT.md\",\"meta\":\"Ready\"},\n",
  )
  builder.write_string(
    "    {\"title\":\"Ownership map\",\"detail\":\"wiki/definitions/ownership.md\",\"meta\":\"Ready\"},\n",
  )
  builder.write_string(
    "    {\"title\":\"Doctor procedure\",\"detail\":\"wiki/operating-procedures/doctor.md\",\"meta\":\"Ready\"}\n",
  )
  builder.write_string("  ],\n")
  builder.write_string("  \"review_queue\": [\n")
  builder.write_string(
    "    {\"title\":\"Stable-state drift\",\"detail\":\"wiki/definitions/stable-state.md\",\"meta\":\"Review when required_missing > 0\"}\n",
  )
  builder.write_string("  ],\n")
  builder.write_string("  \"page_families\": [\n")
  builder.write_string(
    "    {\"title\":\"Stable State\",\"detail\":\"wiki/definitions/stable-state.md\",\"meta\":\"Definitions\"},\n",
  )
  builder.write_string(
    "    {\"title\":\"Ownership\",\"detail\":\"wiki/definitions/ownership.md\",\"meta\":\"Boundaries\"},\n",
  )
  builder.write_string(
    "    {\"title\":\"Doctor\",\"detail\":\"wiki/operating-procedures/doctor.md\",\"meta\":\"Procedure\"}\n",
  )
  builder.write_string("  ],\n")
  builder.write_string("  \"journey\": [\n")
  builder.write_string(
    "    {\"title\":\"Cookbook bootstrap\",\"stage\":\"generated\",\"status\":\"review\",\"summary\":\"MoonBook generated a stable-state cookbook workspace and manifest for Moontown.\",\"highlights\":[\"Manifest: \{manifest.manifest_path}\",\"Workspace: \{entry.workspace_root}\",\"Moondesk can curate this book as the human desktop surface.\"]}\n",
  )
  builder.write_string("  ],\n")
  builder.write_string("  \"links\": [\n")
  builder.write_string(
    "    {\"label\":\"Stable state\",\"kind\":\"wiki\",\"url\":\"wiki/definitions/stable-state.md\"},\n",
  )
  builder.write_string(
    "    {\"label\":\"Ownership\",\"kind\":\"wiki\",\"url\":\"wiki/definitions/ownership.md\"},\n",
  )
  builder.write_string(
    "    {\"label\":\"Doctor\",\"kind\":\"wiki\",\"url\":\"wiki/operating-procedures/doctor.md\"}\n",
  )
  builder.write_string("  ]\n")
  builder.write_string("}")
  builder.to_string()
}

///|
fn cookbook_generated_site_html(
  entry : @moonbook.BookCatalogEntry,
  manifest : MoontownCookbookManifest,
) -> String {
  let cards : Array[String] = []
  for artifact in manifest.artifacts {
    cards.push(
      "<article class=\"card\"><h3>\{html_escape(artifact.path)}</h3><p><strong>\{html_escape(artifact.kind)}</strong> / \{html_escape(artifact.owner)}</p><p>\{html_escape(artifact.stable_role)}</p><p>required=\{artifact.required}; exists=\{artifact.exists}</p></article>",
    )
  }
  [
    "<!doctype html>",
    "<html><head><meta charset=\"utf-8\"><title>Moontown Cookbook</title>",
    "<style>body{font-family:Georgia,serif;background:#f7ecd0;color:#2c2114;margin:0;padding:32px}main{max-width:1120px;margin:auto}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:16px}.card{background:#fff8df;border:2px solid #5b4428;padding:16px;box-shadow:4px 4px 0 #c5a86b}code{background:#ead7a1;padding:2px 5px}</style>",
    "</head><body><main>",
    "<p>MoonBook generated / Moondesk managed / Moontown consumed</p>",
    "<h1>Moontown Stable-State Cookbook</h1>",
    "<p>Workspace <code>\{html_escape(entry.workspace_root)}</code>; manifest <code>\{html_escape(manifest.manifest_path)}</code>.</p>",
    "<section class=\"grid\">",
    cards.join("\n"),
    "</section></main></body></html>",
  ].join("\n")
}

///|
fn html_escape(text : String) -> String {
  text
  .replace(old="&", new="&amp;")
  .replace(old="<", new="&lt;")
  .replace(old=">", new="&gt;")
  .replace(old="\"", new="&quot;")
}
