///|
fn standing_watch_marker_value(summary : String, key : String) -> String? {
  let key_colon = "\{key}:"
  let key_equals = "\{key}="
  for raw in summary.split("\n") {
    let line = raw.trim().to_owned()
    let lower = line.to_lower()
    if lower.has_prefix(key_colon) {
      return Some(line[key_colon.length():].trim(chars=" `").to_owned())
    } else if lower.has_prefix(key_equals) {
      return Some(line[key_equals.length():].trim(chars=" `").to_owned())
    }
  }
  None
}

///|
fn standing_watch_marker_int(
  summary : String,
  key : String,
  fallback~ : Int,
) -> Int {
  let key_colon = "\{key}:"
  let key_equals = "\{key}="
  for raw in summary.to_lower().split("\n") {
    let line = raw.trim().to_owned()
    if line.has_prefix(key_colon) || line.has_prefix(key_equals) {
      match first_non_negative_int(line) {
        Some(value) => return value
        None => return fallback
      }
    }
  }
  fallback
}

///|
fn first_non_negative_int(text : String) -> Int? {
  let mut seen = false
  let mut value = 0
  for char in text {
    if char >= '0' && char <= '9' {
      value = value * 10 + (char.to_int() - '0'.to_int())
      seen = true
    } else if seen {
      return Some(value)
    }
  }
  if seen {
    Some(value)
  } else {
    None
  }
}

///|
async fn append_standing_watch_record(
  goal_id : String,
  ledger_dir : String,
  record : @core.WatcherRunRecord,
) -> Unit {
  @storage.append_watcher_run_record_file(
    @storage.watcher_ledger_path(goal_id, dir=ledger_dir),
    record,
  )
}

///|
fn record_standing_watch_event(
  state : @core.TownState,
  record : @core.WatcherRunRecord,
) -> Unit {
  state.record_event(
    @core.TownEvent::new(
      id="event-watch-\{record.tick}-\{record.goal_id}",
      kind="standing-watch",
      detail="Standing watch \{record.goal_id} -> \{record.decision.to_string()} for \{record.target_book_id}; next_due_tick=\{record.next_due_tick}; \{record.detail}",
      related_book_id=Some(record.target_book_id),
      related_task_id=record.task_id,
      related_run_id=record.run_id,
    ),
  )
}

///|
fn watcher_ledger_dir_for_snapshot(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    @storage.default_watcher_ledger_dir()
  } else {
    "\{base}/watchers"
  }
}

///|
fn compact_watch_segment(text : String) -> String {
  let builder = StringBuilder::new()
  let mut emitted = 0
  let mut last_dash = false
  for char in text.to_lower() {
    if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') {
      if emitted >= 48 {
        break
      }
      builder.write_char(char)
      emitted += 1
      last_dash = false
    } else if !last_dash && emitted > 0 {
      if emitted >= 48 {
        break
      }
      builder.write_char('-')
      emitted += 1
      last_dash = true
    }
  }
  let value = builder.to_string().trim(chars="-").to_owned()
  if value.is_empty() {
    "standing-goal"
  } else {
    value
  }
}
