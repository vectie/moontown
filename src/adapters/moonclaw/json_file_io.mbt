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
async fn moonclaw_optional_file_size(path : String) -> Int64? {
  if !@fs.exists(path) {
    return None
  }
  let file = @fs.open(path, mode=ReadOnly) catch { _ => return None }
  defer file.close()
  Some(file.size()) catch {
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
    create_mode=CreateOrTruncate,
    permission=0o644,
  )
}
