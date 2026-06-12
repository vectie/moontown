///|
fn civic_salon_building_projection_json(
  scenario : CivicSalonScenario,
  protocol : @civic.BuildingProtocolDefinition,
  participants : Array[CivicSalonParticipantBook],
  ideas : Array[CivicSalonIdea],
  metrics : CivicSalonMetric,
  round_id : String,
  round_number : Int,
) -> String {
  let pattern = @civic.salon_pattern_for_scenario(scenario)
  let pattern_label = @civic.salon_pattern_label(scenario)
  let highlights : Array[String] = [
    "Round \{round_number}: \{round_id}",
    "\{participants.length()} internal participant perspectives joined the round",
    "\{ideas.length()} reviewable pattern outputs were produced",
    "\{metrics.research_question_count} testable follow-up questions were generated",
    "\{metrics.idea_return_home_count} output-home records were distributed back to internal participant workspaces",
    "Outputs are review-gated before becoming accepted service work",
    "Cadence: \{scenario.cadence}",
  ]
  let summary = "\{participants.length()} \{scenario.domain_label} participant perspectives use the \{pattern_label} pattern through \{scenario.building_id} and reduce into reviewable outputs with testable follow-up questions."
  let journey_title = "\{scenario.title} round \{round_number}"
  let journey_summary = "The building received \{participants.length()} domain perspectives and reduced them into \{ideas.length()} reviewable outputs worth ongoing review."
  [
    "{",
    "  \"book_id\": \{@support.json_string(protocol.book_id)},",
    "  \"visibility\": \"public\",",
    "  \"projection_scope\": \"public\",",
    "  \"tags\": [\"civic-communication-pattern\", \"building-surface\", \{@support.json_string(pattern.id)}, \{@support.json_string(scenario.id)}, \{@support.json_string(scenario.building_id)}],",
    "  \"title\": \{@support.json_string(scenario.title)},",
    "  \"summary\": \{@support.json_string(summary)},",
    "  \"status_chips\": [",
    "    {\"label\":\{@support.json_string(pattern_label)},\"tone\":\"healthy\"},",
    "    {\"label\":\{@support.json_string(scenario.cadence)},\"tone\":\"info\"},",
    "    {\"label\":\"round \{round_number}\",\"tone\":\"info\"},",
    "    {\"label\":\"review gated\",\"tone\":\"review\"}",
    "  ],",
    "  \"metrics\": [",
    "    {\"label\":\"Participant perspectives\",\"value\":\"\{participants.length()}\",\"note\":\"internal workspaces\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Output reductions\",\"value\":\"\{ideas.length()}\",\"note\":\"pattern outputs\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Effectiveness\",\"value\":\"\{metrics.structural_effectiveness_score}/100\",\"note\":\"structural exchange score\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Follow-up questions\",\"value\":\"\{metrics.research_question_count}\",\"note\":\"testable follow-ups\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Home returns\",\"value\":\"\{metrics.idea_return_home_count}\",\"note\":\"idea-workspace routes\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Review gates\",\"value\":\"1\",\"note\":\{@support.json_string(scenario.review_gate)},\"tone\":\"review\"}",
    "  ],",
    "  \"readiness\": [",
    "    {\"title\":\"Building synthesis\",\"detail\":\{@support.json_string(scenario.synthesis_path)},\"meta\":\"Ready\"},",
    "    {\"title\":\"Follow-up backlog\",\"detail\":\{@support.json_string(scenario.backlog_path)},\"meta\":\"Ready\"},",
    "    {\"title\":\"Effectiveness metrics\",\"detail\":\{@support.json_string(scenario.metrics_path)},\"meta\":\"Ready\"},",
    "    {\"title\":\"Review queue\",\"detail\":\{@support.json_string(scenario.review_path)},\"meta\":\"Pending\"}",
    "  ],",
    "  \"review_queue\": [",
    "    {\"title\":\{@support.json_string(scenario.review_gate)},\"detail\":\{@support.json_string(scenario.review_path)},\"meta\":\"Pending\"}",
    "  ],",
    "  \"page_families\": \{projection_page_families_json(participants, ideas)},",
    "  \"journey\": [",
    "    {\"title\":\{@support.json_string(journey_title)},\"stage\":\"exchange-reduce-distribute\",\"status\":\"review\",\"summary\":\{@support.json_string(journey_summary)},\"highlights\": \{@support.json_string_array(highlights)}}",
    "  ],",
    "  \"links\": [",
    "    {\"label\":\"Follow-up backlog\",\"kind\":\"wiki\",\"url\":\{@support.json_string(scenario.backlog_path)}},",
    "    {\"label\":\"Effectiveness metrics\",\"kind\":\"wiki\",\"url\":\{@support.json_string(scenario.metrics_path)}},",
    "    {\"label\":\"Review queue\",\"kind\":\"wiki\",\"url\":\{@support.json_string(scenario.review_path)}}",
    "  ]",
    "}",
  ].join("\n")
}

///|
fn projection_page_families_json(
  participants : Array[CivicSalonParticipantBook],
  ideas : Array[CivicSalonIdea],
) -> String {
  let items : Array[String] = []
  for participant in participants {
    items.push(
      "{\"title\":\{@support.json_string(participant.title)},\"detail\":\{@support.json_string(participant.book_id)},\"meta\":\"Internal perspective\"}",
    )
  }
  for idea in ideas {
    items.push(
      "{\"title\":\{@support.json_string(idea.title)},\"detail\":\{@support.json_string(idea.id)},\"meta\":\"Output reduction\"}",
    )
  }
  "[\{items.join(",")}]"
}
