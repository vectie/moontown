///|
async fn score_planbook(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let draft = new_book_quality_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    planbook_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    book_quality_planbook_type(),
    draft,
    score,
    review_result_dir,
  )
}

///|
fn planbook_required_paths() -> Array[BookQualityRequiredPath] {
  [
    book_quality_required_path("raw/bootstrap/PLANBOOK_CONTRACT.md", 14),
    book_quality_required_path(
      "plans/2026-05-29-book-quality-upgrade/plan.md", 16,
    ),
    book_quality_required_path("plans/index.md", 8),
    book_quality_required_path("wiki/planning/quality-gates.md", 12),
    book_quality_required_path("wiki/planning/execution-evidence.md", 10),
    book_quality_required_path("wiki/reviews/active-plan-review.md", 10),
    book_quality_required_path("wiki/history/decision-log.md", 8),
    book_quality_required_path("schemas/plan-record.schema.md", 6),
    book_quality_required_path("skills/code-plan/SKILL.md", 12),
    book_quality_required_path("skills/code-review/SKILL.md", 10),
    book_quality_required_path("skills/doc-sync/SKILL.md", 8),
    book_quality_required_path(book_quality_generated_site_path(), 6),
  ]
}

///|
async fn score_cookbook(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let draft = new_book_quality_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    cookbook_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  if @fs.exists(".moontown/book-quality/audit.json") {
    score += 6
    draft.strengths.push(
      "book quality audit is linked into stable-state governance",
    )
  } else {
    draft.gaps.push("book quality audit has not been written yet")
  }
  finalize_score_draft(
    entry,
    book_quality_cookbook_type(),
    draft,
    score,
    review_result_dir,
  )
}

///|
fn cookbook_required_paths() -> Array[BookQualityRequiredPath] {
  [
    book_quality_required_path("raw/bootstrap/COOKBOOK_CONTRACT.md", 14),
    book_quality_required_path("wiki/definitions/stable-state.md", 16),
    book_quality_required_path("wiki/definitions/ownership.md", 12),
    book_quality_required_path("wiki/definitions/book-types.md", 6),
    book_quality_required_path("wiki/definitions/runtime-boundaries.md", 6),
    book_quality_required_path("wiki/operating-procedures/doctor.md", 10),
    book_quality_required_path(
      "wiki/operating-procedures/book-governance.md", 6,
    ),
    book_quality_required_path("wiki/history/stable-state-ledger.md", 6),
    book_quality_required_path("schemas/stable-state-manifest.schema.md", 8),
    book_quality_required_path(book_quality_generated_site_path(), 6),
  ]
}

///|
async fn score_operational_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let draft = new_book_quality_score_draft(entry)
  let mut score = draft.base_score
  score += required_paths_score(
    draft.root,
    operational_book_required_paths(),
    draft.strengths,
    draft.gaps,
  )
  finalize_score_draft(
    entry,
    book_quality_operational_type(),
    draft,
    score,
    review_result_dir,
  )
}

///|
fn operational_book_required_paths() -> Array[BookQualityRequiredPath] {
  [
    book_quality_required_path("raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md", 18),
    book_quality_required_path("wiki/operations/review-policy.md", 16),
    book_quality_required_path("wiki/history/journey.md", 12),
    book_quality_required_path("skills/operational-keeper/SKILL.md", 16),
    book_quality_required_path(book_quality_generated_site_path(), 10),
  ]
}
