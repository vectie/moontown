///|
fn civic_salon_round_validation_errors(
  scenario : CivicSalonScenario,
  ideas : Array[CivicSalonIdea],
) -> Array[String] {
  let errors : Array[String] = []
  if scenario.participants.length() == 0 {
    errors.push("scenario has no participant workspaces")
  }
  let participant_ids = civic_salon_participant_book_ids(scenario.participants)
  for idea in ideas {
    if idea.id.trim().is_empty() {
      errors.push("idea has empty id")
    }
    if idea.title.trim().is_empty() {
      errors.push("idea `\{idea.id}` has empty title")
    }
    if idea.summary.trim().is_empty() {
      errors.push("idea `\{idea.id}` has empty summary")
    }
    if idea.participating_books.length() == 0 {
      errors.push("idea `\{idea.id}` has no participating books")
    }
    if idea.research_questions.length() == 0 {
      errors.push("idea `\{idea.id}` has no follow-up questions")
    }
    if idea.next_experiment.trim().is_empty() {
      errors.push("idea `\{idea.id}` has empty next experiment")
    }
    for book_id in idea.participating_books {
      if !participant_ids.contains(book_id) {
        errors.push(
          "idea `\{idea.id}` references non-participant book `\{book_id}`",
        )
      }
    }
  }
  errors
}

///|
fn civic_salon_first_packet_id(
  scenario : CivicSalonScenario,
  participants : Array[CivicSalonParticipantBook],
  round_id : String,
) -> String {
  match participants {
    [first, ..] => "pkt-\{scenario.id}-\{round_id}-\{first.book_id}"
    [] => "pkt-\{scenario.id}-\{round_id}-missing-participant"
  }
}

///|
fn civic_salon_first_reduction_id(
  ideas : Array[CivicSalonIdea],
  round_id : String,
) -> String {
  match ideas {
    [first, ..] => "red-\{round_id}-\{first.id}"
    [] => "red-\{round_id}-missing-idea"
  }
}

///|
fn civic_salon_participant_book_ids(
  participants : Array[CivicSalonParticipantBook],
) -> Array[String] {
  participants.map(fn(item) { item.book_id })
}
