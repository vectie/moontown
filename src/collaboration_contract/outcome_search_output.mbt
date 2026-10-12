///|
pub fn OutcomeSearch::json_text(self : OutcomeSearch) -> String raise {
  let output = self.to_json().stringify(indent=2) + "\n"
  guard output.length() <= 4194304 else {
    fail("Search output exceeds 4 Mi UTF-16 code units; narrow the query")
  }
  output
}

///|
/// Every retained value is rendered as literal text, never executable markup.
pub fn OutcomeSearch::markdown(self : OutcomeSearch) -> String raise {
  let sections = [
    "# Retained outcome search",
    comparison_literal(
      "Phrase: " +
      self.query.text +
      "\nBook: " +
      self.query.book_id +
      "\nReview filter: " +
      self.query.review_status +
      "\nCase sensitive: " +
      self.query.case_sensitive.to_string() +
      "\nReview selection: " +
      self.review_selection,
    ),
    "Candidates: " +
    self.candidate_count.to_string() +
    "; searched: " +
    self.searched_count.to_string() +
    "; excluded by filters: " +
    self.excluded_count.to_string() +
    "; gaps: " +
    self.gaps.length().to_string() +
    "; matching outcomes: " +
    self.hits.length().to_string() +
    ".",
    "Literal phrase search over retained authored text and source metadata. Source file bodies, live Books and superseded review decisions are not searched. Each field shows its first occurrence with original UTF-16 offsets. Book filters search only that Book's attributed fields. Case-insensitive mode folds ASCII only.",
    "Default selection uses the review pinned by the initial all-source-revision index, not necessarily the newest source revision. Explicit selections can be older historical reviews. Neither mode asserts the current live review state. Gaps are unknown evidence, not evidence of no match. No execution, synthesis, review decision or Book write is performed.",
  ]
  for hit in self.hits {
    sections.push(
      "## Matching outcome\n\n" +
      comparison_literal(
        "Title: " +
        hit.title +
        "\nRecorded: " +
        hit.recorded_at +
        "\nOutcome: " +
        hit.outcome_status +
        "\nSelected review: " +
        hit.review_status +
        "\nArchive digest: " +
        hit.archive_digest +
        "\nExact OutcomeKey:\n" +
        hit.key.to_json().stringify(indent=2),
      ),
    )
    for item in hit.matches {
      sections.push(
        "### Matching field\n\n" +
        comparison_literal(
          "Field: " +
          item.field +
          "\nBook: " +
          item.book_id +
          "\nIdentity: " +
          item.identity +
          "\nDigest: " +
          item.digest +
          "\nMatch offset: " +
          item.match_offset.to_string() +
          "\nExcerpt offset: " +
          item.excerpt_offset.to_string() +
          "\nField length: " +
          item.field_length.to_string(),
        ) +
        "\nExcerpt:\n\n" +
        comparison_literal(item.excerpt),
      )
    }
  }
  if !self.gaps.is_empty() {
    sections.push("## Coverage gaps")
  }
  for gap in self.gaps {
    sections.push(comparison_literal(gap.to_json().stringify(indent=2)))
  }
  let output = sections.join("\n\n") + "\n"
  guard output.length() <= 4194304 else {
    fail("Search output exceeds 4 Mi UTF-16 code units; narrow the query")
  }
  output
}
