///|
pub fn standing_watch_latest_provider_decision_summary(
  history : String,
) -> String? {
  let mut current_id = ""
  let current_lines : Array[String] = []
  for raw in history.split("\n") {
    let line = raw.to_owned()
    if line.has_prefix("### ") {
      if current_id.has_prefix("provider-standing-watch-") {
        return standing_watch_summary_from_history_block(
          current_id, current_lines,
        )
      }
      let heading = line[4:].trim().to_owned()
      current_id = heading
      current_lines.clear()
    } else if current_id != "" {
      current_lines.push(line)
    }
  }
  if current_id.has_prefix("provider-standing-watch-") {
    standing_watch_summary_from_history_block(current_id, current_lines)
  } else {
    None
  }
}

///|
pub fn standing_watch_history_decision_summary_for_task(
  history : String,
  task_id : String,
) -> String? {
  let mut saw_task = false
  let mut current_id = ""
  let current_lines : Array[String] = []
  for raw in history.split("\n") {
    let line = raw.to_owned()
    if line.has_prefix("### ") {
      if saw_task && current_id != "" {
        match
          standing_watch_summary_from_history_block(current_id, current_lines) {
          Some(summary) => return Some(summary)
          None => ()
        }
      }
      let heading = line[4:].trim().to_owned()
      if saw_task && heading.has_prefix("standing-watch-") && heading != task_id {
        return None
      }
      if heading == task_id || saw_task {
        saw_task = true
        current_id = heading
        current_lines.clear()
      }
    } else if saw_task && current_id != "" {
      current_lines.push(line)
    }
  }
  if saw_task && current_id != "" {
    standing_watch_summary_from_history_block(current_id, current_lines)
  } else {
    None
  }
}

///|
pub fn standing_watch_summary_from_history_block(
  block_id : String,
  lines : Array[String],
) -> String? {
  let fields = standing_watch_history_decision_fields(block_id, lines)
  if fields.decision == "unknown" || fields.decision.trim().is_blank() {
    return None
  }
  Some(render_standing_watch_decision_summary(fields))
}

///|
pub fn remove_standing_watch_history_block(
  history : String,
  block_id : String,
) -> String {
  let heading = "### \{block_id}"
  let builder = StringBuilder::new()
  let mut skipping = false
  let mut removed = false
  for raw in history.split("\n") {
    let line = raw.to_owned()
    if line.has_prefix("### ") {
      if line.trim().to_owned() == heading {
        skipping = true
        removed = true
        continue
      }
      skipping = false
    }
    if !skipping {
      builder.write_string(line)
      builder.write_char('\n')
    }
  }
  if removed {
    builder.to_string()
  } else {
    history
  }
}
