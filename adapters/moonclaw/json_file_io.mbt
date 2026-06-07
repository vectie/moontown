///|
async fn moonclaw_read_optional_text(path : String) -> String? {
  if !@fs.exists(path) {
    return None
  }
  Some(@fs.read_file(path).text()) catch {
    _ => None
  }
}

///|
async fn moonclaw_read_optional_json_file(path : String) -> Json? {
  match moonclaw_read_optional_text(path) {
    Some(text) => Some(@json.parse(text)) catch { _ => None }
    None => None
  }
}

///|
async fn moonclaw_write_text_file(path : String, content : String) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(content),
    create=0o644,
    truncate=true,
  )
}
