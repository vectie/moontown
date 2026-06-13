///|
fn civic_communication_participant_index(
  scenario : CivicCommunicationScenario,
  participant : CivicCommunicationParticipantBook,
  returned_ideas : Array[CivicCommunicationIdea],
) -> String {
  let pattern = @civic.communication_pattern_for_scenario(scenario)
  [
    "# \{participant.title}",
    "",
    "Internal participant workspace for \{scenario.title}.",
    "",
    "- Focus: \{participant.focus_area}",
    "- Communication pattern: \{pattern.title}",
    "- Cadence: \{participant.cadence}",
    "- Shared building: `\{scenario.building_id}`",
    "- Communication protocol: map current perspective into the building, let the building reduce the exchange into reviewable outputs, then pull relevant follow-up questions back into this home workspace.",
    "",
    "## Perspective",
    "",
    participant.perspective,
    "",
    "## Current Question",
    "",
    participant.current_question,
    "",
    "## Returned Outputs From \{scenario.title}",
    "",
    if returned_ideas.length() == 0 {
      "No returned pattern outputs yet."
    } else {
      "This workspace received \{returned_ideas.length()} reduced output(s) back from \{scenario.title}. See `\{scenario.returned_ideas_path}`."
    },
  ].join("\n")
}

///|
fn civic_communication_participant_contract(
  scenario : CivicCommunicationScenario,
  participant : CivicCommunicationParticipantBook,
) -> String {
  let pattern = @civic.communication_pattern_for_scenario(scenario)
  [
    "# \{scenario.title} Participant Contract",
    "",
    "- Workspace id: `\{participant.book_id}`",
    "- Focus area: \{participant.focus_area}",
    "- Communication pattern: \{pattern.title}",
    "- Pattern cadence: \{participant.cadence}",
    "- Building channel: `\{scenario.protocol_channel}`",
    "- Expected output: short perspective packet, open question, evidence gap, and useful pattern-specific dependency, match, route, lesson gap, story angle, or recovery constraint.",
    "",
    "## Rules",
    "",
    @support.markdown_bullets(scenario.quality_rules),
  ].join("\n")
}

///|
fn civic_communication_participant_perspective(
  participant : CivicCommunicationParticipantBook,
) -> String {
  [
    "# Current Perspective",
    "",
    "## Focus",
    "",
    participant.focus_area,
    "",
    "## Thesis",
    "",
    participant.perspective,
    "",
    "## Contribution To Building Pattern",
    "",
    participant.contribution,
    "",
    "## Open Question",
    "",
    participant.current_question,
  ].join("\n")
}

///|
fn civic_communication_participant_question_page(
  scenario : CivicCommunicationScenario,
  participant : CivicCommunicationParticipantBook,
) -> String {
  [
    "# Open Questions",
    "",
    "## Current Question",
    "",
    participant.current_question,
    "",
    "## What Would Make This Worth Ongoing Follow-up",
    "",
    "- It connects this participant perspective to another \{scenario.domain_label} bottleneck.",
    "- It can become a benchmark, experiment, architecture contract, data schema, route, match, lesson, story, or recovery drill.",
    "- It changes what the shared building should ask next.",
  ].join("\n")
}

///|
fn civic_communication_returned_outputs_page(
  scenario : CivicCommunicationScenario,
  participant : CivicCommunicationParticipantBook,
  returned_ideas : Array[CivicCommunicationIdea],
  round_id : String,
  round_number : Int,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Returned Outputs From \{scenario.title}\n\n")
  builder.write_string(
    "This page records which `\{scenario.building_id}` pattern reductions came back home to `\{participant.book_id}` in round `\{round_id}` (#\{round_number}).\n\n",
  )
  builder.write_string(
    "A returned output is not yet accepted truth. It is a reviewable direction that this home workspace should evaluate, refine, or reject.\n\n",
  )
  if returned_ideas.length() == 0 {
    builder.write_string("No returned ideas for this workspace yet.\n")
  } else {
    builder.write_string(
      "| Output | Why this workspace is involved | Next artifact/action |\n",
    )
    builder.write_string("| --- | --- | --- |\n")
    for idea in returned_ideas {
      builder.write_string(
        "|\{idea.title}|\{idea.summary}|\{idea.next_experiment}|\n",
      )
    }
    builder.write_string("\n## Follow-up Questions\n\n")
    for idea in returned_ideas {
      builder.write_string("### ")
      builder.write_string(idea.title)
      builder.write_string("\n\n")
      for question in idea.research_questions {
        builder.write_string("- ")
        builder.write_string(question)
        builder.write_char('\n')
      }
      builder.write_char('\n')
    }
  }
  builder.to_string()
}
