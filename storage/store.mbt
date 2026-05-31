///|
pub struct EventCursor {
  offset : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub impl Show for EventCursor with fn output(
  self : EventCursor,
  logger : &Logger,
) -> Unit {
  logger.write_string("EventCursor(offset=\{self.offset})")
}

///|
pub struct Checkpoint {
  run_id : String
  summary : String
  event_count : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub impl Show for Checkpoint with fn output(self : Checkpoint, logger : &Logger) -> Unit {
  logger.write_string(
    "Checkpoint(run_id=\{self.run_id}, summary=\{self.summary}, event_count=\{self.event_count})",
  )
}

///|
pub struct TownSnapshot {
  town : @core.TownState
  event_count : Int
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn snapshot_of(town : @core.TownState) -> TownSnapshot {
  { town, event_count: town.events.length() }
}

///|
pub fn empty_checkpoint(run_id : String) -> Checkpoint {
  { run_id, summary: "not started", event_count: 0 }
}

///|
pub fn describe_snapshot(snapshot : TownSnapshot) -> String {
  "\{snapshot.town.config.name}: books=\{snapshot.town.books.length()} workers=\{snapshot.town.workers.length()} tasks=\{snapshot.town.tasks.length()} events=\{snapshot.event_count}"
}

///|
pub fn default_snapshot_path() -> String {
  ".moontown/town.json"
}

///|
pub fn default_standing_goal_path() -> String {
  ".moontown/standing-goals.json"
}

///|
pub fn default_watcher_ledger_dir() -> String {
  ".moontown/watchers"
}

///|
pub fn watcher_ledger_path(
  goal_id : String,
  dir? : String = default_watcher_ledger_dir(),
) -> String {
  "\{dir}/\{safe_watcher_goal_id(goal_id)}.jsonl"
}

///|
pub fn default_standing_goals() -> Array[@core.StandingGoal] {
  [
    @core.StandingGoal::new(
      id="watch-opc-news",
      title="Track One Person Company news",
      prompt="Research the latest news, evidence, risks, examples, and strategic implications about One Person Company (OPC). Use web search first, fetch and screen sources, update the research-opc book wiki with source cards, claims, timeline notes, and a short digest.",
      target_book_id=Some("research-opc"),
      cadence_ticks=60,
      next_due_tick=0,
      source_policy="web-first",
      quality_threshold=85,
    ),
  ]
}

///|
pub async fn save_standing_goals_file(
  path : String,
  goals : Array[@core.StandingGoal],
) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(goals.to_json().stringify()),
    create=0o644,
    truncate=true,
  )
}

///|
pub async fn load_standing_goals_file(
  path : String,
) -> Array[@core.StandingGoal]? {
  if !@fs.exists(path) {
    return None
  }
  let text = @fs.read_file(path).text()
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
pub async fn load_or_create_standing_goals(
  path? : String = default_standing_goal_path(),
) -> Array[@core.StandingGoal] {
  match load_standing_goals_file(path) {
    Some(goals) => goals
    None => {
      let goals = default_standing_goals()
      save_standing_goals_file(path, goals)
      goals
    }
  }
}

///|
pub async fn append_watcher_run_record_file(
  path : String,
  record : @core.WatcherRunRecord,
) -> Unit {
  ensure_parent_directory(path)
  let previous = if @fs.exists(path) {
    @fs.read_file(path).text() catch {
      _ => ""
    }
  } else {
    ""
  }
  let prefix = if previous.is_empty() || previous.has_suffix("\n") {
    previous
  } else {
    "\{previous}\n"
  }
  let line = record.to_json().stringify()
  @fs.write_file(
    path,
    @encoding/utf8.encode("\{prefix}\{line}\n"),
    create=0o644,
    truncate=true,
  )
}

///|
pub async fn load_watcher_run_records_file(
  path : String,
) -> Array[@core.WatcherRunRecord] {
  let records : Array[@core.WatcherRunRecord] = []
  if !@fs.exists(path) {
    return records
  }
  let text = @fs.read_file(path).text() catch { _ => return records }
  for raw in text.split("\n") {
    let line = raw.trim().to_owned()
    if line.is_empty() {
      continue
    }
    let parsed = @json.parse(line) catch { _ => continue }
    let record : @core.WatcherRunRecord = @json.from_json(parsed) catch {
      _ => continue
    }
    records.push(record)
  }
  records
}

///|
pub async fn load_watcher_run_records(
  goal_id : String,
  dir? : String = default_watcher_ledger_dir(),
) -> Array[@core.WatcherRunRecord] {
  load_watcher_run_records_file(watcher_ledger_path(goal_id, dir~))
}

///|
pub fn consecutive_no_change_count(
  records : Array[@core.WatcherRunRecord],
) -> Int {
  let mut count = 0
  for index = records.length(); index > 0; index = index - 1 {
    if records[index - 1].decision == @core.WatcherDecisionKind::NoChange {
      count += 1
    } else {
      break
    }
  }
  count
}

///|
pub async fn save_snapshot_file(path : String, snapshot : TownSnapshot) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(snapshot.to_json().stringify()),
    create=0o644,
    truncate=true,
  )
}

///|
pub async fn load_snapshot_file(path : String) -> TownSnapshot? {
  if !@fs.exists(path) {
    return None
  }
  let text = @fs.read_file(path).text()
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
pub async fn load_or_create_snapshot(
  path : String,
  seed : () -> @core.TownState,
) -> TownSnapshot {
  match load_snapshot_file(path) {
    Some(snapshot) => snapshot
    None => {
      let snapshot = snapshot_of(seed())
      save_snapshot_file(path, snapshot)
      snapshot
    }
  }
}

///|
async fn ensure_parent_directory(path : String) -> Unit {
  let parent = @path.Path::dirname(path).to_string()
  if parent == "." || parent == "" || @fs.exists(parent) {
    return
  }
  ensure_parent_directory(parent)
  @fs.mkdir(parent, permission=0o755) catch {
    _ => ()
  }
}

///|
fn safe_watcher_goal_id(goal_id : String) -> String {
  let builder = StringBuilder::new()
  let mut emitted = 0
  let mut last_dash = false
  for char in goal_id.to_lower() {
    if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') {
      builder.write_char(char)
      emitted += 1
      last_dash = false
    } else if !last_dash && emitted > 0 {
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
