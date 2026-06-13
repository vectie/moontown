///|
pub async fn write_moontown_planbook_validation_evidence(
  snapshot_path? : String = @storage.default_snapshot_path(),
  note? : String = "Recorded after Codex/MoonClaw validation pass.",
) -> String {
  let path = "\{planbook_autonomy_base_dir(snapshot_path)}/planbook/latest-validation.md"
  let text = @planbook_policy.validation_evidence_markdown(note, @env.now())
  @support.write_text_file(path, text)
  path
}
