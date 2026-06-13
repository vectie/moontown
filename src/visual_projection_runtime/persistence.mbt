///|
pub async fn persist_visual_projection(
  state : @core.TownState,
  snapshot_path : String,
  tick? : Int = @visual_projection.visual_projection_tick(state),
) -> Unit {
  let projection = @visual_projection.build_visual_projection(state, tick~)
  write_text_file(
    @visual_projection.default_visual_projection_path(snapshot_path),
    projection.to_json().stringify(),
  )
}

///|
async fn write_text_file(path : String, content : String) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(content),
    create=0o644,
    truncate=true,
  )
}

///|
async fn ensure_parent_directory(path : String) -> Unit {
  let parent = @path.Path::dirname(path).to_string()
  if parent == "." || parent == "" || @fs.exists(parent) {
    return
  }
  ensure_parent_directory(parent)
  @fs.mkdir(parent, permission=0o755) catch {
    _ => ()
  }
}
