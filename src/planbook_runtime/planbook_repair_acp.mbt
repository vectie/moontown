///|
async fn write_planbook_repair_acp_target(workspace_root : String) -> Unit {
  let path = @moonsuite.product_artifact_for_workspace_root(
    workspace_root, "moonclaw", "moonclaw.json",
  )
  let source_root = planbook_repair_source_root()
  let base = @support.read_json_file_or_empty_object(path)
  @support.write_text_file(
    path,
    @codex.upsert_codex_main_target_json(
      base,
      source_root,
      label="Codex PlanBook Repair",
    ).stringify(indent=2),
  )
}
