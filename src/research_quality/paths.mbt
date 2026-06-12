///|
async fn workspace_missing_relative_paths(
  root : String,
  relative_paths : Array[String],
) -> Array[String] {
  let missing : Array[String] = []
  for relative in relative_paths {
    if !@fs.exists("\{root}/\{relative}") {
      missing.push(relative)
    }
  }
  missing
}

///|
fn path_basename(value : String) -> String {
  @path.Path::basename(value).to_owned()
}
