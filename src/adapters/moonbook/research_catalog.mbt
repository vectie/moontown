///|
pub fn research_lane_topics(goal : String) -> Array[String] {
  let notes = goal.to_lower()
  let topics : Array[String] = []
  for topic in ["moontown", "moonbook", "moonclaw", "finance", "coding"] {
    if notes.contains(topic) {
      topics.push(topic)
    }
  }
  if notes.contains("opc") || notes.contains("one person company") {
    topics.push("opc")
  }
  topics
}

///|
pub fn should_parallelize_goal(goal : String) -> Bool {
  let topics = research_lane_topics(goal)
  is_research_goal(goal) && topics.length() > 1
}

///|
pub fn parallel_research_entry(topic : String) -> BookCatalogEntry {
  let normalized = normalize_topic_id(topic)
  let canonical_book_id = "research-\{normalized}"
  let display = display_topic_name(normalized)
  research_catalog_entry(
    canonical_book_id~,
    topic_id=normalized,
    purpose="Isolated research wiki for \{display}, managed by the mayor as one lane in a parallel town goal.",
    tags=["research", normalized, "topic:\{normalized}", "parallel-lane"],
  )
}

///|
pub fn entry_for_book_id(
  catalog : Array[BookCatalogEntry],
  book_id : String,
) -> BookCatalogEntry? {
  match find_catalog_entry(catalog, book_id) {
    Some(entry) => Some(entry)
    None =>
      match research_book_topic_from_id(book_id) {
        Some(topic) => Some(parallel_research_entry(topic))
        None => None
      }
  }
}

///|
pub fn entry_for_explicit_research_book(
  catalog : Array[BookCatalogEntry],
  book_id : String,
  goal : String,
) -> BookCatalogEntry? {
  match find_catalog_entry(catalog, book_id) {
    Some(entry) => Some(entry)
    None =>
      match research_book_topic_from_id(book_id) {
        Some(storage_topic) => {
          let stable_storage_topic = strip_research_attempt_suffix(
            storage_topic,
          )
          let goal_topic = research_topic_from_goal(goal)
          let goal_topic_id = match goal_topic {
            Some(topic) => normalize_topic_id(topic)
            None => ""
          }
          let storage_topic_id = normalize_topic_id(stable_storage_topic)
          let has_attempt_suffix = stable_storage_topic !=
            storage_topic.to_lower().trim().to_owned()
          let book_topic_id = if has_attempt_suffix && !goal_topic_id.is_empty() {
            goal_topic_id
          } else {
            storage_topic_id
          }
          if book_topic_id.is_empty() {
            return None
          }
          let topic_id = if !goal_topic_id.is_empty() {
            goal_topic_id
          } else {
            book_topic_id
          }
          let canonical_book_id = "research-\{book_topic_id}"
          let display = display_topic_name(topic_id)
          let purpose = if canonical_book_id == book_id {
            "Isolated research wiki for \{display}, stored in \{canonical_book_id} for this topic."
          } else {
            "Isolated research wiki for \{display}; requested as \{book_id}, but stored in stable topic book \{canonical_book_id} so quality retries do not create v1/v2/v3 forks."
          }
          let tags = if canonical_book_id == book_id {
            ["research", topic_id, "topic:\{topic_id}", "explicit-book"]
          } else {
            [
              "research",
              topic_id,
              "topic:\{topic_id}",
              "explicit-book",
              "requested-book:\{book_id}",
            ]
          }
          Some(
            research_catalog_entry(
              canonical_book_id~,
              topic_id~,
              purpose~,
              tags~,
            ),
          )
        }
        None => None
      }
  }
}

///|
fn research_book_topic_from_id(book_id : String) -> String? {
  if !book_id.has_prefix("research-") {
    return None
  }
  let topic = book_id[9:].trim().to_owned()
  if topic.is_empty() {
    None
  } else {
    Some(topic)
  }
}

///|
fn research_catalog_entry(
  canonical_book_id~ : String,
  topic_id~ : String,
  purpose~ : String,
  tags~ : Array[String],
) -> BookCatalogEntry {
  let display = display_topic_name(topic_id)
  BookCatalogEntry::new(
    id=canonical_book_id,
    name="Moonbook / Research / \{display}",
    purpose~,
    workspace_root=default_workspace_root(canonical_book_id),
    memory_scope=@core.MemoryScope::BookPrivate,
    tags~,
    skills=["analysis", "synthesis", "memory", "review"],
  )
}
