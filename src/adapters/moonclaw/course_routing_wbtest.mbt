///|
test "civic repair prompt mentioning course negatively is not rewritten as course task" {
  let task = moonclaw_adapter_standing_watch_task(
    id="standing-book-quality-repair-wenyu-resident-twins-tick-17941",
    title="Standing watch: Repair book quality: wenyu-resident-twins",
    prompt="Follow the book's own contract and SKILL.md; do not force a research genre onto civic, course, planbook, cookbook, or operational books. Resolve the import-authority blocker, then run one module-native resident-memory packet.",
    target_pages=[
      "wiki/history/journey.md", "wiki/sources/", "wiki/synthesis/overview.md", "raw/bootstrap/",
    ],
  )
  let metadata = packet_step_metadata(Some(task)).stringify()
  assert_true(metadata.contains("module-native resident-memory packet"))
  assert_true(!metadata.contains("Produce MoonClaw beginner-course artifacts"))
  assert_true(!metadata.contains("wiki/synthesis/beginner-course.md"))
}

///|
test "explicit course task still receives course artifact routing" {
  let task = moonclaw_adapter_standing_watch_task(
    id="standing-book-quality-repair-course-wenyu-game-design-tick-17941",
    title="Standing watch: Repair book quality: course-wenyu-game-design",
    prompt="Run course projection repair: enforce course identity, lesson progression, exercises, checkpoints, and beginner usability.",
    target_pages=["wiki/course/beginner-course.md"],
  )
  let metadata = packet_step_metadata(Some(task)).stringify()
  assert_true(metadata.contains("Produce MoonClaw beginner-course artifacts"))
  assert_true(metadata.contains("wiki/synthesis/beginner-course.md"))
}

///|
test "course prompt signal requires positive course intent" {
  assert_true(
    @course_book.positive_course_prompt_signal(
      "Run course projection repair with lessons and checkpoints.",
    ),
  )
  assert_true(
    !@course_book.positive_course_prompt_signal(
      "Do not force a research genre onto civic, course, planbook, cookbook, or operational books.",
    ),
  )
}
