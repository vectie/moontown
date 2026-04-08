///|
pub struct EventCursor {
  offset : Int
} derive(Show, Eq)

///|
pub struct Checkpoint {
  run_id : String
  summary : String
  event_count : Int
} derive(Show, Eq)

///|
pub struct TownSnapshot {
  town : @core.TownState
  event_count : Int
} derive(Show, Eq)

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
