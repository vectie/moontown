///|
fn json_escape(text : String) -> String {
  text
  .replace(old="\\", new="\\\\")
  .replace(old="\"", new="\\\"")
  .replace(old="\n", new=" ")
}

///|
fn json_string(text : String) -> String {
  "\"\{json_escape(text)}\""
}

///|
fn json_string_array(items : Array[String]) -> String {
  let encoded : Array[String] = []
  for item in items {
    encoded.push(json_string(item))
  }
  "[\{encoded.join(",")}]"
}
