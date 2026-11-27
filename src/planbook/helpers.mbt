///|
fn json_string(value : String) -> String {
  ToJson::to_json(value).stringify()
}

///|
fn html_escape(text : String) -> String {
  text
  .replace(old="&", new="&amp;")
  .replace(old="<", new="&lt;")
  .replace(old=">", new="&gt;")
  .replace(old="\"", new="&quot;")
}
