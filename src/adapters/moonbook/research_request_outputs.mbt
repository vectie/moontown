///|
fn research_raw_output_bullets() -> String {
  @research_policy.raw_bootstrap_artifact_bullets("  ").join("\n")
}

///|
fn research_materialization_output_bullets() -> String {
  [
    "  - at least one substantive page under `wiki/sources/`", "  - at least one substantive page under `wiki/entities/`",
    "  - at least one substantive page under `wiki/concepts/`", "  - at least one substantive page under `wiki/synthesis/`",
    "  - `wiki/index.md` and `wiki/log.md` updated consistently",
  ].join("\n")
}
