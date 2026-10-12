///|
fn selected_ids(bytes : Bytes) -> Array[String] raise {
  guard bytes.length() <= 1048576 else { fail("Selection exceeds 1 MiB") }
  let text = @utf8.decode(bytes) catch {
    _ => fail("Selection must be lossless UTF-8")
  }
  guard @json.parse(text) is Array(items) else {
    fail("Selection must be a JSON array of exact goal ID strings")
  }
  guard items.length() > 0 && items.length() <= 2000 else {
    fail("Select between 1 and 2,000 goals")
  }
  let ids : Array[String] = []
  let seen : Map[String, Bool] = {}
  for item in items {
    guard item is String(id) && !id.trim().is_empty() else {
      fail("Each selected ID must be a nonblank string")
    }
    guard !seen.contains(id) else { fail("Duplicate selected ID: " + id) }
    seen[id] = true
    ids.push(id)
  }
  ids
}

///|
/// Set selected enabled goals' next due ticks to start + selection position *
/// spacing, retaining source order and every other field. Selection is an
/// ordered JSON array of exact IDs. Returns a complete saved-snapshot candidate;
/// this does not install state, simulate execution or guarantee no later overlap.
pub fn stagger(
  bytes : Bytes,
  selection : Bytes,
  start : Int,
  spacing : Int,
) -> Result[String, String] {
  try {
    guard start >= 0 && spacing > 0 else {
      fail("Start must be nonnegative and spacing must be positive")
    }
    let goals = match @goal_table.decode_snapshot(bytes) {
      Ok(value) => value
      Err(error) => fail(error)
    }
    let ids = selected_ids(selection)
    let by_id : Map[String, @core.StandingGoal] = {}
    for goal in goals {
      by_id[goal.id] = goal
    }
    let due : Map[String, Int] = {}
    let mut next = start
    for i, id in ids {
      guard by_id.get(id) is Some(goal) else {
        fail("Selected goal does not exist: " + id)
      }
      guard goal.enabled else { fail("Selected goal is paused: " + id) }
      due[id] = next
      if i + 1 < ids.length() {
        guard spacing <= 2147483647 - next else {
          fail("Selected due ticks exceed signed 32-bit range")
        }
        next += spacing
      }
    }
    let candidate = goals.map(goal => {
      match due.get(goal.id) {
        None => goal
        Some(next_due_tick) =>
          @core.StandingGoal::new(
            id=goal.id,
            title=goal.title,
            prompt=goal.prompt,
            target_book_id=goal.target_book_id,
            cadence_ticks=goal.cadence_ticks,
            next_due_tick~,
            last_run_tick=goal.last_run_tick,
            enabled=goal.enabled,
            source_policy=goal.source_policy,
            quality_threshold=goal.quality_threshold,
          )
      }
    })
    let output = candidate.to_json().stringify() + "\n"
    guard @utf8.encode(output).length() <= 1048576 else {
      fail("Candidate exceeds 1 MiB; no partial candidate is emitted")
    }
    output
  } catch {
    error => Err("\{error}")
  } noraise {
    output => Ok(output)
  }
}
