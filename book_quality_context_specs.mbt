///|
struct BookQualityContextSpec {
  book_type : String
  pages : Array[String]
} derive(Debug, Eq)

///|
fn book_quality_context_spec(
  book_type : String,
  pages : Array[String],
) -> BookQualityContextSpec {
  {
    book_type,
    pages: [
      book_quality_wiki_index_path(),
      ..pages,
      book_quality_generated_site_path(),
    ],
  }
}

///|
fn book_quality_context_specs() -> Array[BookQualityContextSpec] {
  [
    book_quality_context_spec(book_quality_research_type(), [
      "raw/bootstrap/research-question.md", "raw/bootstrap/source-screen.md", "raw/bootstrap/evidence-matrix.md",
      "raw/bootstrap/deep-report.md",
    ]),
    book_quality_context_spec(book_quality_course_type(), [
      "raw/bootstrap/COURSE_CONTRACT.md", "wiki/course/beginner-course.md", "wiki/course/exercises.md",
      "skills/course-builder/SKILL.md",
    ]),
    book_quality_context_spec(book_quality_planbook_type(), [
      "raw/bootstrap/PLANBOOK_CONTRACT.md", "plans/2026-05-29-book-quality-upgrade/plan.md",
      "skills/code-plan/SKILL.md",
    ]),
    book_quality_context_spec(book_quality_cookbook_type(), [
      "raw/bootstrap/COOKBOOK_CONTRACT.md", "wiki/definitions/stable-state.md", "wiki/definitions/ownership.md",
    ]),
    book_quality_context_spec(book_quality_civic_type(), [
      "raw/bootstrap/CIVIC_SERVICE_CONTRACT.md", "raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md",
      "skills/wenyu-civic-service/SKILL.md", "wiki/ledgers/service-ledger.md", "wiki/ledgers/exchange-ledger.md",
      "wiki/history/service-history.md",
    ]),
    book_quality_context_spec(book_quality_operational_type(), [
      "raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md", "wiki/operations/review-policy.md",
      "wiki/history/journey.md", "skills/operational-keeper/SKILL.md",
    ]),
  ]
}

///|
fn book_quality_context_pages_for_type(book_type : String) -> Array[String] {
  for spec in book_quality_context_specs() {
    if spec.book_type == book_type {
      return spec.pages
    }
  }
  [book_quality_wiki_index_path(), book_quality_projection_state_path()]
}
