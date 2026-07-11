///|
pub fn wenyu_beginner_course_skill_path() -> String {
  "skills/wenyu-beginner-course/SKILL.md"
}

///|
pub fn wiki_course_skill_path() -> String {
  "skills/wiki-course/SKILL.md"
}

///|
pub fn course_skill_paths() -> Array[String] {
  [
    wenyu_beginner_course_skill_path(),
    wiki_course_skill_path(),
    @research_policy.web_first_research_skill_path(),
    @research_policy.source_diarize_skill_path(),
  ]
}

///|
pub fn course_quality_repair_path() -> String {
  "raw/bootstrap/QUALITY_REPAIR.md"
}

///|
pub fn course_outline_path() -> String {
  "raw/bootstrap/course-outline.md"
}

///|
pub fn course_workbook_path() -> String {
  // Course mode reuses the historical deep-report slot as the visible workbook.
  @research_policy.deep_report_path()
}

///|
pub fn course_synthesis_page_path() -> String {
  "wiki/synthesis/beginner-course.md"
}

///|
pub fn course_journey_page_path() -> String {
  @research_policy.journey_context_page()
}

///|
pub fn course_context_pages() -> Array[String] {
  [
    @research_policy.research_request_context_page(),
    @research_policy.source_hints_context_page(),
    course_quality_repair_path(),
    @research_policy.synthesis_brief_path(),
    @research_policy.evidence_matrix_path(),
    course_workbook_path(),
    course_outline_path(),
    course_synthesis_page_path(),
    course_journey_page_path(),
  ]
}

///|
pub fn course_required_artifact_paths() -> Array[String] {
  [course_outline_path(), course_workbook_path(), course_synthesis_page_path()]
}

///|
pub fn course_required_artifact_sentence() -> String {
  course_required_artifact_paths().map(fn(path) { "`\{path}`" }).join(", ")
}

///|
pub fn course_worker_policy_lines() -> Array[String] {
  [
    "MoonClaw executes the course-writing task; MoonBook owns durable wiki and site projection.",
    "This is a beginner course task, not a research-report task.", "Use evidence only as support behind the lessons; do not expose source audit as the main structure.",
    "Repair artifacts in place; do not create v1/v2/v3 books or alternate report files.",
  ]
}

///|
pub fn course_worker_routine_lines() -> Array[String] {
  [
    "Read `\{wenyu_beginner_course_skill_path()}` and `\{wiki_course_skill_path()}` first.",
    "Write a course outline, beginner workbook, and durable beginner-course synthesis page.",
    "Self-review for lesson count, exercises, checkpoints, Wenyu examples, and process-log leakage.",
  ]
}

///|
pub fn course_worker_memory_summary(book_id : String) -> String {
  "Sanitized MoonTown beginner-course context for `\{book_id}`."
}

///|
pub fn course_worker_prompt(
  display : String,
  original_request : String,
) -> String {
  [
    "Own the MoonClaw beginner-course handoff for \{display}.",
    "",
    "This is COURSE MODE, not research-report mode.",
    "Load `\{wenyu_beginner_course_skill_path()}` and `\{wiki_course_skill_path()}` before writing.",
    "Write \{course_required_artifact_sentence()} as a beginner workbook.",
    "The visible structure must be 10-12 lessons. Each lesson must include Objective, Plain explanation, Why it matters, Wenyu example, Exercise, Output artifact, Checkpoint, and Common mistake.",
    "Do not title anything `Deep Research Analysis`.",
    "Do not lead with Verified Findings, source coverage, blockers, or provider status.",
    "Use screened evidence as support only; the reader-facing shape is a course for beginners.",
    "Original request: \{original_request}",
  ].join("\n")
}

///|
pub fn course_output_contract_lines() -> Array[String] {
  [
    "Return plain Markdown summaries unless a step prompt explicitly asks for JSON.",
    "Required course artifacts: \{course_required_artifact_sentence()}.",
    "`\{course_workbook_path()}` must be a beginner course workbook, not a research report.",
    "Every lesson must include objective, explanation, Wenyu example, exercise, output artifact, checkpoint, and common mistake.",
    "Reject and repair titles or sections that expose `Deep Research Analysis`, `Verified Findings`, or source-audit status as the main course structure.",
  ]
}
