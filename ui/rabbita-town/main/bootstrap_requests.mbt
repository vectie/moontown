///|
fn parse_bootstrap_standing_goals() -> Array[StandingGoalSnapshot] {
  parse_standing_goals_json(load_bootstrap_standing_goals_json())
}

///|
fn parse_bootstrap_watcher_records() -> Array[WatcherRunRecordSnapshot] {
  parse_watcher_records_json(load_bootstrap_watcher_records_json())
}

///|
fn parse_bootstrap_operator_requests() -> Array[OperatorRequestSnapshot] {
  parse_operator_requests_json(load_bootstrap_operator_requests_json())
}

///|
fn parse_standing_goals_json(text : String) -> Array[StandingGoalSnapshot] {
  let parsed = @json.parse(text) catch { _ => return [] }
  @json.from_json(parsed) catch {
    _ => []
  }
}

///|
fn parse_watcher_records_json(text : String) -> Array[WatcherRunRecordSnapshot] {
  let parsed = @json.parse(text) catch { _ => return [] }
  @json.from_json(parsed) catch {
    _ => []
  }
}

///|
fn parse_operator_requests_json(
  text : String,
) -> Array[OperatorRequestSnapshot] {
  let parsed = @json.parse(text) catch { _ => return [] }
  @json.from_json(parsed) catch {
    _ => []
  }
}
