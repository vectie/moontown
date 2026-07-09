///|
fn standing_watch_connected_title(model : Model) -> String {
  let summary = standing_goal_summary(model)
  let count = summary.enabled_count
  if count == 0 {
    "No standing watch active"
  } else if count == 1 {
    match summary.active_goal {
      Some(goal) => "\{goal.title} watch active"
      None => "Standing watch active"
    }
  } else {
    "\{count} standing watches active"
  }
}

///|
fn standing_watch_connected_detail(model : Model) -> String {
  let summary = standing_goal_summary(model)
  let count = summary.enabled_count
  match summary.active_goal {
    Some(goal) => {
      let prefix = if count > 1 {
        "Mayor keeps \{count} standing watches active."
      } else {
        "Mayor keeps this standing watch active."
      }
      "\{prefix} \{standing_watch_target_detail(goal)}"
    }
    None =>
      "Save a standing watch from the request panel to start durable topic monitoring."
  }
}

///|
fn standing_watch_target_detail(goal : StandingGoalSnapshot) -> String {
  match goal.target_book_id {
    Some(_) => "Target book and check frequency are saved."
    None => "Target book can be selected when this watch is reviewed."
  }
}

///|
fn standing_watch_idle_detail(model : Model) -> String {
  standing_goal_next_check_view(model).idle_detail
}
