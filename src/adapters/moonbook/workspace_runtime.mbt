///|
async fn resolved_generated_site_index_after_build(root : String) -> String {
  let candidates = [
    canonical_generated_site_relative_path(),
    "site/generated/index.html",
    "site/index.html",
  ]
  for relative in candidates {
    let path = moonbook_adapter_path(root)
      .join(moonbook_adapter_path(relative))
      .to_string()
    let exists = @fs.exists(path) catch { _ => false }
    if exists {
      return path
    }
  }
  canonical_generated_site_path(root)
}

///|
fn moonbook_moon_command() -> String {
  let configured = @sys.get_env_var("MOON").unwrap_or("")
  if configured.trim().is_empty() {
    "moon"
  } else {
    configured
  }
}

///|
fn result_temp_path(task_id : String) -> String {
  resolved_root_path(
    @storage.moontown_product_artifact(
      "book-results/\{safe_result_temp_name(task_id)}.json",
    ),
  )
}

///|
fn safe_result_temp_name(task_id : String) -> String {
  task_id
  .replace(old="/", new="-")
  .replace(old="\\", new="-")
  .replace(old=":", new="-")
  .replace(old=" ", new="-")
}

///|
async fn save_result_payload_file(path : String, payload : Json) -> Unit {
  write_workspace_text(path, payload.stringify())
}

///|
async fn ensure_workspace(
  entry : BookCatalogEntry,
  moonbook_root? : String = default_moonbook_root(),
) -> Unit {
  let root = resolved_workspace_root(entry.workspace_root)
  let resolved_moonbook_root = resolved_root_path(moonbook_root)
  let marker = "\{root}/wiki/index.md"
  if @fs.exists(marker) {
    ensure_workspace_build_dirs(root)
    ensure_book_provider_manifest(root, resolved_moonbook_root)
    ensure_moontown_research_pack(root, entry)
    let jobs_path = "\{root}/moonclaw.jobs.json"
    if @fs.exists(jobs_path) {
      return
    }
  } else {
    ignore(
      @integration.run_checked(
        moonbook_moon_command(),
        ["run", "cmd/main", "--", "wiki", "init", root],
        cwd=Some(resolved_moonbook_root),
      ),
    )
    ensure_workspace_build_dirs(root)
  }
  ignore(
    @integration.run_checked(
      moonbook_moon_command(),
      ["run", "cmd/main", "--", "wiki", "enable", "moonclaw", root],
      cwd=Some(resolved_moonbook_root),
    ),
  )
  ensure_book_provider_manifest(root, resolved_moonbook_root)
  ensure_moontown_research_pack(root, entry)
}

///|
async fn run_book_json_command(
  entry : BookCatalogEntry,
  args : Array[String],
  moonbook_root? : String = default_moonbook_root(),
) -> Json {
  ensure_workspace(entry, moonbook_root~)
  let root = resolved_workspace_root(entry.workspace_root)
  let resolved_moonbook_root = resolved_root_path(moonbook_root)
  @integration.run_json(
    moonbook_moon_command(),
    [
      "run",
      "cmd/main",
      "--",
      "wiki",
      "extension",
      ..rewrite_workspace_args(args, root),
    ],
    cwd=Some(resolved_moonbook_root),
  )
}

///|
async fn ensure_workspace_build_dirs(root : String) -> Unit {
  ensure_directory("\{root}/book/site/generated")
}
