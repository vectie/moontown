///|
priv struct PacketTaskRoute {
  kind : String
  prompt : String
  target_pages : Array[String]
}

///|
fn packet_task_route(task : @moonbook.BookTask) -> PacketTaskRoute {
  let course_task = is_moontown_course_task(task)
  let research_bootstrap = !course_task &&
    @dispatch.research_bootstrap_book_task(task)
  if research_bootstrap {
    {
      kind: provider_task_kind_for_book_task(task),
      prompt: research_bootstrap_task_prompt(),
      target_pages: research_bootstrap_target_pages(),
    }
  } else if course_task {
    {
      kind: provider_task_kind_for_book_task(task),
      prompt: course_task_prompt(),
      target_pages: course_target_pages(),
    }
  } else {
    {
      kind: provider_task_kind_for_book_task(task),
      prompt: task.prompt,
      target_pages: task.target_pages,
    }
  }
}

///|
fn research_bootstrap_task_prompt() -> String {
  [
    "Produce MoonClaw raw research bootstrap artifacts only.", "Use web discovery before local file inspection.",
    "Let the LLM choose sources and claims from screened evidence.", "Do not materialize durable wiki pages in this worker task; MoonBook owns wiki materialization from the raw envelope.",
    "If a tool or source is blocked, write explicit blockers and continue with evidence limits.",
  ].join(" ")
}

///|
fn research_bootstrap_target_pages() -> Array[String] {
  [
    "raw/bootstrap/research-question.md", "raw/bootstrap/search-log.md", "raw/bootstrap/source-screen.md",
    "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/local-sources.md", "raw/bootstrap/synthesis-brief.md",
    "raw/bootstrap/deep-report.md", "raw/bootstrap/marketing-brief.md",
  ]
}

///|
fn course_task_prompt() -> String {
  [
    "Produce MoonClaw beginner-course artifacts only.", "Load `skills/wenyu-beginner-course/SKILL.md` and `skills/wiki-course/SKILL.md` before writing.",
    "Write a beginner workbook, not a research report.", "Use evidence only as support behind lessons.",
    "Do not materialize unrelated durable wiki pages; MoonBook owns broader wiki materialization.",
  ].join(" ")
}

///|
fn course_target_pages() -> Array[String] {
  [
    "raw/bootstrap/course-outline.md", "raw/bootstrap/deep-report.md", "wiki/synthesis/beginner-course.md",
  ]
}

///|
fn is_moontown_course_task(task : @moonbook.BookTask) -> Bool {
  let route_text = "\{task.kind} \{task.id} \{task.title}".to_lower()
  text_contains_any_signal(route_text, course_route_signals()) ||
  positive_course_prompt_signal(task.prompt)
}

///|
fn positive_course_prompt_signal(prompt : String) -> Bool {
  text_contains_any_signal(prompt, positive_course_prompt_signals())
}

///|
fn provider_task_kind_for_book_task(task : @moonbook.BookTask) -> String {
  let combined = "\{task.kind} \{task.title} \{task.prompt}".to_lower()
  if task.kind == "ingest" && combined.contains("bootstrap") {
    "bootstrap_gather"
  } else {
    task.kind
  }
}

///|
fn text_contains_any_signal(text : String, signals : Array[String]) -> Bool {
  let combined = text.to_lower()
  signals.any(fn(signal) { combined.contains(signal) })
}

///|
fn course_route_signals() -> Array[String] {
  ["course", "syllabus", "learning path", "beginner", "workbook", "lesson"]
}

///|
fn positive_course_prompt_signals() -> Array[String] {
  [
    "produce moonclaw beginner-course", "produce beginner-course", "produce course artifacts",
    "write a beginner workbook", "run course projection repair", "create a course",
    "build a course", "generate a course", "syllabus", "learning path", "workbook",
    "lesson",
  ]
}
