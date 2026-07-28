///|
async fn write_book_quality_review_moonclaw_profile(
  review_dir : String,
) -> Unit {
  let root = @book_quality.review_root(review_dir)
  @support.write_text_file(
    "\{root}/moonclaw.jobs.json",
    @book_quality.review_moonclaw_jobs_json(@codex.codex_main_target_id()).stringify(
      indent=2,
    ),
  )
  let config_path = @book_quality.moonclaw_config_path(review_dir)
  let source_root = @support.absolute_path_from_cwd(".")
  let base = @support.read_json_file_or_empty_object(config_path)
  @support.write_text_file(
    config_path,
    @codex.upsert_codex_main_target_json(
      base,
      source_root,
      label="Codex Book Quality Reviewer",
    ).stringify(indent=2),
  )
}

///|
fn book_quality_review_acp_config_json(
  source_root : String,
  command : String,
  args : Array[String],
  model : String,
) -> Json {
  let targets : Map[String, Json] = {}
  targets[@codex.codex_main_target_id()] = @codex.codex_acp_target_json(
    source_root, "Codex Book Quality Reviewer", command, args, model,
  )
  { "acp": { "targets": Json::object(targets) } }
}
