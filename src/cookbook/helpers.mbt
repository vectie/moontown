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
