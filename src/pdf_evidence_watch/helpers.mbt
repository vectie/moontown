///|
fn markdown_bullets(values : Array[String]) -> String {
  values.map(fn(value) { "- \{value}" }).join("\n")
}

///|
pub fn merge_single_book(
  catalog : Array[@moonbook.BookCatalogEntry],
  book : @moonbook.BookCatalogEntry,
) -> Array[@moonbook.BookCatalogEntry] {
  let merged : Array[@moonbook.BookCatalogEntry] = []
  for entry in catalog {
    if entry.id != book.id {
      merged.push(entry)
    }
  }
  merged.push(book)
  merged
}

///|
fn standing_goal_registry_upsert(
  goals : Array[@core.StandingGoal],
  goal : @core.StandingGoal,
) -> Array[@core.StandingGoal] {
  let updated : Array[@core.StandingGoal] = []
  let mut seen = false
  for current in goals {
    if current.id == goal.id {
      updated.push(goal)
      seen = true
    } else {
      updated.push(current)
    }
  }
  if !seen {
    updated.push(goal)
  }
  updated
}

///|
fn standing_goal_registry_contains(
  goals : Array[@core.StandingGoal],
  goal_id : String,
) -> Bool {
  goals.any(fn(goal) { goal.id == goal_id })
}

///|
fn standing_goal_registry_enabled(
  goals : Array[@core.StandingGoal],
  goal_id : String,
) -> Bool {
  goals.any(fn(goal) { goal.id == goal_id && goal.enabled })
}

///|
