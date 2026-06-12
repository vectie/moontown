///|
pub fn semantic_ready_threshold() -> Int {
  80
}

///|
pub fn stable_action() -> String {
  "Keep running standing review; no immediate repair."
}

///|
pub fn semantic_repair_action(semantic_repair_task? : String? = None) -> String {
  match semantic_repair_task {
    Some(task) if !task.trim().is_empty() =>
      "AI semantic review repair: \{task.trim()}"
    _ =>
      "Use the AI semantic review to repair real book quality, not just structure."
  }
}

///|
fn research_repair_action() -> String {
  "Run a research quality review and repair source depth, evidence matrix, report length, and generated projection."
}

///|
fn course_repair_action() -> String {
  "Run course projection repair: enforce course identity, lesson progression, exercises, checkpoints, and beginner usability."
}

///|
fn planbook_repair_action() -> String {
  "Bootstrap or repair plan contract, code-plan skill, acceptance gates, and execution evidence."
}

///|
fn cookbook_repair_action() -> String {
  "Refresh cookbook bootstrap and include latest docs, definitions, runtime state, and book-quality audit."
}

///|
fn civic_repair_action() -> String {
  "Run one protocol-native loop: inbox/contribution -> reduction -> review -> accepted distribution, then persist only the support records required by the building persistence mode."
}

///|
fn operational_repair_action() -> String {
  "Run an operational keeper review: validate safe memory, review policy, journey notes, and sensitive-boundary handling."
}

///|
fn general_repair_action() -> String {
  "Bootstrap a typed MoonBook workspace with policy, skills, wiki index, projection, and review history."
}
