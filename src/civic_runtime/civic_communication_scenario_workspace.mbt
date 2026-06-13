///|
fn merge_civic_salon_catalog(
  scenario : CivicCommunicationScenario,
  catalog : Array[@moonbook.BookCatalogEntry],
  participants : Array[CivicCommunicationParticipantBook],
  workspace_base : String,
) -> Array[@moonbook.BookCatalogEntry] {
  ignore(scenario)
  ignore(workspace_base)
  let merged : Array[@moonbook.BookCatalogEntry] = []
  let participant_ids = civic_salon_participant_book_ids(participants)
  for entry in catalog {
    if !participant_ids.contains(entry.id) {
      merged.push(entry)
    }
  }
  merged
}

///|
fn civic_salon_workspace_root(
  book_id : String,
  workspace_base : String,
) -> String {
  if workspace_base.trim().is_empty() {
    @moonbook.default_workspace_root(book_id)
  } else {
    "\{workspace_base}/books/\{book_id}"
  }
}

///|
async fn write_civic_salon_participant_workspace(
  scenario : CivicCommunicationScenario,
  participant : CivicCommunicationParticipantBook,
  ideas : Array[CivicCommunicationIdea],
  round_id : String,
  round_number : Int,
  root : String,
) -> Unit {
  let returned_ideas = civic_salon_returned_ideas_for_book(
    participant.book_id,
    ideas,
  )
  @support.write_text_file(
    "\{root}/wiki/index.md",
    civic_salon_participant_index(scenario, participant, returned_ideas),
  )
  @support.write_text_file(
    "\{root}/\{scenario.participant_contract_path}",
    civic_salon_participant_contract(scenario, participant),
  )
  @support.write_text_file(
    "\{root}/skills/\{scenario.skill_name}/SKILL.md",
    @civic.salon_participant_skill_text(scenario),
  )
  @support.write_text_file(
    "\{root}/wiki/contributions/current-perspective.md",
    civic_salon_participant_perspective(participant),
  )
  @support.write_text_file(
    "\{root}/\{participant.next_artifact}",
    civic_salon_participant_question_page(scenario, participant),
  )
  @support.write_text_file(
    "\{root}/\{scenario.returned_ideas_path}",
    civic_salon_returned_ideas_page(
      scenario, participant, returned_ideas, round_id, round_number,
    ),
  )
  @support.write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    civic_salon_participant_projection(
      scenario, participant, returned_ideas, round_id, round_number,
    ).stringify(indent=2),
  )
  @support.write_text_file(
    @civic.civic_generated_site_workspace_path(root),
    civic_salon_participant_html(
      scenario, participant, returned_ideas, round_id, round_number,
    ),
  )
}

///|
async fn write_civic_salon_building_pages(
  scenario : CivicCommunicationScenario,
  protocol : @civic.BuildingProtocolDefinition,
  participants : Array[CivicCommunicationParticipantBook],
  ideas : Array[CivicCommunicationIdea],
  metrics : CivicCommunicationMetric,
  round_id : String,
  round_number : Int,
  root : String,
) -> Unit {
  @support.write_text_file(
    "\{root}/\{scenario.synthesis_path}",
    civic_salon_building_synthesis(
      scenario, protocol, participants, ideas, metrics, round_id, round_number,
    ),
  )
  @support.write_text_file(
    "\{root}/\{scenario.backlog_path}",
    civic_salon_idea_backlog(scenario, ideas),
  )
  @support.write_text_file(
    "\{root}/\{scenario.review_path}",
    civic_salon_review_queue(scenario, ideas),
  )
  @support.write_text_file(
    "\{root}/\{scenario.metrics_path}",
    civic_salon_metrics_markdown(
      scenario, metrics, participants, ideas, round_id, round_number,
    ),
  )
  @support.write_text_file(
    "\{root}/raw/bootstrap/\{scenario.id}-metrics.json",
    metrics.to_json().stringify(indent=2),
  )
  @support.write_text_file(
    "\{protocol_ledger_dir(protocol.building_id)}/metrics.json",
    metrics.to_json().stringify(indent=2),
  )
  let html = civic_salon_building_html(
    scenario, protocol, participants, ideas, metrics, round_id, round_number,
  )
  @support.write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    civic_salon_building_projection_json(
      scenario, protocol, participants, ideas, metrics, round_id, round_number,
    ),
  )
  @support.write_text_file("\{root}/book/Home.html", html)
  @support.write_text_file(
    @civic.civic_generated_site_workspace_path(root),
    html,
  )
}
