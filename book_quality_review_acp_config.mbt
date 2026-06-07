///|
fn book_quality_review_acp_config_json() -> Json {
  let root = @core.absolute_path_from_cwd(".")
  {
    "acp": {
      "targets": {
        "codex-main": {
          "backend": "codex",
          "label": "Codex Book Quality Reviewer",
          "cwd": root,
          "workspace": root,
          "command": resolved_codex_command(),
          "args": resolved_codex_args(),
          "model": "gpt-5",
        },
      },
    },
  }
}
