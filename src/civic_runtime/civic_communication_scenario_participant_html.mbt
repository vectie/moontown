///|
fn civic_salon_participant_html(
  scenario : CivicSalonScenario,
  participant : CivicSalonParticipantBook,
  returned_ideas : Array[CivicSalonIdea],
  round_id : String,
  round_number : Int,
) -> String {
  [
    "<!doctype html>",
    civic_salon_participant_html_head(participant),
    civic_salon_participant_html_body_open(),
    civic_salon_participant_round_meta(scenario, participant, round_number),
    civic_salon_participant_intro(participant, round_id),
    civic_salon_participant_work_sections(participant),
    civic_salon_participant_returned_outputs_heading(),
    civic_salon_returned_idea_cards(returned_ideas),
    civic_salon_participant_html_body_close(),
  ].join("\n")
}

///|
fn civic_salon_returned_idea_cards(
  returned_ideas : Array[CivicSalonIdea],
) -> String {
  if returned_ideas.length() == 0 {
    "<p>No returned outputs yet.</p>"
  } else {
    let builder = StringBuilder::new()
    for idea in returned_ideas {
      builder.write_string(civic_salon_returned_idea_card(idea))
    }
    builder.to_string()
  }
}

///|
fn civic_salon_participant_html_head(
  participant : CivicSalonParticipantBook,
) -> String {
  "<html><head><meta charset=\"utf-8\"><title>\{participant.title}</title>\n\{civic_salon_participant_html_style()}"
}

///|
fn civic_salon_participant_html_style() -> String {
  [
    "<style>", "body{font-family:Georgia,serif;background:#f4f0df;color:#1f2d22;margin:0}",
    "main{max-width:920px;margin:auto;padding:48px 24px}", ".card{background:#fff;border:1px solid #d9d0ad;border-radius:22px;padding:28px;box-shadow:0 18px 50px rgba(58,73,44,.12)}",
    "code{background:#ecf0d5;padding:2px 6px;border-radius:6px}", "</style>",
  ].join("")
}

///|
fn civic_salon_participant_html_body_open() -> String {
  "</head><body><main><section class=\"card\">"
}

///|
fn civic_salon_participant_html_body_close() -> String {
  "</section></main></body></html>"
}

///|
fn civic_salon_participant_round_meta(
  scenario : CivicSalonScenario,
  participant : CivicSalonParticipantBook,
  round_number : Int,
) -> String {
  "<p><code>\{scenario.title}</code> <code>\{participant.cadence}</code> <code>round \{round_number}</code></p>"
}

///|
fn civic_salon_participant_intro(
  participant : CivicSalonParticipantBook,
  round_id : String,
) -> String {
  [
    "<h1>\{participant.title}</h1>",
    "<p><code>\{round_id}</code></p>",
    "<p>\{participant.perspective}</p>",
  ].join("\n")
}

///|
fn civic_salon_participant_work_sections(
  participant : CivicSalonParticipantBook,
) -> String {
  [
    "<h2>Contribution</h2><p>\{participant.contribution}</p>",
    "<h2>Question</h2><p>\{participant.current_question}</p>",
  ].join("\n")
}

///|
fn civic_salon_participant_returned_outputs_heading() -> String {
  "<h2>Returned Outputs</h2>"
}

///|
fn civic_salon_returned_idea_card(idea : CivicSalonIdea) -> String {
  [
    "<article>",
    "<h3>\{idea.title}</h3>",
    "<p>\{idea.summary}</p>",
    "<p><strong>Follow-up questions:</strong> \{idea.research_questions.length()}</p>",
    "<p><strong>Next:</strong> \{idea.next_experiment}</p>",
    "</article>",
  ].join("")
}
