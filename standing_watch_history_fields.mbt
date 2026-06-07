///|
fn standing_watch_history_field(
  lines : Array[String],
  prefix : String,
) -> String? {
  for line in lines {
    if line.has_prefix(prefix) {
      let value = line[prefix.length():].trim().to_owned()
      if value.has_suffix("`") {
        return Some(value[:value.length() - 1].to_owned())
      }
      return Some(value)
    }
  }
  None
}

///|
fn standing_watch_history_summary_text(lines : Array[String]) -> String {
  let prefix = "- Summary: "
  let builder = StringBuilder::new()
  let mut collecting = false
  let mut wrote = false
  for line in lines {
    if line.has_prefix(prefix) {
      collecting = true
      let value = line[prefix.length():].trim().to_owned()
      if !value.is_blank() {
        builder.write_string(value)
        wrote = true
      }
    } else if collecting {
      let value = line.trim().to_owned()
      if value.is_blank() || line.has_prefix("- ") {
        break
      }
      if wrote {
        builder.write_char('\n')
      }
      builder.write_string(value)
      wrote = true
    }
  }
  builder.to_string()
}

///|
fn standing_watch_decision_text_marks_update(decision : String) -> Bool {
  decision == "update"
}

///|
fn standing_watch_decision_text_marks_book_changed(decision : String) -> Bool {
  standing_watch_decision_text_marks_update(decision) ||
  decision == "needs_review"
}
