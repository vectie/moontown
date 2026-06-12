///|
pub fn course_book_task(task : @moonbook.BookTask) -> Bool {
  let route_text = "\{task.kind} \{task.id} \{task.title}"
  course_route_text(route_text) || positive_course_prompt_signal(task.prompt)
}

///|
pub fn course_route_text(text : String) -> Bool {
  text_contains_any_signal(text, course_route_signals())
}

///|
pub fn positive_course_prompt_signal(prompt : String) -> Bool {
  text_contains_any_signal(prompt, positive_course_prompt_signals())
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
