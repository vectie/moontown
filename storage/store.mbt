///|
pub struct EventCursor {
  offset : Int
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct Checkpoint {
  run_id : String
  summary : String
  event_count : Int
} derive(Show, Eq, ToJson, FromJson)

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
