///|
fn wenyu_course_index_markdown(entry : @moonbook.BookCatalogEntry) -> String {
  [
    "# Wenyu Valley Game Design Course",
    "",
    "This MoonBook is a course book. It teaches a beginner how to design and implement the Wenyu Valley tile-map UI. It must not be projected as a research report.",
    "",
    "## Ownership",
    "",
    "- MoonBook owns the course syllabus, lessons, exercises, checkpoints, and generated course site.",
    "- Moontown consumes only course progress and visible outputs.",
    "- MoonClaw can generate lesson revisions through the course-builder skill.",
    "",
    "## Book",
    "",
    "- Book id: `\{entry.id}`",
    "- Workspace: `\{entry.workspace_root}`",
    "- Type: `course-book`",
    "",
    "## Start Here",
    "",
    "- `raw/bootstrap/COURSE_CONTRACT.md`",
    "- `raw/bootstrap/course-outline.md`",
    "- `wiki/course/beginner-course.md`",
    "- `wiki/course/exercises.md`",
    "- `wiki/course/progress-rubric.md`",
    "- `skills/course-builder/SKILL.md`",
  ].join("\n")
}

///|
fn wenyu_course_contract_markdown() -> String {
  [
    "# Course Contract", "", "This book teaches. It does not primarily research, operate civic services, or track code plans.",
    "", "## Rules", "", "- Write for a beginner who can learn by doing.", "- Prefer lessons, exercises, checkpoints, diagrams, and expected artifacts.",
    "- Avoid process logs and generic research sections.", "- Explain why each concept matters in Wenyu Valley.",
    "- Keep course progress separate from domain evidence counts.", "- If source research is needed, cite it briefly and convert it into teaching material.",
    "- Never copy a research report verbatim into the course surface. Translate findings into lessons, exercises, examples, and learner checkpoints.",
    "- The course should feel like a guided beginner curriculum, not a survey paper.",
  ].join("\n")
}

///|
fn wenyu_course_outline_markdown() -> String {
  [
    "# Course Outline", "", "This is a beginner curriculum. Each module should teach one design judgment and produce one artifact.",
    "", "1. Read the Wenyu Valley map as product space.", "2. Understand orthographic versus isometric tile-map views.",
    "3. Build a terrain vocabulary: grass, forest, road, water, bridges, plazas.",
    "4. Place buildings as modular civic/service affordances.", "5. Connect paths and agent movement to real task state.",
    "6. Separate editor mode, view mode, and output mode.", "7. Use quality checks before adding visual complexity.",
    "8. Package the final town as a playable/inspectable design handoff.",
  ].join("\n")
}

///|
pub fn course_builder_skill_markdown() -> String {
  [
    "---",
    "name: course-builder",
    "description: Build beginner-friendly course material with lessons, exercises, checkpoints, examples, and artifacts instead of research-report prose.",
    "---",
    "",
    "# Course Builder Skill",
    "",
    "Turn a domain into teachable progression.",
    "",
    "## Required Lesson Shape",
    "",
    "- Learning objective",
    "- Plain-language explanation",
    "- Why this matters",
    "- Wenyu Valley example",
    "- Hands-on exercise",
    "- Expected artifact",
    "- Checkpoint",
    "- Common mistake",
    "",
    "## Quality Bar",
    "",
    "- A beginner can follow it without hidden prior context.",
    "- Each lesson produces an artifact or decision.",
    "- The course should teach judgment, not just commands.",
    "- Do not use research-report headings like `Evidence Matrix` unless the lesson is explicitly about research.",
    "",
    @skill_quality.exploration_quality_contract_section(),
    "",
    "## Concrete Example",
    "",
    "```md",
    "## Lesson: Roads Before Buildings",
    "Objective: explain why movement corridors define useful building placement.",
    "Exercise: draw the three roads an agent must use before placing any pavilion.",
    "Checkpoint: every building entrance touches a path and no road crosses a river without a bridge.",
    "```",
  ].join("\n")
}

