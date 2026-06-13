///|
fn course_worker_context_bundle(
  entry : BookCatalogEntry,
  bundle : WorkerContextBundle,
) -> WorkerContextBundle {
  let skill_paths = unique_paths([..bundle.skill_paths, ..course_skill_paths()])
  let context_pages = unique_paths(
    [..bundle.context_pages, ..course_context_pages()],
  )
  {
    book_id: bundle.book_id,
    workspace_root: bundle.workspace_root,
    task_id: bundle.task_id,
    prompt: course_worker_prompt(entry, bundle),
    policy: [
      "MoonClaw executes the course-writing task; MoonBook owns durable wiki and site projection.",
      "This is a beginner course task, not a research-report task.", "Use evidence only as support behind the lessons; do not expose source audit as the main structure.",
      "Repair artifacts in place; do not create v1/v2/v3 books or alternate report files.",
    ],
    routines: [
      "Read `skills/wenyu-beginner-course/SKILL.md` and `skills/wiki-course/SKILL.md` first.",
      "Write a course outline, beginner workbook, and durable beginner-course synthesis page.",
      "Self-review for lesson count, exercises, checkpoints, Wenyu examples, and process-log leakage.",
    ],
    skill_paths,
    context_pages,
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: "Sanitized Moontown beginner-course context for `\{entry.id}`.",
    output_contract: course_output_contract_lines(),
  }
}

///|
fn course_skill_paths() -> Array[String] {
  [
    "skills/wenyu-beginner-course/SKILL.md",
    "skills/wiki-course/SKILL.md",
    @research_policy.web_first_research_skill_path(),
    @research_policy.source_diarize_skill_path(),
  ]
}

///|
fn course_context_pages() -> Array[String] {
  [
    "raw/bootstrap/RESEARCH_REQUEST.md",
    "raw/bootstrap/SOURCE_HINTS.md",
    "raw/bootstrap/QUALITY_REPAIR.md",
    "raw/bootstrap/synthesis-brief.md",
    "raw/bootstrap/evidence-matrix.md",
    course_workbook_path(),
    course_outline_path(),
    course_synthesis_page_path(),
    "wiki/history/journey.md",
  ]
}

///|
fn course_outline_path() -> String {
  "raw/bootstrap/course-outline.md"
}

///|
fn course_workbook_path() -> String {
  // Course mode reuses the historical deep-report slot as the visible workbook.
  "raw/bootstrap/deep-report.md"
}

///|
fn course_synthesis_page_path() -> String {
  "wiki/synthesis/beginner-course.md"
}

///|
fn course_required_artifact_paths() -> Array[String] {
  [course_outline_path(), course_workbook_path(), course_synthesis_page_path()]
}

///|
fn course_required_artifact_sentence() -> String {
  course_required_artifact_paths().map(fn(path) { "`\{path}`" }).join(", ")
}

///|
fn course_worker_prompt(
  entry : BookCatalogEntry,
  bundle : WorkerContextBundle,
) -> String {
  let display = display_topic_name(research_topic_id(entry))
  [
    "Own the MoonClaw beginner-course handoff for \{display}.",
    "",
    "This is COURSE MODE, not research-report mode.",
    "Load `skills/wenyu-beginner-course/SKILL.md` and `skills/wiki-course/SKILL.md` before writing.",
    "Write \{course_required_artifact_sentence()} as a beginner workbook.",
    "The visible structure must be 10-12 lessons. Each lesson must include Objective, Plain explanation, Why it matters, Wenyu example, Exercise, Output artifact, Checkpoint, and Common mistake.",
    "Do not title anything `Deep Research Analysis`.",
    "Do not lead with Verified Findings, source coverage, blockers, or provider status.",
    "Use screened evidence as support only; the reader-facing shape is a course for beginners.",
    "Original request: \{bundle.prompt}",
  ].join("\n")
}

///|
fn course_output_contract_lines() -> Array[String] {
  [
    "Return plain Markdown summaries unless a step prompt explicitly asks for JSON.",
    "Required course artifacts: \{course_required_artifact_sentence()}.",
    "`\{course_workbook_path()}` must be a beginner course workbook, not a research report.",
    "Every lesson must include objective, explanation, Wenyu example, exercise, output artifact, checkpoint, and common mistake.",
    "Reject and repair titles or sections that expose `Deep Research Analysis`, `Verified Findings`, or source-audit status as the main course structure.",
  ]
}
