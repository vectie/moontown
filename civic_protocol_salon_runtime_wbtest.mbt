///|
test "civic salon scenario carries participant workspaces and cross-area ideas" {
  let scenario = test_civic_salon_scenario()
  let participants = scenario.participants
  let ideas = scenario.ideas
  assert_eq(participants.length(), 2)
  assert_eq(ideas.length(), 1)
  let seen : Array[String] = []
  for participant in participants {
    assert_true(!participant.current_question.is_empty())
    assert_true(!seen.contains(participant.book_id))
    seen.push(participant.book_id)
  }
  for idea in ideas {
    assert_true(idea.participating_books.length() >= 2)
    assert_true(idea.research_questions.length() >= 2)
    assert_true(!idea.next_experiment.is_empty())
    for book_id in idea.participating_books {
      assert_true(seen.contains(book_id))
    }
  }
}

///|
test "civic salon metrics count idea yield and home returns" {
  let scenario = test_civic_salon_scenario()
  let participants = scenario.participants
  let ideas = scenario.ideas
  let metrics = civic_salon_metrics(scenario, participants, ideas)
  let counts = civic_salon_metric_counts(participants, ideas)
  assert_eq(counts.participant_count, 2)
  assert_eq(counts.idea_count, 1)
  assert_eq(counts.research_question_count, 2)
  assert_eq(counts.participant_idea_links, 2)
  assert_eq(counts.participating_book_coverage_count, 2)
  assert_eq(counts.idea_return_home_count, 2)
  assert_eq(metrics.participant_count, 2)
  assert_eq(metrics.idea_count, 1)
  assert_eq(metrics.research_question_count, 2)
  assert_eq(metrics.participant_idea_links, 2)
  assert_eq(metrics.participating_book_coverage_count, 2)
  assert_eq(metrics.idea_return_home_count, 2)
  assert_eq(metrics.average_books_per_idea, "2/1 = 2.0")
  assert_eq(metrics.summary, civic_salon_metric_summary(scenario, counts))
  assert_true(
    metrics.summary.contains("future energy participant perspectives"),
  )
  assert_true(metrics.structural_effectiveness_score > 0)
  for participant in participants {
    let returned = civic_salon_returned_ideas_for_book(
      participant.book_id,
      ideas,
    )
    assert_true(returned.length() > 0)
  }
}

///|
test "civic salon home return records map every idea to home books" {
  let scenario = test_civic_salon_scenario()
  let ideas = scenario.ideas
  let records = civic_salon_home_return_records(
    scenario, "social-square", ideas,
  )
  assert_eq(records.length(), 2)
  for record in records {
    assert_eq(record.target_path, "wiki/queries/salon-returned-ideas.md")
    assert_eq(record.review_status, "pending")
  }
}

///|
test "civic salon runtime summaries keep blocked and seeded states explicit" {
  let scenario = test_civic_salon_scenario()
  let participants = scenario.participants
  let ideas = scenario.ideas
  let metrics = civic_salon_metrics(scenario, participants, ideas)
  assert_eq(
    civic_salon_blocked_summary(
      scenario, "round-1", "reducer produced no outputs.",
    ),
    "Blocked Future Energy Social Square Salon round-1: reducer produced no outputs.",
  )
  let seeded = civic_salon_seeded_summary(
    scenario,
    "round-1",
    participants,
    ideas,
    metrics,
    Some("fixture reducer"),
  )
  assert_true(
    seeded.has_prefix("Seeded Future Energy Social Square Salon round-1:"),
  )
  assert_true(seeded.contains("2 internal participant perspective(s)"))
  assert_true(seeded.contains("1 reviewable pattern output(s)"))
  assert_true(seeded.contains("2 follow-up question(s)"))
  assert_true(seeded.contains("2 returned output-home route(s)."))
  assert_true(seeded.contains("Reducer: fixture reducer"))
  assert_eq(civic_salon_seeded_reducer_suffix(None), "")
}

///|
test "civic salon participant workspaces do not pollute the public catalog" {
  let scenario = test_civic_salon_scenario()
  let workspace_base = "/tmp/moontown-civic-salon-template"
  let stale_participant = civic_protocol_catalog_entry(
    id=scenario.participants[0].book_id,
    name="Old participant",
    purpose="stale intermediate participant book",
    workspace_base~,
  )
  let durable_book = civic_protocol_catalog_entry(
    id=scenario.building_book_id,
    name="Durable building book",
    purpose="public salon aggregate",
    workspace_base~,
  )
  let merged = merge_civic_salon_catalog(
    scenario,
    [durable_book, stale_participant],
    scenario.participants,
    workspace_base,
  )
  assert_eq(merged.length(), 1)
  assert_eq(merged[0].id, scenario.building_book_id)
}
