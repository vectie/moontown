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

///|
test "standing watch ids are compact and stable" {
  assert_eq(
    standing_watch_task_id("Book Quality Repair: Research OPC", 42),
    "standing-book-quality-repair-research-opc-tick-42",
  )
  assert_eq(compact_watch_segment("$$$"), "standing-goal")
  assert_eq(
    standing_watch_task_tick_prefix("Book Quality Repair: Research OPC"),
    "standing-book-quality-repair-research-opc-tick-",
  )
}

///|
test "standing watch ids parse back to matching goal ticks" {
  let goal = @core.StandingGoal::new(
    id="watch-opc-news",
    title="Track OPC news",
    prompt="Track latest OPC signals.",
  )
  assert_true(
    standing_watch_tick_for_goal_task(goal, "standing-watch-opc-news-tick-1440")
    is Some(1440),
  )
  assert_true(
    standing_watch_tick_for_goal_task(goal, "standing-other-tick-1440") is None,
  )
  assert_true(
    standing_goal_for_execution_task(
      [goal],
      "standing-watch-opc-news-tick-1440",
    )
    is Some(_),
  )
}

///|
test "standing watch marker parser owns emitted contract fields" {
  let summary =
    #|standing_goal_decision: update
    #|delta_score: 17
    #|new_source_count=3
    #|book_changed: yes
  assert_true(
    standing_watch_marker_decision(summary.to_lower()) is Some(Update),
  )
  assert_eq(standing_watch_marker_int(summary, "delta_score", fallback=0), 17)
  assert_eq(
    standing_watch_marker_int(summary, "new_source_count", fallback=0),
    3,
  )
  assert_true(
    standing_watch_marker_value(summary, "book_changed") is Some("yes"),
  )
  assert_true(!standing_watch_summary_has_zero_material_delta(summary))
}
