///|
fn json_string_field(fields : Map[String, Json], key : String) -> String {
  match fields.get(key) {
    Some(String(value)) => value.trim().to_owned()
    _ => ""
  }
}

///|
fn json_string_list_field(
  fields : Map[String, Json],
  key : String,
) -> Array[String] {
  match fields.get(key) {
    Some(Array(values)) =>
      values.filter_map(value => {
        match value {
          String(text) if !text.trim().is_empty() =>
            Some(text.trim().to_owned())
          _ => None
        }
      })
    Some(String(text)) => {
      let values : Array[String] = []
      for raw in text.replace(old=",", new="\n").split("\n") {
        let value = raw.trim().to_owned()
        if !value.is_empty() {
          values.push(value)
        }
      }
      values
    }
    _ => []
  }
}

///|
fn json_int_field(
  fields : Map[String, Json],
  key : String,
  fallback : Int,
  minimum : Int,
  maximum : Int,
) -> Int {
  let value : Int = match fields.get(key) {
    Some(Number(value, ..)) => value.trunc().to_int()
    Some(String(value)) =>
      @strconv.from_str(value.trim()) catch {
        _ => fallback
      }
    _ => fallback
  }
  value.clamp(min=minimum, max=maximum)
}

///|
fn safe_slug(value : String) -> String {
  let builder = StringBuilder::new()
  let mut last_dash = false
  for char in value.to_lower() {
    if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') {
      builder.write_char(char)
      last_dash = false
    } else if !last_dash {
      builder.write_char('-')
      last_dash = true
    }
  }
  let slug = builder.to_string().trim(chars="-").to_owned()
  if slug.is_empty() {
    "request"
  } else {
    slug
  }
}
