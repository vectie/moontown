///|
fn civic_salon_building_html(
  scenario : CivicSalonScenario,
  protocol : @civic.BuildingProtocolDefinition,
  participants : Array[CivicSalonParticipantBook],
  ideas : Array[CivicSalonIdea],
  metrics : CivicSalonMetric,
  round_id : String,
  round_number : Int,
) -> String {
  let pattern_label = @civic.communication_pattern_label_for_scenario(scenario)
  [
    "<!doctype html>",
    "<html lang=\"en\">",
    "<head>",
    "  <meta charset=\"utf-8\">",
    "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
    "  <title>\{scenario.title}</title>",
    "  <style>",
    "    body{margin:0;background:#f2eddc;color:#1f2d22;font-family:Georgia,'Times New Roman',serif;}",
    "    main{max-width:1120px;margin:0 auto;padding:52px 24px 80px;}",
    "    .hero{border-radius:30px;padding:38px;background:linear-gradient(135deg,#fff8df,#d7ebc7 58%,#c5e8eb);box-shadow:0 24px 80px rgba(45,65,40,.18);border:1px solid rgba(35,54,33,.16);}",
    "    .eyebrow{font:700 12px system-ui,sans-serif;letter-spacing:.16em;text-transform:uppercase;color:#5d6f3c;}",
    "    h1{font-size:52px;line-height:1;margin:10px 0 16px;}",
    "    h2{margin-top:34px;}",
    "    .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px;margin-top:20px;}",
    "    .metric{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:14px;margin:22px 0 0;}",
    "    .card{background:rgba(255,255,255,.76);border:1px solid rgba(35,54,33,.14);border-radius:20px;padding:18px;}",
    "    .stat{background:rgba(255,255,255,.7);border:1px solid rgba(35,54,33,.16);border-radius:18px;padding:16px;}",
    "    .stat b{display:block;font-size:30px;line-height:1;margin-bottom:6px;}",
    "    .idea{border-left:5px solid #5d8b5b;}",
    "    code{background:rgba(35,54,33,.08);padding:2px 6px;border-radius:7px;}",
    "    li{margin:7px 0;}",
    "  </style>",
    "</head>",
    "<body><main>",
    "  <section class=\"hero\">",
    "    <p class=\"eyebrow\">\{protocol.title} / \{pattern_label}</p>",
    "    <h1>\{scenario.title}</h1>",
    "    <p><code>\{round_id}</code> <code>\{pattern_label}</code> <code>round \{round_number}</code></p>",
    "    <p>\{participants.length()} internal participant perspectives exchange focused views on \{scenario.cadence}, then \{scenario.building_id} reduces the plurality into reviewable outputs worth ongoing work.</p>",
    "    <p><code>\{participants.length()} internal perspectives</code> <code>\{ideas.length()} output reductions</code> <code>review gated</code></p>",
    "    <div class=\"metric\">",
    "      <div class=\"stat\"><b>\{metrics.structural_effectiveness_score}/100</b><span>structural effectiveness</span></div>",
    "      <div class=\"stat\"><b>\{metrics.research_question_count}</b><span>follow-up questions</span></div>",
    "      <div class=\"stat\"><b>\{metrics.idea_return_home_count}</b><span>output-home returns</span></div>",
    "      <div class=\"stat\"><b>\{metrics.average_books_per_idea}</b><span>workspaces per output</span></div>",
    "    </div>",
    "  </section>",
    "  <h2>Internal Perspectives</h2>",
    "  <section class=\"grid\">\{civic_salon_participant_cards(participants)}</section>",
    "  <h2>Reduced Pattern Outputs</h2>",
    "  <section class=\"grid\">\{civic_salon_idea_cards(ideas)}</section>",
    "</main></body></html>",
  ].join("\n")
}

///|
fn civic_salon_participant_cards(
  participants : Array[CivicSalonParticipantBook],
) -> String {
  let builder = StringBuilder::new()
  for participant in participants {
    builder.write_string(
      "<article class=\"card\"><h3>\{participant.title}</h3><p><code>\{participant.book_id}</code></p><p>\{participant.focus_area}</p><p><strong>Question:</strong> \{participant.current_question}</p></article>",
    )
  }
  builder.to_string()
}

///|
fn civic_salon_idea_cards(ideas : Array[CivicSalonIdea]) -> String {
  let builder = StringBuilder::new()
  for idea in ideas {
    builder.write_string(
      "<article class=\"card idea\"><h3>\{idea.title}</h3><p>\{idea.summary}</p><p><strong>Why:</strong> \{idea.why_it_matters}</p><p><strong>Next:</strong> \{idea.next_experiment}</p></article>",
    )
  }
  builder.to_string()
}
