///|
fn town_synthesis_dir(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown/town-synthesis"
  } else {
    "\{base}/town-synthesis"
  }
}

///|
fn town_synthesis_task_id(goal : String) -> String {
  "town-synthesis-\{town_goal_slug(goal)}"
}

///|
fn town_goal_slug(goal : String) -> String {
  let builder = StringBuilder::new()
  let mut last_dash = false
  let mut emitted = 0
  for char in goal.to_lower() {
    if emitted >= 72 {
      break
    }
    if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') {
      builder.write_char(char)
      last_dash = false
      emitted += 1
    } else if !last_dash && emitted > 0 {
      builder.write_char('-')
      last_dash = true
      emitted += 1
    }
  }
  let slug = builder.to_string().trim(chars="-").to_owned()
  if slug.is_empty() {
    "goal"
  } else {
    slug
  }
}
