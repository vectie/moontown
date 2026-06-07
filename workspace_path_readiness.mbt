///|
async fn workspace_missing_relative_paths(
  root : String,
  paths : Array[String],
) -> Array[String] {
  let missing : Array[String] = []
  for path in paths {
    if !@fs.exists("\{root}/\{path}") {
      missing.push(path)
    }
  }
  missing
}

///|
async fn workspace_relative_paths_ready(
  root : String,
  paths : Array[String],
) -> Bool {
  paths.is_empty() || workspace_missing_relative_paths(root, paths).is_empty()
}
