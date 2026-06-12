///|
fn json_string(value : String) -> String {
  value.to_json().stringify()
}

///|
fn html_escape(text : String) -> String {
  text
  .replace(old="&", new="&amp;")
  .replace(old="<", new="&lt;")
  .replace(old=">", new="&gt;")
  .replace(old="\"", new="&quot;")
}
