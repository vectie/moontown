///|
fn json_string(text : String) -> String {
  text.to_json().stringify()
}

///|
fn json_string_array(items : Array[String]) -> String {
  items.to_json().stringify()
}

///|
fn markdown_bullets(values : Array[String]) -> String {
  if values.is_empty() {
    "- none"
  } else {
    values.map(fn(value) { "- `\{value}`" }).join("\n")
  }
}

///|
async fn write_text_file(path : String, content : String) -> Unit {
  let dir = @path.Path::dirname(path).to_string()
  if dir != "." && dir != "" {
    ensure_directory(dir)
  }
  @fs.write_file(
    path,
    @encoding/utf8.encode(content),
    create=0o644,
    truncate=true,
  )
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
