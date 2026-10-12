///|
fn policy() -> String {
  "Cadence-only local snapshot projection. Window is [start_tick,end_tick_exclusive), in scheduler ticks, not dates or minutes. Each enabled overdue goal occurs once at start; later occurrences assume immediate successful dispatch followed by the core cadence (minimum 1 tick). Paused goals never occur. This does not simulate active tasks, capacity, material-change checks, review debt, failed/deferred/review outcomes or actual daemon execution. Shared ticks show projected clustering, not a capacity violation. No goal, Book, daemon or provider is changed or started."
}

///|
fn digest(bytes : Bytes) -> String {
  "sha256:" + @crypto.bytes_to_hex_string(@crypto.sha256(bytes))
}

///|
fn project(bytes : Bytes, start : Int, end : Int) -> Outlook raise {
  guard start >= 0 && end > start && end - start <= 1000000 else {
    fail(
      "Choose a nonnegative start and an exclusive end 1 to 1,000,000 ticks later, within signed 32-bit range",
    )
  }
  let goals = match @goal_table.decode_snapshot(bytes) {
    Ok(value) => value
    Err(error) => fail(error)
  }
  let views : Array[GoalView] = []
  let events : Array[(Int, Int)] = []
  for i, goal in goals {
    let cadence = if goal.cadence_ticks < 1 { 1 } else { goal.cadence_ticks }
    let state = if !goal.enabled {
      "paused"
    } else if goal.next_due_tick < start {
      "overdue"
    } else if goal.is_due(start) {
      "due_now"
    } else if goal.next_due_tick < end {
      "scheduled"
    } else {
      "beyond_window"
    }
    let ticks : Array[Int] = []
    if goal.enabled {
      let first = if goal.next_due_tick < start {
        start
      } else {
        goal.next_due_tick
      }
      for tick = first; tick < end; {
        guard events.length() < 10000 else {
          fail(
            "Projection exceeds 10,000 occurrences; narrow the window or goal selection",
          )
        }
        ticks.push(tick)
        events.push((tick, i + 1))
        // Compare before addition: no signed-Int wrap near the final tick.
        if cadence >= end - tick {
          break
        }
        continue tick + cadence
      }
    }
    views.push({
      source_position: i + 1,
      goal,
      state,
      effective_cadence_ticks: cadence,
      occurrence_count: ticks.length(),
      occurrence_ticks: ticks,
    })
  }
  events.sort_by((left, right) => {
    let by_tick = left.0.compare(right.0)
    if by_tick == 0 {
      left.1.compare(right.1)
    } else {
      by_tick
    }
  })
  let slots : Array[Slot] = []
  for (tick, position) in events {
    if slots.length() > 0 && slots[slots.length() - 1].tick == tick {
      slots[slots.length() - 1].goal_positions.push(position)
    } else {
      slots.push({ tick, goal_positions: [position], })
    }
  }
  let mut shared = 0
  let mut peak = 0
  for slot in slots {
    let count = slot.goal_positions.length()
    if count > 1 {
      shared += 1
    }
    if count > peak {
      peak = count
    }
  }
  {
    contract: "moontown.goal-outlook.v1",
    policy: policy(),
    source_digest: digest(bytes),
    source_size_bytes: bytes.length(),
    start_tick: start,
    end_tick_exclusive: end,
    occurrence_count: events.length(),
    occupied_tick_count: slots.length(),
    shared_tick_count: shared,
    peak_goals_at_tick: peak,
    goals: views,
    slots,
  }
}

///|
fn bounded(text : String) -> String raise {
  guard @utf8.encode(text).length() <= 4 * 1048576 else {
    fail("Output exceeds 4 MiB; narrow the inputs")
  }
  text
}

///|
/// Explore a saved StandingGoal snapshot over a half-open scheduler tick window.
/// Returns full JSON with chronological slots, or CSV with one row per goal.
pub fn report(
  bytes : Bytes,
  start : Int,
  end : Int,
  format~ : String,
) -> Result[String, String] {
  try {
    guard format == "json" || format == "csv" else {
      fail("Choose json or csv")
    }
    let outlook = project(bytes, start, end)
    bounded(
      if format == "json" {
        outlook.to_json().stringify() + "\n"
      } else {
        csv(outlook)
      },
    )
  } catch {
    error => Err("\{error}")
  } noraise {
    output => Ok(output)
  }
}
