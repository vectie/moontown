///|
pub async fn read_optional_text(path : String) -> String? {
  if !@fs.exists(path) {
    return None
  }
  Some(@fs.read_file(path).text()) catch {
    _ => None
  }
}

///|
pub async fn read_optional_json_file(path : String) -> Json? {
  match read_optional_text(path) {
    Some(text) => Some(@json.parse(text)) catch { _ => None }
    None => None
  }
}

///|
pub async fn read_json_file_or_empty_object(path : String) -> Json {
  read_optional_json_file(path).unwrap_or(Json::object({}))
}

///|
pub async fn read_text_or_empty(path : String) -> String {
  if !@fs.exists(path) {
    return ""
  }
  @fs.read_file(path).text() catch {
    _ => ""
  }
}

///|
pub async fn list_directory_paths(path : String) -> Array[String] {
  let dir : @fs.Directory = @fs.opendir(path)
  defer dir.close()
  let entries : Array[String] = []
  let prefix = if path.has_suffix("/") { path } else { path + "/" }
  for name in dir.read_all() {
    entries.push(prefix + name)
  }
  entries.sort()
  entries
}

///|
pub async fn write_text_file(path : String, content : String) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(content),
    create=0o644,
    truncate=true,
  )
}

///|
pub async fn write_text_file_if_missing(
  path : String,
  content : String,
) -> Unit {
  let current = if @fs.exists(path) {
    @fs.read_file(path).text() catch {
      _ => ""
    }
  } else {
    ""
  }
  if current.trim().is_empty() {
    write_text_file(path, content)
  }
}

///|
pub async fn ensure_parent_directory(path : String) -> Unit {
  let parent = @path.Path::dirname(path).to_string()
  if parent == "." || parent == "" || @fs.exists(parent) {
    return
  }
  ensure_parent_directory(parent)
  @fs.mkdir(parent, permission=0o755) catch {
    _ => ()
  }
}
