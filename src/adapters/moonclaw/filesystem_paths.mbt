///|
fn resolve_packet_path(packet_path : String) -> String {
  resolve_root_path(packet_path)
}

///|
fn resolve_root_path(path : String) -> String {
  @support.absolute_path_from_cwd(path)
}

///|
fn resolve_home_path(home : String, cwd : String) -> String {
  @support.absolute_path_from_base(cwd, home)
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