///|
fn wenyu_course_exercises_markdown() -> String {
  [
    "# Course Exercises", "", "| Exercise | Artifact | Pass Condition |", "| --- | --- | --- |",
    "| Trace the reference map | labeled terrain sketch | river, lake, road, district, and farm zones are separated |",
    "| Place five civic modules | module placement map | every module has a reason and a path |",
    "| Design one movement loop | route diagram | agents can go home -> building -> output surface -> home |",
    "| Compare styles | style sheet | at least three building visual systems are evaluated |",
  ].join("\n")
}

///|
fn wenyu_course_rubric_markdown() -> String {
  [
    "# Beginner Course Rubric", "", "| Score | Meaning |", "| ---: | --- |", "| 5 | learner can explain, build, and critique a Wenyu tile-map feature |",
    "| 4 | learner can implement the feature with minor guidance |", "| 3 | learner understands the concept but needs execution help |",
    "| 2 | learner copied steps without understanding tradeoffs |", "| 1 | learner cannot connect the lesson to Wenyu Valley |",
  ].join("\n")
}

///|
fn default_wenyu_course_body() -> String {
  [
    "# Wenyu Valley Tile-Map Design: Beginner Course", "", "This course teaches the system behind the town UI: map reading, terrain labels, modular civic buildings, roads, paths, agent movement, editor mode, view mode, and output mode.",
    "", "## How To Use This Course", "", "Work through the lessons in order. Every lesson has a concrete artifact. Do not add visual complexity until the map, routes, building roles, and output mode are coherent.",
    "", "## Lesson 1: Start With The Map", "", "Objective: learn to identify water, roads, farms, forests, civic districts, and open land before adding buildings.",
    "", "Why it matters: a town that starts from random buildings will never feel like a real place. The reference landscape gives constraints first, then architecture.",
    "", "Exercise: label the map before placing anything new.", "", "Expected artifact: a terrain label map with separate layers for water, roads, districts, farms, forests, and future civic modules.",
    "", "Checkpoint: every later building decision can point back to one labeled terrain reason.",
    "", "## Lesson 2: Roads Before Buildings", "", "Objective: design movement corridors before placing pavilions.",
    "", "Exercise: draw the route for an agent going home -> civic building -> output board -> home.",
    "", "Checkpoint: every building entrance touches a path, and every river crossing has a bridge.",
    "", "## Lesson 3: Buildings As Protocols", "", "Objective: treat a building as a place where agents aggregate, exchange, reduce, and distribute information.",
    "", "Exercise: choose one building and write its participants, inputs, outputs, review gates, and visible state.",
    "", "Checkpoint: the building can explain why agents enter, what they produce inside, and what leaves the building.",
  ].join("\n")
}

///|
fn course_body_from_sources(
  source_course : String,
  source_report : String,
) -> String {
  let candidate = if !source_course.trim().is_empty() {
    source_course
  } else if !source_report.trim().is_empty() {
    source_report
  } else {
    ""
  }
  if candidate.trim().is_empty() || looks_research_shaped(candidate) {
    default_wenyu_course_body()
  } else {
    candidate
  }
}

///|
fn looks_research_shaped(text : String) -> Bool {
  let lower = text.to_lower()
  lower.contains("deep research") ||
  lower.contains("research report") ||
  lower.contains("raw/bootstrap/deep-report.md") ||
  lower.contains("evidence matrix") ||
  lower.contains("source-backed") ||
  lower.contains("research question") ||
  lower.contains("thesis:")
}

///|
fn wenyu_course_source_material_markdown(
  source_workspace_root : String,
  source_course : String,
  source_report : String,
) -> String {
  [
    "# Source Material Boundary",
    "",
    "- Source workspace: `\{source_workspace_root}`",
    "- Source course bytes: `\{source_course.length()}`",
    "- Source report bytes: `\{source_report.length()}`",
    "",
    "This file records where the course may learn from. The generated course must translate any source research into beginner lessons, exercises, examples, and checkpoints rather than copying research prose.",
  ].join("\n")
}
