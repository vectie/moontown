///|
struct BookQualityContextSpec {
  book_type : String
  pages : Array[String]
} derive(Debug, Eq)

///|
fn context_spec(
  book_type : String,
  pages : Array[String],
) -> BookQualityContextSpec {
  { book_type, pages: [wiki_index_path(), ..pages, generated_site_path()] }
}

///|
fn context_specs() -> Array[BookQualityContextSpec] {
  [
    context_spec(@policy.research_type(), [
      "raw/bootstrap/research-question.md", "raw/bootstrap/source-screen.md", "raw/bootstrap/evidence-matrix.md",
      "raw/bootstrap/deep-report.md",
    ]),
    context_spec(@policy.course_type(), [
      "raw/bootstrap/COURSE_CONTRACT.md", "wiki/course/beginner-course.md", "wiki/course/exercises.md",
      "skills/course-builder/SKILL.md",
    ]),
    context_spec(@policy.planbook_type(), [
      "raw/bootstrap/PLANBOOK_CONTRACT.md", "plans/2026-05-29-book-quality-upgrade/plan.md",
      "skills/code-plan/SKILL.md",
    ]),
    context_spec(@policy.cookbook_type(), [
      "raw/bootstrap/COOKBOOK_CONTRACT.md", "wiki/definitions/stable-state.md", "wiki/definitions/ownership.md",
    ]),
    context_spec(@policy.civic_type(), [
      "raw/bootstrap/CIVIC_SERVICE_CONTRACT.md", "raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md",
      "skills/wenyu-civic-service/SKILL.md", "wiki/ledgers/service-ledger.md", "wiki/ledgers/exchange-ledger.md",
      "wiki/history/service-history.md",
    ]),
    context_spec(@policy.operational_type(), [
      "raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md", "wiki/operations/review-policy.md",
      "wiki/history/journey.md", "skills/operational-keeper/SKILL.md",
    ]),
  ]
}

///|
pub fn context_pages_for_type(book_type : String) -> Array[String] {
  for spec in context_specs() {
    if spec.book_type == book_type {
      return spec.pages
    }
  }
  [wiki_index_path(), projection_state_path()]
}
