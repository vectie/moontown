///|
pub async fn render_live_autonomy_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  let path = default_live_autonomy_path(snapshot_path~)
  if !@fs.exists(path) {
    ignore(refresh_live_autonomy_spine(snapshot_path~))
    if !@fs.exists(path) {
      return "No live autonomy spine exists at \{path}. Run `moon run cmd/main -- daemon tick` or `moon run cmd/main -- live refresh`."
    }
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ =>
      return "Live autonomy spine exists at \{path}, but it is not valid JSON."
  }
  let decoded = match decode_live_autonomy_spine(parsed) {
    Some(value) => value
    None => {
      ignore(refresh_live_autonomy_spine(snapshot_path~))
      let refreshed = @json.parse(@fs.read_file(path).text()) catch {
        _ =>
          return "Live autonomy spine exists at \{path}, but it is not valid JSON after refresh."
      }
      match decode_live_autonomy_spine(refreshed) {
        Some(value) => value
        None =>
          return "Live autonomy spine exists at \{path}, but it does not match the contract after refresh."
      }
    }
  }
  let current = current_live_autonomy_spine(snapshot_path, decoded)
  let spine = sync_live_autonomy_planbook_counts(current, snapshot_path)
  @live_autonomy_policy.render_live_autonomy_spine_markdown(spine)
}
