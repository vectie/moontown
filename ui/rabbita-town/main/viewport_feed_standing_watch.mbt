fn standing_watch_connected_title(model : Model) -> String {
  let summary = standing_goal_summary(model)
  let count = summary.enabled_count
  if count == 0 {
    "No standing watcher connected"
  } else if count == 1 {
    match summary.active_goal {
      Some(goal) => "\{goal.title} watcher is connected"
      None => "Standing watcher is connected"
    }
  } else {
    "\{count} standing watchers connected"
  }
}

///|
fn standing_watch_connected_detail(model : Model) -> String {
  let summary = standing_goal_summary(model)
  let count = summary.enabled_count
  match summary.active_goal {
    Some(goal) => {
      let target = goal.target_book_id.unwrap_or("mayor-selected-book")
      let prefix = if count > 1 {
        "Mayor keeps \{count} standing watches alive through the daemon."
      } else {
        "Mayor keeps this standing watch alive through the daemon."
      }
      "\{prefix} Next configured watch: `\{goal.id}` -> `\{target}` every \{goal.cadence_ticks} ticks."
    }
    None =>
      "Add a standing goal in `.moontown/standing-goals.json` or submit one from the operator panel to start durable topic monitoring."
  }
}

///|
fn standing_watch_idle_detail(model : Model) -> String {
  standing_goal_next_check_view(model).idle_detail
}
