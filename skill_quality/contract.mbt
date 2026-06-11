///|
pub fn exploration_quality_contract_section() -> String {
  [
    "## Exploration Quality Contract", "", "Every run should improve the book's ability to answer deeper and broader questions about its topic.",
    "", "- Go deeper: explain the mechanism, evidence chain, confidence boundary, contradiction, or internal dependency that makes the result true, weak, or blocked.",
    "- Go broader: connect the result to adjacent entities, concepts, source pages, downstream decisions, and book-maintenance consequences.",
    "- Generate new questions: record follow-up questions that would change the answer, expose missing evidence, or open a useful next investigation.",
    "- Generate new directions: name the next durable page, review item, experiment, comparison, or synthesis update that should grow from this work.",
    "- Prefer longer meaningful text over short status output when evidence exists: give enough context that a future keeper can resume without the chat history.",
    "- Separate observation from judgment: cite what was actually seen, explain what it implies, and state what remains uncertain before recommending action.",
    "- Preserve curiosity and imagination: propose useful analogies, neglected stakeholders, surprising hypotheses, or adjacent domains without presenting speculation as fact.",
    "- Support long-horizon memory: write findings so a keeper can compare this run with prior runs, notice drift, and decide whether the book policy or skills should change.",
    "- Make progress auditable: name changed files, accepted evidence, rejected evidence, unresolved blockers, and the next check that would prove the book improved.",
  ].join("\n")
}

///|
pub fn exploration_quality_contract_is_strong(text : String) -> Bool {
  english_word_count(text) >= 160 &&
  has_depth(text) &&
  has_breadth(text) &&
  generates_questions(text) &&
  generates_directions(text) &&
  prefers_meaningful_length(text)
}

///|
fn has_depth(text : String) -> Bool {
  let lower = text.to_lower()
  lower.contains("go deeper") &&
  lower.contains("mechanism") &&
  lower.contains("evidence chain")
}

///|
fn has_breadth(text : String) -> Bool {
  let lower = text.to_lower()
  lower.contains("go broader") &&
  lower.contains("adjacent") &&
  lower.contains("downstream")
}

///|
fn generates_questions(text : String) -> Bool {
  let lower = text.to_lower()
  lower.contains("generate new questions") &&
  lower.contains("follow-up questions")
}

///|
fn generates_directions(text : String) -> Bool {
  let lower = text.to_lower()
  lower.contains("generate new directions") &&
  lower.contains("next durable page")
}

///|
fn prefers_meaningful_length(text : String) -> Bool {
  text.to_lower().contains("longer meaningful text")
}

///|
fn english_word_count(text : String) -> Int {
  let mut count = 0
  let mut in_word = false
  for char in text {
    if is_english_alnum(char) {
      if !in_word {
        count += 1
      }
      in_word = true
    } else {
      in_word = false
    }
  }
  count
}

///|
fn is_english_alnum(char : Char) -> Bool {
  (char >= 'a' && char <= 'z') ||
  (char >= 'A' && char <= 'Z') ||
  (char >= '0' && char <= '9')
}
