///|
test "standing watch prompt requires strict research accounting" {
  let goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Track OPC news",
    prompt="Track latest OPC signals with judgement.",
    target_book_id=Some("research-opc"),
  )
  let prompt = standing_watch_prompt(goal, "research-opc", 12, 2)
  assert_true(prompt.contains("Research temperament"))
  assert_true(prompt.contains("Use imagination"))
  assert_true(prompt.contains("checked_sources_count"))
  assert_true(prompt.contains("accepted_facts_count"))
  assert_true(prompt.contains("wiki_pages_changed_count"))
  assert_true(prompt.contains("book_changed: yes | no"))
  assert_true(prompt.contains("failed and ordinary no_change cycles"))
}

///|
test "book quality repair prompt requires active gap closure" {
  let goal = @core.StandingGoal::new(
    id="book-quality-repair-research-embodied-robotics",
    title="Repair embodied robotics book",
    prompt="Run a source-screening and synthesis pass that creates missing artifacts.",
    target_book_id=Some("research-embodied-robotics"),
  )
  let prompt = standing_watch_prompt(
    goal, "research-embodied-robotics", 18084, 3,
  )
  assert_true(prompt.contains("Book-quality repair mode"))
  assert_true(prompt.contains("wiki/reviews/book-quality-repair.md"))
  assert_true(prompt.contains("Do not return ordinary `no_change`"))
  assert_true(
    prompt.contains("while the repair queue still names missing artifacts"),
  )
  assert_true(prompt.contains("Return `update` when durable book artifacts"))
}
