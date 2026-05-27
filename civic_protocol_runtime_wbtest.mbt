///|
async test "Social Square protocol proof slice has inbox reduction outbox and review" {
  let root = "/tmp/moontown-protocol-social-square"
  ignore_checked_command("rm", ["-rf", root])
  let registry_path = "\{root}/protocols.json"
  let status_path = "\{root}/protocol-status.json"
  ignore(bootstrap_wenyu_building_protocols(registry_path~, status_path~))
  let portfolio = inspect_wenyu_building_protocols(status_path~, registry_path~)
  let social = portfolio.protocols
    .filter(fn(item) { item.building_id == "social-square" })
    .get(0)
    .unwrap()
  assert_eq(social.protocol_mode, "exchange-reduce-distribute")
  assert_eq(social.status, "review")
  assert_true(social.ready)
  assert_eq(social.inbox_count, 1)
  assert_eq(social.contribution_count, 1)
  assert_eq(social.reduction_count, 1)
  assert_eq(social.outbox_count, 1)
  assert_eq(social.review_count, 1)
  assert_true(social.latest_reduction_summary.contains("consent-gated"))
  assert_true(@fs.exists(status_path))
}

///|
test "Protocol status labels follow packet lifecycle" {
  assert_eq(
    protocol_status_label(
      inbox_count=0,
      contribution_count=0,
      reduction_count=0,
      outbox_count=0,
      review_count=0,
    ),
    "defined",
  )
  assert_eq(
    protocol_status_label(
      inbox_count=1,
      contribution_count=0,
      reduction_count=0,
      outbox_count=0,
      review_count=0,
    ),
    "inbox",
  )
  assert_eq(
    protocol_status_label(
      inbox_count=1,
      contribution_count=1,
      reduction_count=1,
      outbox_count=1,
      review_count=0,
    ),
    "reduced",
  )
  assert_eq(
    protocol_status_label(
      inbox_count=1,
      contribution_count=1,
      reduction_count=1,
      outbox_count=1,
      review_count=1,
    ),
    "review",
  )
}

///|
test "Embodied robotics salon has ten subarea books and cross-area ideas" {
  let participants = embodied_robotics_participant_books()
  let ideas = embodied_robotics_salon_ideas()
  assert_eq(participants.length(), 10)
  assert_true(ideas.length() >= 5)
  let seen : Array[String] = []
  for participant in participants {
    assert_true(participant.book_id.has_prefix("embodied-robotics-"))
    assert_true(!participant.current_question.is_empty())
    assert_true(!seen.contains(participant.book_id))
    seen.push(participant.book_id)
  }
  for idea in ideas {
    assert_true(idea.participating_books.length() >= 3)
    assert_true(idea.research_questions.length() >= 3)
    assert_true(!idea.next_experiment.is_empty())
    for book_id in idea.participating_books {
      assert_true(seen.contains(book_id))
    }
  }
}

///|
test "Embodied robotics salon metrics count idea yield and home returns" {
  let participants = embodied_robotics_participant_books()
  let ideas = embodied_robotics_salon_ideas()
  let metrics = embodied_robotics_salon_metrics(participants, ideas)
  assert_eq(metrics.participant_count, 10)
  assert_eq(metrics.idea_count, 5)
  assert_eq(metrics.research_question_count, 15)
  assert_eq(metrics.participant_idea_links, 21)
  assert_eq(metrics.participating_book_coverage_count, 10)
  assert_eq(metrics.idea_return_home_count, 21)
  assert_eq(metrics.average_books_per_idea, "21/5 = 4.2")
  assert_true(metrics.structural_effectiveness_score >= 90)
  for participant in participants {
    let returned = embodied_robotics_returned_ideas_for_book(
      participant.book_id,
      ideas,
    )
    assert_true(returned.length() > 0)
  }
}

///|
test "Embodied robotics home return records map every idea to home books" {
  let ideas = embodied_robotics_salon_ideas()
  let records = embodied_robotics_home_return_records("social-square", ideas)
  assert_eq(records.length(), 21)
  assert_true(
    records
    .filter(fn(record) {
      record.target_book_id == "embodied-robotics-evaluation-safety"
    })
    .length() >=
    4,
  )
  for record in records {
    assert_eq(record.target_path, "wiki/queries/salon-returned-ideas.md")
    assert_eq(record.review_status, "pending")
  }
}
