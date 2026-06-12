///|
pub fn compact_watch_segment(text : String) -> String {
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

///|
pub fn standing_watch_task_id(goal_id : String, tick : Int) -> String {
  "standing-\{compact_watch_segment(goal_id)}-tick-\{tick}"
}

///|
pub fn standing_watch_task_prefix(goal_id : String) -> String {
  "standing-\{compact_watch_segment(goal_id)}-"
}

///|
pub fn standing_watch_task_tick_prefix(goal_id : String) -> String {
  "\{standing_watch_task_prefix(goal_id)}tick-"
}

///|
pub fn standing_watch_tick_for_goal_task(
  goal : @core.StandingGoal,
  task_id : String,
) -> Int? {
  let prefix = standing_watch_task_tick_prefix(goal.id)
  if task_id.has_prefix(prefix) {
    first_non_negative_int(task_id[prefix.length():].to_owned())
  } else {
    None
  }
}

///|
pub fn standing_goal_for_execution_task(
  goals : Array[@core.StandingGoal],
  task_id : String,
) -> @core.StandingGoal? {
  for goal in goals {
    match standing_watch_tick_for_goal_task(goal, task_id) {
      Some(_) => return Some(goal)
      None => ()
    }
  }
  None
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
