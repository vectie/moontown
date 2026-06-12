///|
fn select_default_entry(
  catalog : Array[@moonbook.BookCatalogEntry],
  goal : String,
) -> @moonbook.BookCatalogEntry? {
  let notes = goal.to_lower()
  let book_id = if notes.contains("finance") ||
    notes.contains("ledger") ||
    notes.contains("budget") ||
    notes.contains("daily") {
    "finance"
  } else {
    "coding"
  }
  match @moonbook.find_catalog_entry(catalog, book_id) {
    Some(entry) => Some(entry)
    None => if catalog.is_empty() { None } else { Some(catalog[0]) }
  }
}

///|
fn mayor_goal_decomposition_prompt(
  catalog : Array[@moonbook.BookCatalogEntry],
  goal : String,
  explicit_book_id? : String? = None,
) -> String {
  [
    mayor_goal_prompt_header(catalog, goal, explicit_book_id~),
    "Rules:",
    mayor_goal_decomposition_rules().join("\n"),
    "Required output contract: \{mayor_goal_decomposition_contract()}",
    "Fields:",
    mayor_goal_decomposition_contract_fields().join("\n"),
  ].join("\n")
}

///|
fn mayor_goal_prompt_header(
  catalog : Array[@moonbook.BookCatalogEntry],
  goal : String,
  explicit_book_id? : String? = None,
) -> String {
  [
    "You are the Mayor claw for Moontown.",
    "Decide whether the town goal should stay in one MoonBook or decompose into multiple isolated MoonBooks.",
    "Available books: \{catalog.map(fn(entry) { entry.id }).join(", ")}",
    "Explicit book: \{explicit_book_id.unwrap_or("none")}",
    "Goal: \{goal}",
  ].join("\n")
}

///|
fn mayor_goal_decomposition_contract() -> String {
  "mayor.goal.decomposition.v1"
}

///|
fn mayor_goal_decomposition_rules() -> Array[String] {
  [
    "- parallelize only when the goal names meaningfully distinct knowledge subjects or domains",
    "- each lane must own an isolated wiki/workspace", "- prefer one lane if shared context is essential and decomposition would create artificial fragmentation",
    "- if decomposing, emit one lane per durable knowledge subject", "- each lane objective must be self-contained and book-local",
  ]
}

///|
fn mayor_goal_decomposition_contract_fields() -> Array[String] {
  [
    "- parallelizable: bool", "- summary: string", "- lanes: [{book_id, objective, rationale}]",
  ]
}
