///|
fn civic_communication_participant_projection(
  scenario : CivicCommunicationScenario,
  participant : CivicCommunicationParticipantBook,
  returned_ideas : Array[CivicCommunicationIdea],
  round_id : String,
  round_number : Int32,
) -> Json {
  let fields : Map[String, Json] = Map([])
  fields["book_id"] = ToJson::to_json(participant.book_id)
  fields["visibility"] = ToJson::to_json("internal")
  fields["projection_scope"] = ToJson::to_json("internal")
  fields["tags"] = civic_communication_participant_projection_tags(scenario)
  fields["title"] = ToJson::to_json(
    "\{scenario.domain_label} / \{participant.title}",
  )
  fields["summary"] = ToJson::to_json(participant.contribution)
  fields["status_chips"] = civic_communication_participant_projection_status_chips(
    scenario, returned_ideas, round_number,
  )
  fields["metrics"] = civic_communication_participant_projection_metrics(
    scenario, participant, returned_ideas,
  )
  fields["readiness"] = civic_communication_participant_projection_readiness(
    scenario,
  )
  fields["review_queue"] = civic_communication_participant_projection_review_queue(
    scenario,
  )
  fields["page_families"] = participant_returned_idea_page_families_json(
    returned_ideas,
  )
  fields["journey"] = civic_communication_participant_projection_journey(
    scenario, returned_ideas, round_id, round_number,
  )
  Json::object(fields)
}

///|
fn civic_communication_participant_projection_tags(
  scenario : CivicCommunicationScenario,
) -> Json {
  ToJson::to_json([
    "civic-communication-pattern",
    "internal",
    "participant-workspace",
    scenario.id,
    scenario.building_id,
  ])
}

///|
fn civic_communication_participant_projection_status_chips(
  scenario : CivicCommunicationScenario,
  returned_ideas : Array[CivicCommunicationIdea],
  round_number : Int32,
) -> Json {
  ToJson::to_json([
    participant_projection_chip(
      @civic.communication_pattern_label_for_scenario(scenario),
      "info",
    ),
    participant_projection_chip(scenario.cadence, "healthy"),
    participant_projection_chip("round \{round_number}", "info"),
    participant_projection_chip(
      "returned outputs \{returned_ideas.length()}",
      "review",
    ),
  ])
}

///|
fn civic_communication_participant_projection_metrics(
  scenario : CivicCommunicationScenario,
  participant : CivicCommunicationParticipantBook,
  returned_ideas : Array[CivicCommunicationIdea],
) -> Json {
  ToJson::to_json([
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
  ])
}

///|
fn civic_communication_participant_projection_readiness(
  scenario : CivicCommunicationScenario,
) -> Json {
  ToJson::to_json([
    participant_projection_entry(
      "Returned pattern outputs",
      scenario.returned_ideas_path,
      "Reviewable",
    ),
  ])
}

///|
fn civic_communication_participant_projection_review_queue(
  scenario : CivicCommunicationScenario,
) -> Json {
  ToJson::to_json([
    participant_projection_entry(
      "Review returned outputs",
      scenario.returned_ideas_path,
      "Pending",
    ),
  ])
}

///|
fn civic_communication_participant_projection_journey(
  scenario : CivicCommunicationScenario,
  returned_ideas : Array[CivicCommunicationIdea],
  round_id : String,
  round_number : Int32,
) -> Json {
  ToJson::to_json([
    Json::object({
      "title": ToJson::to_json("Pattern return-home \{round_id}"),
      "stage": ToJson::to_json("distribute"),
      "status": ToJson::to_json("review"),
      "summary": ToJson::to_json(
        "\{scenario.title} returned \{returned_ideas.length()} relevant pattern output(s) to this internal participant workspace in round \{round_number}.",
      ),
      "highlights": Json::array([]),
    }),
  ])
}

///|
fn participant_projection_chip(label : String, tone : String) -> Json {
  Json::object({
    "label": ToJson::to_json(label),
    "tone": ToJson::to_json(tone),
  })
}

///|
fn participant_projection_metric(
  label : String,
  value : String,
  note : String,
  tone : String,
) -> Json {
  Json::object({
    "label": ToJson::to_json(label),
    "value": ToJson::to_json(value),
    "note": ToJson::to_json(note),
    "tone": ToJson::to_json(tone),
  })
}

///|
fn participant_projection_entry(
  title : String,
  detail : String,
  meta : String,
) -> Json {
  Json::object({
    "title": ToJson::to_json(title),
    "detail": ToJson::to_json(detail),
    "meta": ToJson::to_json(meta),
  })
}

///|
fn participant_returned_idea_page_families_json(
  returned_ideas : Array[CivicCommunicationIdea],
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
  ToJson::to_json(items)
}
