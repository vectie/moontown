///|
fn rewrite_workspace_args(args : Array[String], root : String) -> Array[String] {
  if args.is_empty() {
    return args
  }
  let next = args.copy()
  match next[0] {
    "accept"
    | "tasks"
    | "context"
    | "persist"
    | "catalog"
    | "summary"
    | "health" => if next.length() >= 2 { next[1] = root }
    _ => ()
  }
  next
}

///|
fn resolved_workspace_root(workspace_root : String) -> String {
  resolved_root_path(workspace_root)
}

///|
fn resolved_root_path(path : String) -> String {
  @support.absolute_path_from_cwd(path)
}

///|
fn canonical_generated_site_relative_path() -> String {
  @policy.default_generated_site_projection_path()
}

///|
fn canonical_generated_site_path(root : String) -> String {
  @path.Path(root)
  .join(@path.Path(canonical_generated_site_relative_path()))
  .to_string()
}

///|
async fn ensure_parent_directory(path : String) -> Unit {
  let parent = @path.Path::dirname(path).to_string()
  ensure_directory(parent)
}

///|
async fn ensure_directory(path : String) -> Unit {
  if path == "." || path == "" || @fs.exists(path) {
    return
  }
  let parent = @path.Path::dirname(path).to_string()
  if parent != path {
    ensure_directory(parent)
  }
  @fs.mkdir(path, permission=0o755) catch {
    _ => ()
  }
}
