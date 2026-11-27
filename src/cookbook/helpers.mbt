///|
fn json_string(text : String) -> String {
  ToJson::to_json(text).stringify()
}

///|
fn json_string_array(items : Array[String]) -> String {
  ToJson::to_json(items).stringify()
}

///|
fn markdown_bullets(values : Array[String]) -> String {
  if values.is_empty() {
    "- none"
  } else {
    values.map(fn(value) { "- `\{value}`" }).join("\n")
  }
}
