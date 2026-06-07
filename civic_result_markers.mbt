///|
fn civic_marker_value(
  summary : String,
  key : String,
  fallback~ : String,
) -> String {
  let lower_key = key.to_lower()
  let key_colon = "\{lower_key}:"
  let key_equals = "\{lower_key}="
  for raw in summary.split("\n") {
    let line = raw.trim().to_owned()
    let lower = line.to_lower()
    if lower.has_prefix(key_colon) {
      return line[key_colon.length():].trim(chars=" `").to_owned()
    } else if lower.has_prefix(key_equals) {
      return line[key_equals.length():].trim(chars=" `").to_owned()
    }
  }
  fallback
}

///|
fn civic_marker_int(summary : String, key : String, fallback~ : Int) -> Int {
  let value = civic_marker_value(summary, key, fallback="")
  match first_non_negative_int(value) {
    Some(parsed) => parsed
    None => fallback
  }
}
