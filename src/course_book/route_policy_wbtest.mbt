///|
fn course_book_test_task(
  id~ : String,
  title~ : String,
  kind~ : String,
  prompt~ : String,
) -> @moonbook.BookTask {
  @moonbook.BookTask::new(
    id~,
    title~,
    kind~,
    prompt~,
    priority=100,
    requires_review=true,
  )
}

///|
test "course book task detects course identity from route text" {
  let task = course_book_test_task(
    id="course-wenyu-game-design",
    title="Wenyu beginner learning path",
    kind="standing-watch",
    prompt="Refresh the book with clearer exercises.",
  )
  assert_true(course_book_task(task))
}

///|
test "course book task detects positive course prompt intent" {
  let task = course_book_test_task(
    id="standing-book-quality-repair-wenyu",
    title="Repair book quality",
    kind="standing-watch",
    prompt="Run course projection repair with lessons and checkpoints.",
  )
  assert_true(course_book_task(task))
}

///|
test "course book task ignores negative course mentions" {
  let task = course_book_test_task(
    id="standing-book-quality-repair-wenyu-resident-twins",
    title="Repair civic book quality",
    kind="standing-watch",
    prompt="Do not force a research genre onto civic, course, planbook, cookbook, or operational books.",
  )
  assert_true(!course_book_task(task))
}
