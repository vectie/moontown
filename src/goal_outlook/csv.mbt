///|
fn quote(text : String) -> String {
  "\"" + text.replace_all(old="\"", new="\"\"") + "\""
}

///|
fn cell(text : String) -> String {
  text.to_json().stringify()
}

///|
fn optional_text(text : String?) -> String {
  match text {
    Some(value) => cell(value)
    None => "null"
  }
}

///|
fn csv(value : Outlook) -> String {
  let rows = [
    [
      "source_position", "goal_id_json", "title_json", "target_book_id_json", "state",
      "cadence_ticks", "effective_cadence_ticks", "next_due_tick", "occurrence_count",
      "occurrence_ticks_json", "start_tick", "end_tick_exclusive", "source_digest",
    ]
    .map(quote)
    .join(","),
  ]
  for view in value.goals {
    rows.push(
      [
        view.source_position.to_string(),
        cell(view.goal.id),
        cell(view.goal.title),
        optional_text(view.goal.target_book_id),
        view.state,
        view.goal.cadence_ticks.to_string(),
        view.effective_cadence_ticks.to_string(),
        view.goal.next_due_tick.to_string(),
        view.occurrence_count.to_string(),
        view.occurrence_ticks.to_json().stringify(),
        value.start_tick.to_string(),
        value.end_tick_exclusive.to_string(),
        value.source_digest,
      ]
      .map(quote)
      .join(","),
    )
  }
  rows.join("\r\n") + "\r\n"
}

///|
fn count(view : GoalView?) -> String {
  match view {
    Some(value) => value.occurrence_count.to_string()
    None => "null"
  }
}

///|
fn ticks(view : GoalView?) -> String {
  match view {
    Some(value) => value.occurrence_ticks.to_json().stringify()
    None => "null"
  }
}

///|
fn comparison_csv(value : Comparison) -> String {
  let rows = [
    [
      "goal_id_json", "state", "settings_changed", "outlook_changed", "before_count",
      "after_count", "occurrence_delta", "before_ticks_json", "after_ticks_json",
      "start_tick", "end_tick_exclusive", "before_digest", "after_digest",
    ]
    .map(quote)
    .join(","),
  ]
  for change in value.changes {
    rows.push(
      [
        cell(change.goal_id),
        change.state,
        change.settings_changed.to_string(),
        change.outlook_changed.to_string(),
        count(change.before),
        count(change.after),
        change.occurrence_delta.to_string(),
        ticks(change.before),
        ticks(change.after),
        value.start_tick.to_string(),
        value.end_tick_exclusive.to_string(),
        value.before_digest,
        value.after_digest,
      ]
      .map(quote)
      .join(","),
    )
  }
  rows.join("\r\n") + "\r\n"
}
