///|
fn book_type_signal_score(
  book_type : String,
  entry : @moonbook.BookCatalogEntry,
  content : BookQualityContentObservation,
  structural : BookQualityStructuralObservation,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  if book_type == @policy.research_type() {
    return apply_score_signal(
      research_deep_report_word_assessment(
        content.research_deep_report_word_count,
      ),
      strengths,
      gaps,
    )
  }
  if book_type == @policy.course_type() {
    return apply_score_signal(
      course_identity_assessment(entry.id, content.course_index_text),
      strengths,
      gaps,
    )
  }
  if book_type == @policy.cookbook_type() {
    return apply_score_signal(
      cookbook_audit_link_assessment(content.cookbook_audit_exists),
      strengths,
      gaps,
    )
  }
  if book_type == @policy.civic_type() {
    return civic_book_signal_score(entry, structural, strengths, gaps)
  }
  0
}

///|
fn civic_book_signal_score(
  entry : @moonbook.BookCatalogEntry,
  structural : BookQualityStructuralObservation,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) =>
      score_civic_service_definition(structural, service, strengths, gaps)
    None => {
      gaps.push("no civic service definition matched this book")
      0
    }
  }
}
