///|
fn weakest_score(scores : Array[BookQualityScore]) -> BookQualityScore? {
  let mut weakest : BookQualityScore? = None
  for score in scores {
    match weakest {
      Some(current) if current.score <= score.score => ()
      _ => weakest = Some(score)
    }
  }
  weakest
}

///|
fn render_book_quality_audit(audit : BookQualityAudit) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# MoonBook Management And Quality Audit\n\n")
  builder.write_string(
    "Total: \{audit.total}; structurally ready: \{audit.ready_count}; structurally excellent: \{audit.world_class_count}; weakest structural book: `\{audit.weakest_book_id}` (\{audit.weakest_score}).\n\n",
  )
  builder.write_string(
    "Important: structural readiness is not book quality. Real quality must come from AI semantic review results written under `\{default_book_quality_review_result_dir()}/<book-id>.md`.\n\n",
  )
  builder.write_string(
    "| Book | Type | Structural readiness | AI quality | Quality status | Ready | Next action |\n",
  )
  builder.write_string("| --- | --- | ---: | --- | --- | ---: | --- |\n")
  for score in audit.scores {
    let ai_quality = match score.semantic_score {
      Some(value) => "\{value} / \{score.semantic_grade}"
      None => "pending"
    }
    builder.write_string(
      "|\{score.book_id}|\{score.book_type}|\{score.structural_score} / \{score.structural_grade}|\{ai_quality}|\{score.quality_status}|\{score.ready}|\{markdown_inline(score.next_action)}|\n",
    )
  }
  builder.write_string("\n## Gaps By Book\n\n")
  for score in audit.scores {
    builder.write_string("### \{score.book_id}\n\n")
    if score.gaps.is_empty() {
      builder.write_string("- none\n\n")
    } else {
      builder.write_string(markdown_bullets(score.gaps))
      builder.write_string("\n\n")
    }
  }
  builder.to_string()
}

///|
async fn read_ai_quality_result_text(
  book_id : String,
  result_dir : String,
) -> String {
  let path = book_quality_ai_review_result_path(result_dir, book_id)
  let text = read_text_or_empty(path)
  text
}

///|
fn parse_ai_quality_score(text : String) -> Int? {
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
fn book_quality_semantic_repair_task(text : String) -> String? {
  book_quality_contract_field(text, "next_repair_task")
}

///|
fn book_quality_markdown_path(audit_path : String) -> String {
  if audit_path.has_suffix(".json") {
    "\{audit_path[:audit_path.length() - 5]}.md"
  } else {
    "\{audit_path}.md"
  }
}
