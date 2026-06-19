///|

///|
pub fn default_book_id() -> String {
  "moontown-cookbook"
}

///|
pub fn default_workspace_root() -> String {
  @moonbook.default_workspace_root(default_book_id())
}

///|
pub fn default_manifest_path() -> String {
  ".moontown/cookbook/stable-state.json"
}

///|
pub fn book_entry(workspace_root : String) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id=default_book_id(),
    name="MoonBook / Moontown Cookbook",
    purpose="Canonical generated operating cookbook for Moontown docs, definitions, stable state, and runtime contracts. Moondesk can curate it as the human desktop surface; Moontown consumes it as a stable-state index.",
    workspace_root~,
    memory_scope=BookPrivate,
    tags=["cookbook", "stable-state", "definitions", "moondesk", "operator"],
    skills=["cookbook-generation", "definition-index", "stable-state-review"],
  )
}

///|
pub fn merge_catalog(
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
pub fn manifest(
  workspace_root : String,
  manifest_path : String,
) -> MoontownCookbookManifest {
  {
    book_id: default_book_id(),
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
pub fn cookbook_artifacts() -> Array[CookbookArtifact] {
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
fn cookbook_artifact(
  path : String,
  kind : String,
  owner : String,
  stable_role : String,
  required : Bool,
) -> CookbookArtifact {
  { path, kind, owner, stable_role, required, exists: false }
}

///|
pub fn cookbook_artifact_with_exists(
  artifact : CookbookArtifact,
  exists : Bool,
) -> CookbookArtifact {
  { ..artifact, exists, }
}

///|
pub fn cookbook_manifest_with_artifacts(
  base : MoontownCookbookManifest,
  artifacts : Array[CookbookArtifact],
) -> MoontownCookbookManifest {
  { ..base, artifacts, }
}
