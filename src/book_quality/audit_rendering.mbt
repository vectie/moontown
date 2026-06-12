///|
pub fn weakest_score(scores : Array[BookQualityScore]) -> BookQualityScore? {
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
pub fn audit_from_scores(
  catalog_path : String,
  scores : Array[BookQualityScore],
) -> BookQualityAudit {
  let weakest = weakest_score(scores)
  {
    generated_at: "runtime",
    catalog_path,
    total: scores.length(),
    world_class_count: scores.filter(fn(item) { item.score >= 90 }).length(),
    ready_count: scores.filter(fn(item) { item.ready }).length(),
    weakest_book_id: match weakest {
      Some(score) => score.book_id
      None => ""
    },
    weakest_score: match weakest {
      Some(score) => score.score
      None => 0
    },
    scores,
  }
}

///|
pub fn render_audit_markdown(audit : BookQualityAudit) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# MoonBook Management And Quality Audit\n\n")
  builder.write_string(
    "Total: \{audit.total}; structurally ready: \{audit.ready_count}; structurally excellent: \{audit.world_class_count}; weakest structural book: `\{audit.weakest_book_id}` (\{audit.weakest_score}).\n\n",
  )
  builder.write_string(
    "Important: structural readiness is not book quality. Real quality must come from AI semantic review results written under `\{default_review_result_dir()}/<book-id>.md`.\n\n",
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
      "|\{score.book_id}|\{score.book_type}|\{score.structural_score} / \{score.structural_grade}|\{ai_quality}|\{score.quality_status}|\{score.ready}|\{book_quality_markdown_inline(score.next_action)}|\n",
    )
  }
  builder.write_string("\n## Gaps By Book\n\n")
  for score in audit.scores {
    builder.write_string("### \{score.book_id}\n\n")
    if score.gaps.is_empty() {
      builder.write_string("- none\n\n")
    } else {
      builder.write_string(book_quality_markdown_bullets(score.gaps))
      builder.write_string("\n\n")
    }
  }
  builder.to_string()
}

///|
fn book_quality_markdown_bullets(values : Array[String]) -> String {
  values
  .map(fn(value) { "- \{book_quality_markdown_inline(value)}" })
  .join("\n")
}

///|
pub fn audit_markdown_path(audit_path : String) -> String {
  if audit_path.has_suffix(".json") {
    "\{audit_path[:audit_path.length() - 5]}.md"
  } else {
    "\{audit_path}.md"
  }
}
