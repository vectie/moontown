///|
fn current_repo_root() -> String {
  match @env.current_dir() {
    Some(dir) => dir
    None => "."
  }
}
