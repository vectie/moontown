///|
fn civic_salon_participant_projection(
  scenario : CivicSalonScenario,
  participant : CivicSalonParticipantBook,
  returned_ideas : Array[CivicSalonIdea],
  round_id : String,
  round_number : Int,
) -> Json {
  let fields : Map[String, Json] = {}
  fields["book_id"] = participant.book_id.to_json()
  fields["visibility"] = "internal".to_json()
  fields["projection_scope"] = "internal".to_json()
  fields["tags"] = civic_salon_participant_projection_tags(scenario)
  fields["title"] = "\{scenario.domain_label} / \{participant.title}".to_json()
  fields["summary"] = participant.contribution.to_json()
  fields["status_chips"] = civic_salon_participant_projection_status_chips(
    scenario, returned_ideas, round_number,
  )
  fields["metrics"] = civic_salon_participant_projection_metrics(
    scenario, participant, returned_ideas,
  )
  fields["readiness"] = civic_salon_participant_projection_readiness(scenario)
  fields["review_queue"] = civic_salon_participant_projection_review_queue(
    scenario,
  )
  fields["page_families"] = participant_returned_idea_page_families_json(
    returned_ideas,
  )
  fields["journey"] = civic_salon_participant_projection_journey(
    scenario, returned_ideas, round_id, round_number,
  )
  Json::object(fields)
}

///|
fn civic_salon_participant_projection_tags(
  scenario : CivicSalonScenario,
) -> Json {
  [
    "civic-communication-pattern",
    "internal",
    "participant-workspace",
    scenario.id,
    scenario.building_id,
  ].to_json()
}

///|
fn civic_salon_participant_projection_status_chips(
  scenario : CivicSalonScenario,
  returned_ideas : Array[CivicSalonIdea],
  round_number : Int,
) -> Json {
  [
    participant_projection_chip(@civic.salon_pattern_label(scenario), "info"),
    participant_projection_chip(scenario.cadence, "healthy"),
    participant_projection_chip("round \{round_number}", "info"),
    participant_projection_chip(
      "returned outputs \{returned_ideas.length()}",
      "review",
    ),
  ].to_json()
}

///|
fn civic_salon_participant_projection_metrics(
  scenario : CivicSalonScenario,
  participant : CivicSalonParticipantBook,
  returned_ideas : Array[CivicSalonIdea],
) -> Json {
  [
    participant_projection_metric(
      "Focus",
      participant.focus_area,
      "participant",
      "info",
    ),
    participant_projection_metric(
      "Returned outputs",
      "\{returned_ideas.length()}",
      "from \{scenario.building_id}",
      "healthy",
    ),
  ].to_json()
}

///|
fn civic_salon_participant_projection_readiness(
  scenario : CivicSalonScenario,
) -> Json {
  [
    participant_projection_entry(
      "Returned pattern outputs",
      scenario.returned_ideas_path,
      "Reviewable",
    ),
  ].to_json()
}

///|
fn civic_salon_participant_projection_review_queue(
  scenario : CivicSalonScenario,
) -> Json {
  [
    participant_projection_entry(
      "Review returned outputs",
      scenario.returned_ideas_path,
      "Pending",
    ),
  ].to_json()
}

///|
fn civic_salon_participant_projection_journey(
  scenario : CivicSalonScenario,
  returned_ideas : Array[CivicSalonIdea],
  round_id : String,
  round_number : Int,
) -> Json {
  [
    Json::object({
      "title": "Pattern return-home \{round_id}".to_json(),
      "stage": "distribute".to_json(),
      "status": "review".to_json(),
      "summary": "\{scenario.title} returned \{returned_ideas.length()} relevant pattern output(s) to this internal participant workspace in round \{round_number}.".to_json(),
      "highlights": Json::array([]),
    }),
  ].to_json()
}

///|
fn participant_projection_chip(label : String, tone : String) -> Json {
  Json::object({ "label": label.to_json(), "tone": tone.to_json() })
}

///|
fn participant_projection_metric(
  label : String,
  value : String,
  note : String,
  tone : String,
) -> Json {
  Json::object({
    "label": label.to_json(),
    "value": value.to_json(),
    "note": note.to_json(),
    "tone": tone.to_json(),
  })
}

///|
fn participant_projection_entry(
  title : String,
  detail : String,
  meta : String,
) -> Json {
  Json::object({
    "title": title.to_json(),
    "detail": detail.to_json(),
    "meta": meta.to_json(),
  })
}

///|
fn participant_returned_idea_page_families_json(
  returned_ideas : Array[CivicSalonIdea],
) -> Json {
  let items : Array[Json] = [
    participant_projection_entry(
      "Returned pattern outputs", "wiki/queries/salon-returned-ideas.md", "Follow-up backlog",
    ),
  ]
  for idea in returned_ideas {
    items.push(
      participant_projection_entry(idea.title, idea.id, "Returned output"),
    )
  }
  items.to_json()
}
