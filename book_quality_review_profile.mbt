///|
async fn write_book_quality_review_moonclaw_profile(
  review_dir : String,
) -> Unit {
  let root = @book_quality.review_root(review_dir)
  @support.write_text_file(
    "\{root}/moonclaw.jobs.json",
    @book_quality.review_moonclaw_jobs_json().stringify(indent=2),
  )
  let home = "\{root}/.moonclaw"
  let config_path = "\{home}/moonclaw.json"
  let source_root = @core.absolute_path_from_cwd(".")
  @support.write_text_file(
    config_path,
    @book_quality.review_acp_config_json(
      source_root,
      @codex.command(),
      @codex.args(),
      @codex.model(),
    ).stringify(indent=2),
  )
}
