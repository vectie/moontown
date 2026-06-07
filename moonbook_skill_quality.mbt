///|
fn moonbook_skill_quality_contract_section() -> String {
  [
    "## Exploration Quality Contract", "", "Every run should improve the book's ability to answer deeper and broader questions about its topic.",
    "", "- Go deeper: explain the mechanism, evidence chain, confidence boundary, contradiction, or internal dependency that makes the result true, weak, or blocked.",
    "- Go broader: connect the result to adjacent entities, concepts, source pages, downstream decisions, and book-maintenance consequences.",
    "- Generate new questions: record follow-up questions that would change the answer, expose missing evidence, or open a useful next investigation.",
    "- Generate new directions: name the next durable page, review item, experiment, comparison, or synthesis update that should grow from this work.",
    "- Prefer longer meaningful text over short status output when evidence exists: give enough context that a future keeper can resume without the chat history.",
  ].join("\n")
}

///|
fn moonbook_skill_quality_word_count(text : String) -> Int {
  count_english_word_tokens(text)
}

///|
fn moonbook_skill_quality_has_depth(text : String) -> Bool {
  let lower = text.to_lower()
  lower.contains("go deeper") &&
  lower.contains("mechanism") &&
  lower.contains("evidence chain")
}

///|
fn moonbook_skill_quality_has_breadth(text : String) -> Bool {
  let lower = text.to_lower()
  lower.contains("go broader") &&
  lower.contains("adjacent") &&
  lower.contains("downstream")
}

///|
fn moonbook_skill_quality_generates_questions(text : String) -> Bool {
  let lower = text.to_lower()
  lower.contains("generate new questions") &&
  lower.contains("follow-up questions")
}

///|
fn moonbook_skill_quality_generates_directions(text : String) -> Bool {
  let lower = text.to_lower()
  lower.contains("generate new directions") &&
  lower.contains("next durable page")
}

///|
fn moonbook_skill_quality_prefers_meaningful_length(text : String) -> Bool {
  text.to_lower().contains("longer meaningful text")
}

///|
pub fn moonbook_skill_quality_is_strong(text : String) -> Bool {
  moonbook_skill_quality_word_count(text) >= 160 &&
  moonbook_skill_quality_has_depth(text) &&
  moonbook_skill_quality_has_breadth(text) &&
  moonbook_skill_quality_generates_questions(text) &&
  moonbook_skill_quality_generates_directions(text) &&
  moonbook_skill_quality_prefers_meaningful_length(text)
}
