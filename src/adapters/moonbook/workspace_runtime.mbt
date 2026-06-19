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
fn result_temp_path(task_id : String) -> String {
  resolved_root_path(".moontown/book-results/\{task_id}.json")
}

///|
async fn save_result_file(path : String, result : BookResult) -> Unit {
  write_workspace_text(path, result.to_json().stringify())
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
        "moon",
        ["run", "cmd/main", "--", "wiki", "init", root],
        cwd=Some(resolved_moonbook_root),
      ),
    )
    ensure_workspace_build_dirs(root)
  }
  ignore(
    @integration.run_checked(
      "moon",
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
    "moon",
    [
      "run",
      "cmd/main",
      "--",
      "wiki",
      "book",
      ..rewrite_workspace_args(args, root),
    ],
    cwd=Some(resolved_moonbook_root),
  )
}

///|
async fn ensure_workspace_build_dirs(root : String) -> Unit {
  ensure_directory("\{root}/book/site/generated")
}
