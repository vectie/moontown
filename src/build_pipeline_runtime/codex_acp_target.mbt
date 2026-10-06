///|
async fn ensure_wenyu_codex_acp_target(root : String) -> Unit {
  write_wenyu_codex_acp_target_config(
    @moonsuite.product_artifact_for_workspace_root(
      root, "moonclaw", "moonclaw.json",
    ),
    root,
  )
}

///|
async fn write_wenyu_codex_acp_target_config(
  path : String,
  root : String,
) -> Unit {
  let base = if @fs.exists(path) {
    @json.parse(@fs.read_file(path).text())
  } else {
    Json::object({})
  }
  if base is { "acp": { "targets": Object(targets), .. }, .. } &&
    targets.contains(@codex.moontown_target_id()) {
    return
  }
  @support.write_text_file(
    path,
    @codex.upsert_moontown_target_json(base, root).stringify(indent=2),
  )
}
