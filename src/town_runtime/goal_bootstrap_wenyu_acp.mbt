///|
async fn ensure_wenyu_codex_acp_target(root : String) -> Unit {
  write_wenyu_codex_acp_target_config("\{root}/moonclaw.json", root)
  write_wenyu_codex_acp_target_config("\{root}/.moonclaw/moonclaw.json", root)
}

///|
async fn write_wenyu_codex_acp_target_config(
  path : String,
  root : String,
) -> Unit {
  let base = @support.read_json_file_or_empty_object(path)
  @support.write_text_file(
    path,
    @codex.upsert_moontown_target_json(base, root).stringify(indent=2),
  )
}
