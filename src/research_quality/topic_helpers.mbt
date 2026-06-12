///|
fn projection_contains_topic(lower : String, topic : String) -> Bool {
  if research_text_contains_topic(lower, topic) {
    return true
  }
  for topic_alias in topic_page_aliases(topic) {
    if lower.contains(topic_alias.to_lower()) {
      return true
    }
  }
  false
}

///|
pub fn research_text_contains_topic(lower : String, topic : String) -> Bool {
  for topic_alias in topic_page_aliases(topic) {
    if lower.contains(topic_alias.to_lower()) {
      return true
    }
  }
  let normalized = @support.label_from_slug(topic)
  let mut first_topic_word : String? = None
  let mut hits = 0
  for piece in normalized.split(" ") {
    let word = piece.trim().to_owned()
    if first_topic_word is None && !word.is_empty() && word != "research" {
      first_topic_word = Some(word)
    }
    if word.length() >= 4 && lower.contains(word.to_lower()) {
      hits += 1
    }
  }
  match first_topic_word {
    Some(word) =>
      if word.length() >= 3 && lower.contains(word.to_lower()) {
        return true
      }
    None => ()
  }
  hits >= 2
}

///|
fn topic_page_aliases(topic : String) -> Array[String] {
  if topic == "opc" {
    ["opc", "one-person-company", "one person company", "one-person company"]
  } else if topic.contains("llm") ||
    topic.contains("large-language-model") ||
    topic.contains("large language model") {
    [
      topic,
      @support.label_from_slug(topic),
      "llm training",
      "llm trained",
      "llms are trained",
      "large language model training",
      "large language models are trained",
      "large language model pre-training",
      "large language model post-training",
    ]
  } else {
    [topic, @support.label_from_slug(topic)]
  }
}

///|
pub fn quality_topic_for_entry(entry : @moonbook.BookCatalogEntry) -> String {
  for tag in entry.tags {
    if tag.has_prefix("topic:") {
      let topic = tag[6:].to_owned()
      if !topic.is_empty() {
        return topic
      }
    }
  }
  if entry.id.has_prefix("research-") {
    entry.id.replace(old="research-", new="").to_lower()
  } else if entry.id.has_prefix("wenyu-") {
    @support.label_from_slug(entry.id.replace(old="wenyu-", new="")).to_lower()
  } else {
    entry.id.to_lower()
  }
}
