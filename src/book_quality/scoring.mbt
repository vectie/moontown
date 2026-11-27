///|
pub fn clamp_score(score : Int32) -> Int32 {
  if score < 0 {
    0
  } else if score > 100 {
    100
  } else {
    score
  }
}

///|
pub fn quality_grade(score : Int32) -> String {
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
pub fn semantic_review_requires_repair(semantic_score : Int32?) -> Bool {
  match semantic_score {
    Some(value) => value < semantic_ready_threshold()
    None => false
  }
}

///|
pub fn structural_quality_is_stable(
  gaps : Array[String],
  score : Int32,
) -> Bool {
  gaps.is_empty() && score >= 90
}

///|
pub fn push_unique_note(notes : Array[String], note : String) -> Unit {
  if !notes.contains(note) {
    notes.push(note)
  }
}

///|
pub fn next_action(
  book_type : String,
  gaps : Array[String],
  score : Int32,
  semantic_score : Int32?,
  semantic_repair_task~ : String? = None,
) -> String {
  if semantic_review_requires_repair(semantic_score) {
    semantic_repair_action(semantic_repair_task~)
  } else if structural_quality_is_stable(gaps, score) {
    stable_action()
  } else {
    repair_action_for_type(book_type)
  }
}
