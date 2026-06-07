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

///|
fn json_object_string(object : Map[String, Json], key : String) -> String? {
  match object.get(key) {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
fn json_object_field_summary(
  object : Map[String, Json],
  key : String,
) -> String? {
  match object.get(key) {
    Some(value) => Some(value.stringify())
    None => None
  }
}

///|
fn json_string_field(value : Json, key : String) -> String? {
  match value {
    Object(object) => json_object_string(object, key)
    _ => None
  }
}

///|
fn json_object_copy(value : Json?) -> Map[String, Json] {
  @core.json_object_copy(value)
}
