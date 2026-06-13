///|
test "salon schedule uses wall-clock due checks and completion cadence" {
  let schedule = CivicCommunicationSchedule::new(
    id="robotics-salon",
    title="Robotics Salon",
    building_id="social-square",
    topic="embodied AI",
    next_due_ms=10UL,
  )
  assert_true(!civic_communication_is_due(schedule, 9UL))
  assert_true(civic_communication_is_due(schedule, 10UL))
  let next = complete_civic_communication_schedule(
    schedule, 10UL, "robotics-salon-round-1", "done",
  )
  assert_eq(next.round_count, 1)
  assert_eq(next.last_run_ms, 10UL)
  assert_eq(next.next_due_ms, 1_800_010UL)
  assert_eq(next.latest_round_id, "robotics-salon-round-1")
}

///|
test "salon round id and record derive from schedule and metrics" {
  let schedule = CivicCommunicationSchedule::new(
    id="robotics-salon",
    title="Robotics Salon",
    building_id="social-square",
    topic="embodied AI",
    round_count=2,
  )
  assert_eq(civic_communication_round_id(schedule), "robotics-salon-round-3")
  let metrics = CivicCommunicationMetric::{
    participant_count: 2,
    idea_count: 1,
    research_question_count: 3,
    participant_idea_links: 2,
    participating_book_coverage_count: 2,
    idea_return_home_count: 2,
    average_books_per_idea: "2/1 = 2.0",
    structural_effectiveness_score: 72,
    summary: "metric summary",
  }
  let record = civic_communication_round_record(
    schedule, "robotics-salon-round-3", 9, 100UL, 200UL, metrics, "review", "round complete",
  )
  assert_eq(record.round_number, 3)
  assert_eq(record.tick, 9)
  assert_eq(record.structural_effectiveness_score, 72)
  assert_eq(record.summary, "round complete")
}
