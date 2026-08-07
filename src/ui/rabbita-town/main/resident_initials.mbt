///|
fn worker_avatar_initials(title : String) -> String {
  let builder = StringBuilder::new()
  let mut count = 0
  for token in title.split(" ") {
    if count >= 2 {
      break
    }
    if worker_avatar_initial_from_token(builder, token.to_owned()) {
      count += 1
    }
  }
  if count == 0 {
    "??"
  } else {
    builder.to_string()
  }
}

///|
fn worker_avatar_initial_from_token(
  builder : StringBuilder,
  token : String,
) -> Bool {
  let trimmed = token.trim()
  if trimmed.is_empty() {
    return false
  }
  for char in trimmed {
    builder.write_char(char)
    return true
  }
  false
}
