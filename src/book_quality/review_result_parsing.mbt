///|
pub(all) struct BookQualityRepairReviewContract {
  semantic_grade : String
  repair_owner : String
  next_repair_task : String
} derive(Eq, ToJson, FromJson)

///|
pub fn parse_ai_quality_score(text : String) -> Int? {
  for raw in text.split("\n") {
    let line = raw.trim()
    let owned = line.to_owned()
    let lower = owned.to_lower()
    if lower.has_prefix("ai_quality_score:") {
      return first_int(owned)
    }
    if lower.has_prefix("\"ai_quality_score\"") {
      return first_int(owned)
    }
  }
  None
}

///|
fn first_int(text : String) -> Int? {
  let mut value = 0
  let mut seen = false
  for char in text {
    if char >= '0' && char <= '9' {
      seen = true
      value = value * 10 + (char.to_int() - '0'.to_int())
    } else if seen {
      return Some(value)
    }
  }
  if seen {
    Some(value)
  } else {
    None
  }
}

///|
pub fn semantic_repair_task_from_review_text(text : String) -> String? {
  review_contract_field(text, "next_repair_task")
}

///|
pub fn repair_review_contract(
  result_text : String,
  score : BookQualityScore,
) -> BookQualityRepairReviewContract {
  {
    semantic_grade: review_contract_field(result_text, "ai_quality_grade").unwrap_or(
      score.semantic_grade,
    ),
    repair_owner: review_contract_field(result_text, "repair_owner").unwrap_or(
      "mixed",
    ),
    next_repair_task: review_contract_field(result_text, "next_repair_task").unwrap_or(
      score.next_action,
    ),
  }
}

///|
fn review_contract_field(text : String, key : String) -> String? {
  let needle = "\{key.to_lower()}:"
  for raw in text.split("\n") {
    let line = raw.trim()
    let lower = line.to_lower()
    if lower.has_prefix(needle) {
      return Some(line[needle.length():].trim().to_owned())
    }
  }
  None
}
