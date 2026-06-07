///|
fn clamp_score(score : Int) -> Int {
  if score < 0 {
    0
  } else if score > 100 {
    100
  } else {
    score
  }
}

///|
fn quality_grade(score : Int) -> String {
  if score >= 95 {
    "world-class"
  } else if score >= 90 {
    "excellent"
  } else if score >= 80 {
    "strong"
  } else if score >= 65 {
    "usable"
  } else if score >= 45 {
    "weak"
  } else {
    "not-managed"
  }
}

///|
fn next_book_quality_action(
  book_type : String,
  gaps : Array[String],
  score : Int,
  semantic_score : Int?,
) -> String {
  if semantic_review_requires_repair(semantic_score) {
    semantic_quality_repair_action()
  } else if structural_quality_is_stable(gaps, score) {
    stable_book_quality_action()
  } else {
    book_type_repair_action(book_type)
  }
}

///|
fn semantic_review_requires_repair(semantic_score : Int?) -> Bool {
  match semantic_score {
    Some(value) => value < semantic_quality_ready_threshold()
    None => false
  }
}

///|
fn semantic_quality_ready_threshold() -> Int {
  80
}

///|
fn semantic_quality_repair_action() -> String {
  "Use the AI semantic review to repair real book quality, not just structure."
}

///|
fn stable_book_quality_action() -> String {
  "Keep running standing review; no immediate repair."
}

///|
fn structural_quality_is_stable(gaps : Array[String], score : Int) -> Bool {
  gaps.is_empty() && score >= 90
}

///|
fn book_type_repair_action(book_type : String) -> String {
  match book_quality_policy_spec_for_type(book_type) {
    Some(spec) => spec.repair_action
    None => general_book_repair_action()
  }
}

///|
fn research_book_repair_action() -> String {
  "Run a research quality review and repair source depth, evidence matrix, report length, and generated projection."
}

///|
fn course_book_repair_action() -> String {
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
fn civic_protocol_support_repair_action() -> String {
  "Run one protocol-native loop: inbox/contribution -> reduction -> review -> accepted distribution, then persist only the support records required by the building persistence mode."
}

///|
fn operational_book_repair_action() -> String {
  "Run an operational keeper review: validate safe memory, review policy, journey notes, and sensitive-boundary handling."
}

///|
fn general_book_repair_action() -> String {
  "Bootstrap a typed MoonBook workspace or remove placeholder catalog entry."
}
