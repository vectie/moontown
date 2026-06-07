///|
async fn moonbook_read_optional_text(path : String) -> String? {
  if !@fs.exists(path) {
    return None
  }
  Some(@fs.read_file(path).text()) catch {
    _ => None
  }
}

///|
async fn moonbook_read_optional_json_file(path : String) -> Json? {
  match moonbook_read_optional_text(path) {
    Some(text) => Some(@json.parse(text)) catch { _ => None }
    None => None
  }
}

///|
async fn write_workspace_text(path : String, content : String) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(content),
    create=0o644,
    truncate=true,
  )
}

///|
async fn write_workspace_text_if_missing(
  path : String,
  content : String,
) -> Unit {
  let existing = if @fs.exists(path) {
    @fs.read_file(path).text() catch {
      _ => ""
    }
  } else {
    ""
  }
  if existing.trim().is_empty() {
    write_workspace_text(path, content)
  }
}
