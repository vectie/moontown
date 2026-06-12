///|
priv struct CivicServiceWorkspaceReadiness {
  root : String
  workspace_exists : Bool
  missing_required_paths : Array[String]
  schema_ready : Bool
  wiki_ready : Bool
  review_ready : Bool
  projection_ready : Bool
  skill_ready : Bool
  moonclaw_profile_ready : Bool
  operable : Bool
}

///|
async fn inspect_civic_service_workspace_readiness(
  service : @civic.CivicServiceDefinition,
  entry : @moonbook.BookCatalogEntry,
) -> CivicServiceWorkspaceReadiness {
  let root = @moonbook.workspace_root(entry)
  let workspace_exists = @fs.exists(root)
  let missing_required_paths = civic_missing_paths(root, service.target_pages)
  let schema_ready = civic_paths_ready(root, service.schema_pages)
  let wiki_ready = civic_paths_ready(root, service.wiki_pages)
  let review_ready = civic_paths_ready(root, service.review_queues)
  let projection_ready = @fs.exists("\{root}/book/moonbook-ui-state.json")
  let skill_ready = civic_service_skill_ready(service, root)
  let moonclaw_profile_ready = civic_moonclaw_profile_ready(root)
  let operable = workspace_exists &&
    missing_required_paths.is_empty() &&
    schema_ready &&
    wiki_ready &&
    review_ready &&
    projection_ready &&
    skill_ready &&
    moonclaw_profile_ready
  {
    root,
    workspace_exists,
    missing_required_paths,
    schema_ready,
    wiki_ready,
    review_ready,
    projection_ready,
    skill_ready,
    moonclaw_profile_ready,
    operable,
  }
}

///|
async fn civic_service_skill_ready(
  service : @civic.CivicServiceDefinition,
  root : String,
) -> Bool {
  @fs.exists("\{root}/skills/wenyu-civic-service/SKILL.md") &&
  @fs.exists("\{root}/\{service.skill_path}")
}

///|
async fn civic_missing_paths(
  root : String,
  paths : Array[String],
) -> Array[String] {
  @support.workspace_missing_relative_paths(root, paths)
}

///|
async fn civic_paths_ready(root : String, paths : Array[String]) -> Bool {
  @support.workspace_relative_paths_ready(root, paths)
}

///|
async fn civic_moonclaw_profile_ready(root : String) -> Bool {
  let path = "\{root}/moonclaw.jobs.json"
  if !@fs.exists(path) {
    return false
  }
  let text = @fs.read_file(path).text() catch { _ => return false }
  text.contains("\"wenyu_civic_service_worker\"") &&
  text.contains("\"execute_civic_service\"") &&
  text.contains("\"review_civic_service\"")
}
