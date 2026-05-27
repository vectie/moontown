///|
pub async fn bootstrap_civic_salon_scenario_file(
  template_path : String,
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  round_id? : String = "civic-salon-round-001",
  round_number? : Int = 1,
  workspace_base? : String = "",
  reducer_mode? : CivicSalonReductionMode = MoonClawReducer,
) -> String {
  match load_civic_salon_scenario_file(template_path) {
    Some(scenario) =>
      bootstrap_civic_salon_scenario(
        scenario,
        book_catalog_path~,
        round_id~,
        round_number~,
        workspace_base~,
        reducer_mode~,
      )
    None => "Could not load civic salon scenario template: \{template_path}"
  }
}

///|
pub async fn bootstrap_civic_salon_scenario(
  scenario : CivicSalonScenario,
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  round_id? : String = "civic-salon-round-001",
  round_number? : Int = 1,
  workspace_base? : String = "",
  reducer_mode? : CivicSalonReductionMode = MoonClawReducer,
) -> String {
  let reduction = reduce_civic_salon_ideas(
    scenario,
    round_id~,
    round_number~,
    workspace_base~,
    mode=reducer_mode,
  )
  if reduction.status is @core.TaskExecutionStatus::Completed &&
    reduction.ideas.length() > 0 {
    materialize_civic_salon_scenario(
      scenario,
      reduction.ideas,
      book_catalog_path~,
      round_id~,
      round_number~,
      workspace_base~,
      reducer_summary=Some(reduction.summary),
    )
  } else {
    write_civic_salon_reducer_blocker(scenario, reduction, round_id)
    "Blocked \{scenario.title} \{round_id}: \{reduction.summary}"
  }
}

///|
async fn materialize_civic_salon_scenario(
  scenario : CivicSalonScenario,
  ideas : Array[CivicSalonIdea],
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  round_id? : String = "civic-salon-round-001",
  round_number? : Int = 1,
  workspace_base? : String = "",
  reducer_summary? : String? = None,
) -> String {
  if ideas.length() == 0 {
    return "Blocked \{scenario.title} \{round_id}: reducer produced no civic salon ideas."
  }
  let participants = scenario.participants
  let metrics = civic_salon_metrics(scenario, participants, ideas)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let merged_catalog = merge_civic_salon_catalog(
    scenario, catalog, participants, workspace_base,
  )
  @moonbook.save_catalog_file(book_catalog_path, merged_catalog)
  for participant in participants {
    write_civic_salon_participant_workspace(
      scenario,
      participant,
      ideas,
      round_id,
      round_number,
      civic_salon_workspace_root(participant.book_id, workspace_base),
    )
  }
  match @civic.wenyu_building_protocol_for_building_id(scenario.building_id) {
    Some(protocol) => {
      seed_civic_salon_protocol_slice(
        scenario, protocol, participants, ideas, round_id, round_number,
      )
      write_civic_salon_building_pages(
        scenario,
        protocol,
        participants,
        ideas,
        metrics,
        round_id,
        round_number,
        civic_salon_workspace_root(protocol.book_id, workspace_base),
      )
    }
    None => ()
  }
  ignore(write_wenyu_building_protocol_status())
  ignore(write_wenyu_civic_status())
  let source = match reducer_summary {
    Some(summary) => " Reducer: \{summary}"
    None => ""
  }
  "Seeded \{scenario.title} \{round_id}: \{participants.length()} participant MoonBook(s), \{ideas.length()} cross-area idea reduction(s), \{metrics.research_question_count} research question(s), and \{metrics.idea_return_home_count} returned idea-home route(s).\{source}"
}

///|
fn civic_salon_markdown_bullets(items : Array[String]) -> String {
  let builder = StringBuilder::new()
  for item in items {
    builder.write_string("- \{item}\n")
  }
  builder.to_string().trim().to_owned()
}

///|
async fn seed_civic_salon_protocol_slice(
  scenario : CivicSalonScenario,
  protocol : @civic.BuildingProtocolDefinition,
  participants : Array[CivicSalonParticipantBook],
  ideas : Array[CivicSalonIdea],
  round_id : String,
  round_number : Int,
) -> Unit {
  let inputs : Array[Json] = []
  let contributions : Array[Json] = []
  for participant in participants {
    let input_id = "pkt-\{scenario.id}-\{round_id}-\{participant.book_id}"
    inputs.push(
      @civic.BuildingInputPacket::{
        id: input_id,
        building_id: protocol.building_id,
        source_kind: "moonbook_subarea",
        source_id: participant.book_id,
        channel: scenario.protocol_channel,
        privacy_label: "book-public",
        summary: "\{participant.title} joins \{scenario.title} on \{participant.cadence}.",
        payload: "focus=\{participant.focus_area}; question=\{participant.current_question}; contribution=\{participant.contribution}",
        review_status: "accepted",
        idempotency_key: "\{scenario.id}/\{participant.book_id}/round-\{round_number}",
        related_book_id: participant.book_id,
        related_task_id: round_id,
        related_run_id: "protocol-seed",
      }.to_json(),
    )
    contributions.push(
      @civic.BuildingContribution::{
        id: "ctr-\{scenario.id}-\{round_id}-\{participant.book_id}",
        building_id: protocol.building_id,
        contribution_kind: "subarea_perspective",
        input_packet_ids: [input_id],
        summary: participant.contribution,
        basis: [
          "Sub-area MoonBook: \{participant.book_id}",
          "Focus area: \{participant.focus_area}",
          "Current question: \{participant.current_question}",
        ],
        confidence: "medium",
        privacy_label: "book-public",
        review_status: "accepted",
        idempotency_key: "\{scenario.id}/contribution/\{participant.book_id}/round-\{round_number}",
      }.to_json(),
    )
  }
  let reductions : Array[Json] = []
  let outbox : Array[Json] = []
  for idea in ideas {
    reductions.push(
      @civic.BuildingReductionResult::{
        id: "red-\{round_id}-\{idea.id}",
        building_id: protocol.building_id,
        reduction_kind: scenario.reduction_kind,
        decision: "update",
        summary: "\{idea.title}: \{idea.summary}",
        contribution_ids: idea.participating_books.map(fn(book_id) {
          "ctr-\{scenario.id}-\{round_id}-\{book_id}"
        }),
        output_channel: scenario.output_channel,
        distribution_targets: [
          "moonbook:\{scenario.building_book_id}/\{scenario.backlog_path}",
          "projection:module/\{scenario.building_id}",
          ..idea.participating_books.map(fn(book_id) {
            "moonbook:\{book_id}/wiki/queries/open-questions.md"
          }),
        ],
        changed_pages: [scenario.backlog_path, scenario.synthesis_path],
        accepted_records: [
          idea.summary,
          "Next experiment: \{idea.next_experiment}",
        ],
        review_items: [scenario.review_reason],
        review_status: "pending",
        idempotency_key: "\{scenario.id}/reduction/\{idea.id}/round-\{round_number}",
        related_book_id: protocol.book_id,
      }.to_json(),
    )
    outbox.push(
      @civic.BuildingDistributionRecord::{
        id: "out-\{round_id}-\{idea.id}",
        building_id: protocol.building_id,
        target_kind: "moonbook_question_backlog",
        target_id: protocol.book_id,
        target_path: scenario.backlog_path,
        summary: "Distributed cross-area question set for `\{idea.title}` to \{idea.participating_books.length()} sub-area MoonBook(s).",
        review_status: "pending",
        idempotency_key: "\{scenario.id}/outbox/\{idea.id}/round-\{round_number}",
      }.to_json(),
    )
  }
  let review = @civic.BuildingReviewGateRecord::{
    id: "rev-\{round_id}",
    building_id: protocol.building_id,
    gate: scenario.review_gate,
    status: "pending",
    reason: scenario.review_reason,
    related_packet_id: "pkt-\{scenario.id}-\{round_id}-\{participants.get(0).unwrap().book_id}",
    related_reduction_id: "red-\{round_id}-\{ideas.get(0).unwrap().id}",
    owner: scenario.review_owner,
  }
  write_protocol_jsonl_records(
    protocol.building_id,
    "participants",
    participants.map(fn(item) { item.to_json() }),
  )
  write_protocol_jsonl_records(
    protocol.building_id,
    "ideas",
    ideas.map(fn(item) { item.to_json() }),
  )
  write_protocol_jsonl_records(protocol.building_id, "inbox", inputs)
  write_protocol_jsonl_records(
    protocol.building_id,
    "contributions",
    contributions,
  )
  write_protocol_jsonl_records(protocol.building_id, "reductions", reductions)
  write_protocol_jsonl_records(protocol.building_id, "outbox", outbox)
  write_protocol_jsonl_records(
    protocol.building_id,
    "home_returns",
    civic_salon_home_return_records(
      scenario,
      protocol.building_id,
      ideas,
      round_id~,
    ).map(fn(item) { item.to_json() }),
  )
  write_protocol_jsonl_records(protocol.building_id, "reviews", [
    review.to_json(),
  ])
}

///|
async fn load_civic_salon_scenario_file(path : String) -> CivicSalonScenario? {
  if !@fs.exists(path) {
    return None
  }
  let text = @fs.read_file(path).text() catch { _ => return None }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed)) catch {
    _ => None
  }
}

///|
async fn load_civic_salon_scenario_for_schedule(
  schedule : CivicSalonSchedule,
  snapshot_path : String,
) -> CivicSalonScenario? {
  let template_path = civic_salon_scenario_path(schedule.id, snapshot_path~)
  load_civic_salon_scenario_file(template_path)
}

///|
fn civic_salon_metrics(
  scenario : CivicSalonScenario,
  participants : Array[CivicSalonParticipantBook],
  ideas : Array[CivicSalonIdea],
) -> CivicSalonMetric {
  let research_question_count = civic_salon_research_question_count(ideas)
  let participant_idea_links = civic_salon_participant_idea_link_count(ideas)
  let participating_book_coverage_count = civic_salon_covered_book_count(ideas)
  let idea_return_home_count = participant_idea_links
  let average_books_per_idea = civic_salon_average_books_per_idea_label(ideas)
  let structural_effectiveness_score = civic_salon_structural_score(
    participant_count=participants.length(),
    idea_count=ideas.length(),
    research_question_count~,
    participating_book_coverage_count~,
    idea_return_home_count~,
    participant_idea_links~,
  )
  {
    participant_count: participants.length(),
    idea_count: ideas.length(),
    research_question_count,
    participant_idea_links,
    participating_book_coverage_count,
    idea_return_home_count,
    average_books_per_idea,
    structural_effectiveness_score,
    summary: "The salon converted \{participants.length()} \{scenario.domain_label} participant perspectives into \{ideas.length()} cross-area ideas, \{research_question_count} testable questions, and \{idea_return_home_count} returned idea-home records.",
  }
}

///|
fn civic_salon_research_question_count(ideas : Array[CivicSalonIdea]) -> Int {
  let mut count = 0
  for idea in ideas {
    count += idea.research_questions.length()
  }
  count
}

///|
fn civic_salon_participant_idea_link_count(
  ideas : Array[CivicSalonIdea],
) -> Int {
  let mut count = 0
  for idea in ideas {
    count += idea.participating_books.length()
  }
  count
}

///|
fn civic_salon_covered_book_count(ideas : Array[CivicSalonIdea]) -> Int {
  let covered : Array[String] = []
  for idea in ideas {
    for book_id in idea.participating_books {
      if !covered.contains(book_id) {
        covered.push(book_id)
      }
    }
  }
  covered.length()
}

///|
fn civic_salon_average_books_per_idea_label(
  ideas : Array[CivicSalonIdea],
) -> String {
  if ideas.length() == 0 {
    "0"
  } else {
    let links = civic_salon_participant_idea_link_count(ideas)
    let scaled = links * 10 / ideas.length()
    "\{links}/\{ideas.length()} = \{scaled / 10}.\{scaled % 10}"
  }
}

///|
fn civic_salon_score_component(value : Int, target : Int, max : Int) -> Int {
  if target <= 0 {
    0
  } else if value >= target {
    max
  } else {
    value * max / target
  }
}

///|
fn civic_salon_structural_score(
  participant_count~ : Int,
  idea_count~ : Int,
  research_question_count~ : Int,
  participating_book_coverage_count~ : Int,
  idea_return_home_count~ : Int,
  participant_idea_links~ : Int,
) -> Int {
  civic_salon_score_component(participant_count, 10, 20) +
  civic_salon_score_component(idea_count, 5, 20) +
  civic_salon_score_component(research_question_count, 15, 20) +
  civic_salon_score_component(
    participating_book_coverage_count, participant_count, 20,
  ) +
  civic_salon_score_component(
    idea_return_home_count, participant_idea_links, 20,
  )
}

///|
fn civic_salon_returned_ideas_for_book(
  book_id : String,
  ideas : Array[CivicSalonIdea],
) -> Array[CivicSalonIdea] {
  ideas.filter(fn(idea) { idea.participating_books.contains(book_id) })
}

///|
fn civic_salon_home_return_records(
  scenario : CivicSalonScenario,
  building_id : String,
  ideas : Array[CivicSalonIdea],
  round_id? : String = "civic-salon-round-001",
) -> Array[CivicSalonHomeReturn] {
  let records : Array[CivicSalonHomeReturn] = []
  for idea in ideas {
    for book_id in idea.participating_books {
      records.push({
        id: "home-\{round_id}-\{idea.id}-\{book_id}",
        building_id,
        idea_id: idea.id,
        target_book_id: book_id,
        target_path: scenario.returned_ideas_path,
        summary: "Returned `\{idea.title}` to \{book_id} for review and follow-up research shaping.",
        review_status: "pending",
      })
    }
  }
  records
}

///|
fn merge_civic_salon_catalog(
  scenario : CivicSalonScenario,
  catalog : Array[@moonbook.BookCatalogEntry],
  participants : Array[CivicSalonParticipantBook],
  workspace_base : String,
) -> Array[@moonbook.BookCatalogEntry] {
  let merged : Array[@moonbook.BookCatalogEntry] = []
  for entry in catalog {
    if !civic_salon_participant_book_ids(participants).contains(entry.id) {
      merged.push(entry)
    }
  }
  for participant in participants {
    merged.push(
      civic_salon_catalog_entry(scenario, participant, workspace_base),
    )
  }
  merged
}

///|
fn civic_salon_participant_book_ids(
  participants : Array[CivicSalonParticipantBook],
) -> Array[String] {
  participants.map(fn(item) { item.book_id })
}

///|
fn civic_salon_catalog_entry(
  scenario : CivicSalonScenario,
  participant : CivicSalonParticipantBook,
  workspace_base : String,
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id=participant.book_id,
    name="\{scenario.domain_label} / \{participant.title}",
    purpose="Participant MoonBook for \{participant.focus_area}; participates in \{scenario.title} and maintains durable questions, evidence, and research memory.",
    workspace_root=civic_salon_workspace_root(
      participant.book_id,
      workspace_base,
    ),
    memory_scope=@core.MemoryScope::BookPrivate,
    tags=[
      scenario.id,
      "protocol-salon",
      scenario.building_id,
      "subarea",
      participant.book_id,
    ],
    skills=[
      scenario.skill_name,
      "research-question-generation",
      "cross-area-synthesis",
      "review",
    ],
  )
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
  scenario : CivicSalonScenario,
  participant : CivicSalonParticipantBook,
  ideas : Array[CivicSalonIdea],
  round_id : String,
  round_number : Int,
  root : String,
) -> Unit {
  let returned_ideas = civic_salon_returned_ideas_for_book(
    participant.book_id,
    ideas,
  )
  write_text_file(
    "\{root}/wiki/index.md",
    civic_salon_participant_index(scenario, participant, returned_ideas),
  )
  write_text_file(
    "\{root}/\{scenario.participant_contract_path}",
    civic_salon_participant_contract(scenario, participant),
  )
  write_text_file(
    "\{root}/skills/\{scenario.skill_name}/SKILL.md",
    civic_salon_skill_text(scenario),
  )
  write_text_file(
    "\{root}/wiki/contributions/current-perspective.md",
    civic_salon_participant_perspective(participant),
  )
  write_text_file(
    "\{root}/\{participant.next_artifact}",
    civic_salon_participant_question_page(scenario, participant),
  )
  write_text_file(
    "\{root}/\{scenario.returned_ideas_path}",
    civic_salon_returned_ideas_page(
      scenario, participant, returned_ideas, round_id, round_number,
    ),
  )
  write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    civic_salon_participant_projection(
      scenario, participant, returned_ideas, round_id, round_number,
    ).stringify(indent=2),
  )
  write_text_file(
    "\{root}/book/site/generated/index.html",
    civic_salon_participant_html(
      scenario, participant, returned_ideas, round_id, round_number,
    ),
  )
}

///|
async fn write_civic_salon_building_pages(
  scenario : CivicSalonScenario,
  protocol : @civic.BuildingProtocolDefinition,
  participants : Array[CivicSalonParticipantBook],
  ideas : Array[CivicSalonIdea],
  metrics : CivicSalonMetric,
  round_id : String,
  round_number : Int,
  root : String,
) -> Unit {
  write_text_file(
    "\{root}/\{scenario.synthesis_path}",
    civic_salon_building_synthesis(
      scenario, protocol, participants, ideas, metrics, round_id, round_number,
    ),
  )
  write_text_file(
    "\{root}/\{scenario.backlog_path}",
    civic_salon_idea_backlog(scenario, ideas),
  )
  write_text_file(
    "\{root}/\{scenario.review_path}",
    civic_salon_review_queue(scenario, ideas),
  )
  write_text_file(
    "\{root}/\{scenario.metrics_path}",
    civic_salon_metrics_markdown(
      scenario, metrics, participants, ideas, round_id, round_number,
    ),
  )
  write_text_file(
    "\{root}/raw/bootstrap/\{scenario.id}-metrics.json",
    metrics.to_json().stringify(indent=2),
  )
  write_text_file(
    "\{protocol_ledger_dir(protocol.building_id)}/metrics.json",
    metrics.to_json().stringify(indent=2),
  )
  let html = civic_salon_building_html(
    scenario, protocol, participants, ideas, metrics, round_id, round_number,
  )
  write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    civic_salon_building_projection_json(
      scenario, protocol, participants, ideas, metrics, round_id, round_number,
    ),
  )
  write_text_file("\{root}/book/Home.html", html)
  write_text_file("\{root}/book/site/generated/index.html", html)
}

///|
fn civic_salon_participant_index(
  scenario : CivicSalonScenario,
  participant : CivicSalonParticipantBook,
  returned_ideas : Array[CivicSalonIdea],
) -> String {
  [
    "# \{participant.title}",
    "",
    "Participant MoonBook for \{scenario.title}.",
    "",
    "- Focus: \{participant.focus_area}",
    "- Cadence: \{participant.cadence}",
    "- Shared building: `\{scenario.building_id}`",
    "- Communication protocol: map current perspective into the building, let the building reduce cross-area tensions into questions, then pull relevant questions back into this book.",
    "",
    "## Perspective",
    "",
    participant.perspective,
    "",
    "## Current Question",
    "",
    participant.current_question,
    "",
    "## Returned Ideas From \{scenario.title}",
    "",
    if returned_ideas.length() == 0 {
      "No returned salon ideas yet."
    } else {
      "This book received \{returned_ideas.length()} reduced idea(s) back from \{scenario.title}. See `\{scenario.returned_ideas_path}`."
    },
  ].join("\n")
}

///|
fn civic_salon_participant_contract(
  scenario : CivicSalonScenario,
  participant : CivicSalonParticipantBook,
) -> String {
  [
    "# \{scenario.title} Participant Contract",
    "",
    "- Book id: `\{participant.book_id}`",
    "- Focus area: \{participant.focus_area}",
    "- Salon cadence: \{participant.cadence}",
    "- Building channel: `\{scenario.protocol_channel}`",
    "- Expected output: short perspective packet, open question, evidence gap, and useful cross-area dependency.",
    "",
    "## Rules",
    "",
    civic_salon_markdown_bullets(scenario.quality_rules),
  ].join("\n")
}

///|
fn civic_salon_skill_text(scenario : CivicSalonScenario) -> String {
  [
    "---",
    "name: \{scenario.skill_name}",
    "description: \{scenario.skill_description}",
    "---",
    "",
    "# \{scenario.title} Skill",
    "",
    "This skill is for a participant MoonBook entering a shared building protocol.",
    "",
    "## Behavior",
    "",
    civic_salon_markdown_bullets(scenario.skill_rules),
    "",
    "## Output Example",
    "",
    "```md",
    "salon_decision: update",
    "subarea: VLA",
    "bottleneck: short-horizon demos hide recovery failures",
    "cross_area_dependency: world models and safety evaluation",
    "research_question: How should a VLA policy revise its plan when the expected tool is missing?",
    "next_artifact: wiki/queries/vla-long-horizon-eval.md",
    "```",
  ].join("\n")
}

///|
fn civic_salon_participant_perspective(
  participant : CivicSalonParticipantBook,
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
    "## Contribution To Salon",
    "",
    participant.contribution,
    "",
    "## Open Question",
    "",
    participant.current_question,
  ].join("\n")
}

///|
fn civic_salon_participant_question_page(
  scenario : CivicSalonScenario,
  participant : CivicSalonParticipantBook,
) -> String {
  [
    "# Open Questions",
    "",
    "## Current Question",
    "",
    participant.current_question,
    "",
    "## What Would Make This Worth Ongoing Research",
    "",
    "- It connects this participant perspective to another \{scenario.domain_label} bottleneck.",
    "- It can become a benchmark, experiment, architecture contract, or data schema.",
    "- It changes what the shared building should ask next.",
  ].join("\n")
}

///|
fn civic_salon_returned_ideas_page(
  scenario : CivicSalonScenario,
  participant : CivicSalonParticipantBook,
  returned_ideas : Array[CivicSalonIdea],
  round_id : String,
  round_number : Int,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Returned Ideas From \{scenario.title}\n\n")
  builder.write_string(
    "This page records which `\{scenario.building_id}` salon reductions came back home to `\{participant.book_id}` in round `\{round_id}` (#\{round_number}).\n\n",
  )
  builder.write_string(
    "A returned idea is not yet accepted truth. It is a reviewable research direction that this sub-area book should evaluate, refine, or reject.\n\n",
  )
  if returned_ideas.length() == 0 {
    builder.write_string("No returned ideas for this book yet.\n")
  } else {
    builder.write_string(
      "| Idea | Why this book is involved | Next experiment |\n",
    )
    builder.write_string("| --- | --- | --- |\n")
    for idea in returned_ideas {
      builder.write_string(
        "|\{idea.title}|\{idea.summary}|\{idea.next_experiment}|\n",
      )
    }
    builder.write_string("\n## Research Questions\n\n")
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

///|
fn civic_salon_participant_projection(
  scenario : CivicSalonScenario,
  participant : CivicSalonParticipantBook,
  returned_ideas : Array[CivicSalonIdea],
  round_id : String,
  round_number : Int,
) -> Json {
  @json.parse(
    "{ \"title\": \"\{json_escape(scenario.domain_label)} / \{json_escape(participant.title)}\", \"summary\": \"\{json_escape(participant.contribution)}\", \"status_chips\": [{\"label\":\"protocol salon\",\"tone\":\"info\"},{\"label\":\"\{json_escape(scenario.cadence)}\",\"tone\":\"healthy\"},{\"label\":\"round \{round_number}\",\"tone\":\"info\"},{\"label\":\"returned ideas \{returned_ideas.length()}\",\"tone\":\"review\"}], \"metrics\": [{\"label\":\"Focus\",\"value\":\"\{json_escape(participant.focus_area)}\",\"note\":\"participant\",\"tone\":\"info\"},{\"label\":\"Returned ideas\",\"value\":\"\{returned_ideas.length()}\",\"note\":\"from \{json_escape(scenario.building_id)}\",\"tone\":\"healthy\"}], \"readiness\": [{\"title\":\"Returned salon ideas\",\"detail\":\"\{json_escape(scenario.returned_ideas_path)}\",\"meta\":\"Reviewable\"}], \"review_queue\": [{\"title\":\"Review returned ideas\",\"detail\":\"\{json_escape(scenario.returned_ideas_path)}\",\"meta\":\"Pending\"}], \"page_families\": \{participant_returned_idea_page_families_json(returned_ideas)}, \"journey\": [{\"title\":\"Salon return-home \{json_escape(round_id)}\",\"stage\":\"distribute\",\"status\":\"review\",\"summary\":\"\{json_escape(scenario.title)} returned \{returned_ideas.length()} relevant cross-area idea(s) to this participant book in round \{round_number}.\",\"highlights\": []}] }",
  ) catch {
    _ => Json::object({})
  }
}

///|
fn participant_returned_idea_page_families_json(
  returned_ideas : Array[CivicSalonIdea],
) -> String {
  let items : Array[String] = [
    "{\"title\":\"Returned salon ideas\",\"detail\":\"wiki/queries/salon-returned-ideas.md\",\"meta\":\"Question backlog\"}",
  ]
  for idea in returned_ideas {
    items.push(
      "{\"title\":\{json_string(idea.title)},\"detail\":\{json_string(idea.id)},\"meta\":\"Returned idea\"}",
    )
  }
  "[\{items.join(",")}]"
}

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
    "<html><head><meta charset=\"utf-8\"><title>\{participant.title}</title>",
    "<style>body{font-family:Georgia,serif;background:#f4f0df;color:#1f2d22;margin:0}main{max-width:920px;margin:auto;padding:48px 24px}.card{background:#fff;border:1px solid #d9d0ad;border-radius:22px;padding:28px;box-shadow:0 18px 50px rgba(58,73,44,.12)}code{background:#ecf0d5;padding:2px 6px;border-radius:6px}</style>",
    "</head><body><main><section class=\"card\">",
    "<p><code>\{scenario.title}</code> <code>\{participant.cadence}</code> <code>round \{round_number}</code></p>",
    "<h1>\{participant.title}</h1>",
    "<p><code>\{round_id}</code></p>",
    "<p>\{participant.perspective}</p>",
    "<h2>Contribution</h2><p>\{participant.contribution}</p>",
    "<h2>Question</h2><p>\{participant.current_question}</p>",
    "<h2>Returned Ideas</h2>",
    civic_salon_returned_idea_cards(returned_ideas),
    "</section></main></body></html>",
  ].join("\n")
}

///|
fn civic_salon_returned_idea_cards(
  returned_ideas : Array[CivicSalonIdea],
) -> String {
  if returned_ideas.length() == 0 {
    "<p>No returned ideas yet.</p>"
  } else {
    let builder = StringBuilder::new()
    for idea in returned_ideas {
      builder.write_string(
        "<article><h3>\{idea.title}</h3><p>\{idea.summary}</p><p><strong>Questions:</strong> \{idea.research_questions.length()}</p><p><strong>Next:</strong> \{idea.next_experiment}</p></article>",
      )
    }
    builder.to_string()
  }
}

///|
fn civic_salon_building_synthesis(
  scenario : CivicSalonScenario,
  protocol : @civic.BuildingProtocolDefinition,
  participants : Array[CivicSalonParticipantBook],
  ideas : Array[CivicSalonIdea],
  metrics : CivicSalonMetric,
  round_id : String,
  round_number : Int,
) -> String {
  [
    "# \{scenario.title}",
    "",
    "- Round: `\{round_id}`",
    "- Round number: `\{round_number}`",
    "",
    "This is a live protocol test for `\{protocol.title}` as a domain exchange building. Participant MoonBooks contribute focused perspectives, and the building reduces them into research ideas and questions worth ongoing work.",
    "",
    "## Participants",
    "",
    civic_salon_participant_table(participants),
    "",
    "## Cross-area Ideas",
    "",
    civic_salon_idea_sections(ideas),
    "",
    "## Effectiveness Metrics",
    "",
    civic_salon_metrics_table(metrics),
    "",
    "This metric is structural: it proves the building moved from exchange to reduction to distribution. It does not claim the ideas are correct; the review queue still decides which become accepted research programs.",
    "",
    "## Quality Standard",
    "",
    civic_salon_markdown_bullets(scenario.quality_rules),
  ].join("\n")
}

///|
fn civic_salon_idea_backlog(
  scenario : CivicSalonScenario,
  ideas : Array[CivicSalonIdea],
) -> String {
  [
    "# \{scenario.title} Open Question Backlog",
    "",
    "Questions generated by \{scenario.title}.",
    "",
    civic_salon_idea_sections(ideas),
  ].join("\n")
}

///|
fn civic_salon_review_queue(
  scenario : CivicSalonScenario,
  ideas : Array[CivicSalonIdea],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# \{scenario.title} Review\n\n")
  builder.write_string("| ID | Idea | Review Need | Status |\n")
  builder.write_string("| --- | --- | --- | --- |\n")
  for idea in ideas {
    builder.write_string(
      "|\{idea.id}|\{idea.title}|\{scenario.review_reason}|pending|\n",
    )
  }
  builder.to_string()
}

///|
fn civic_salon_metrics_markdown(
  scenario : CivicSalonScenario,
  metrics : CivicSalonMetric,
  participants : Array[CivicSalonParticipantBook],
  ideas : Array[CivicSalonIdea],
  round_id : String,
  round_number : Int,
) -> String {
  [
    "# \{scenario.title} Effectiveness Metrics",
    "",
    "- Round: `\{round_id}`",
    "- Round number: `\{round_number}`",
    "",
    metrics.summary,
    "",
    "These metrics evaluate whether the building actually held an exchange, reduced new shared ideas, and returned them to the right home MoonBooks. They do not certify scientific truth; they certify protocol effectiveness for this round.",
    "",
    "## Score",
    "",
    "- Structural effectiveness score: \{metrics.structural_effectiveness_score}/100",
    "- Participant books: \{metrics.participant_count}",
    "- Cross-area idea reductions: \{metrics.idea_count}",
    "- Research questions generated: \{metrics.research_question_count}",
    "- Participant-idea links: \{metrics.participant_idea_links}",
    "- Books covered by at least one idea: \{metrics.participating_book_coverage_count}/\{participants.length()}",
    "- Idea-home return records: \{metrics.idea_return_home_count}",
    "- Average books per idea: \{metrics.average_books_per_idea}",
    "",
    "## Formula",
    "",
    "The structural score allocates 20 points each to participant coverage, idea yield, research-question yield, book coverage, and return-home completion.",
    "",
    "## Ideas",
    "",
    civic_salon_idea_metric_table(ideas),
    "",
    "## Return Home Contract",
    "",
    "Each participating book receives `\{scenario.returned_ideas_path}` with the reduced ideas relevant to its perspective. That page is the next place for each home book to review, accept, refine, or reject the salon output.",
  ].join("\n")
}

///|
fn civic_salon_metrics_table(metrics : CivicSalonMetric) -> String {
  [
    "| Metric | Value | Meaning |",
    "| --- | ---: | --- |",
    "| Structural effectiveness score | \{metrics.structural_effectiveness_score}/100 | Exchange-reduce-distribute completion, not truth certification |",
    "| Participant books | \{metrics.participant_count} | Distinct sub-area MoonBooks in the salon |",
    "| Idea reductions | \{metrics.idea_count} | New cross-area ideas produced by the building |",
    "| Research questions | \{metrics.research_question_count} | Testable questions attached to those ideas |",
    "| Participant-idea links | \{metrics.participant_idea_links} | Cross-pollination edges between ideas and home books |",
    "| Covered books | \{metrics.participating_book_coverage_count} | Books receiving at least one returned idea |",
    "| Return-home records | \{metrics.idea_return_home_count} | Idea-to-book distributions written back home |",
    "| Average books per idea | \{metrics.average_books_per_idea} | Breadth of each reduced idea |",
  ].join("\n")
}

///|
fn civic_salon_idea_metric_table(ideas : Array[CivicSalonIdea]) -> String {
  let builder = StringBuilder::new()
  builder.write_string("| Idea | Books | Questions | Home books |\n")
  builder.write_string("| --- | ---:| ---:| --- |\n")
  for idea in ideas {
    builder.write_string(
      "|\{idea.title}|\{idea.participating_books.length()}|\{idea.research_questions.length()}|`\{idea.participating_books.join("`, `")}`|\n",
    )
  }
  builder.to_string().trim().to_owned()
}

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
  let highlights : Array[String] = [
    "Round \{round_number}: \{round_id}",
    "\{participants.length()} participant MoonBooks joined the round",
    "\{ideas.length()} cross-area idea reductions were produced",
    "\{metrics.research_question_count} testable research questions were generated",
    "\{metrics.idea_return_home_count} idea-home records were distributed back to participant books",
    "Outputs are review-gated before becoming long-horizon research programs",
    "Cadence: \{scenario.cadence}",
  ]
  let summary = "\{participants.length()} \{scenario.domain_label} participant MoonBooks exchange focused perspectives through \{scenario.building_id} and reduce them into testable research questions."
  let journey_title = "\{scenario.title} round \{round_number}"
  let journey_summary = "The building received \{participants.length()} domain perspectives and reduced them into \{ideas.length()} research programs worth ongoing review."
  [
    "{",
    "  \"book_id\": \{json_string(protocol.book_id)},",
    "  \"title\": \{json_string(scenario.title)},",
    "  \"summary\": \{json_string(summary)},",
    "  \"status_chips\": [",
    "    {\"label\":\"protocol salon\",\"tone\":\"healthy\"},",
    "    {\"label\":\{json_string(scenario.cadence)},\"tone\":\"info\"},",
    "    {\"label\":\"round \{round_number}\",\"tone\":\"info\"},",
    "    {\"label\":\"review gated\",\"tone\":\"review\"}",
    "  ],",
    "  \"metrics\": [",
    "    {\"label\":\"Participant books\",\"value\":\"\{participants.length()}\",\"note\":\"active perspectives\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Idea reductions\",\"value\":\"\{ideas.length()}\",\"note\":\"cross-area questions\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Effectiveness\",\"value\":\"\{metrics.structural_effectiveness_score}/100\",\"note\":\"structural exchange score\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Research questions\",\"value\":\"\{metrics.research_question_count}\",\"note\":\"testable follow-ups\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Home returns\",\"value\":\"\{metrics.idea_return_home_count}\",\"note\":\"idea-book routes\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Review gates\",\"value\":\"1\",\"note\":\{json_string(scenario.review_gate)},\"tone\":\"review\"}",
    "  ],",
    "  \"readiness\": [",
    "    {\"title\":\"Building synthesis\",\"detail\":\{json_string(scenario.synthesis_path)},\"meta\":\"Ready\"},",
    "    {\"title\":\"Question backlog\",\"detail\":\{json_string(scenario.backlog_path)},\"meta\":\"Ready\"},",
    "    {\"title\":\"Effectiveness metrics\",\"detail\":\{json_string(scenario.metrics_path)},\"meta\":\"Ready\"},",
    "    {\"title\":\"Review queue\",\"detail\":\{json_string(scenario.review_path)},\"meta\":\"Pending\"}",
    "  ],",
    "  \"review_queue\": [",
    "    {\"title\":\{json_string(scenario.review_gate)},\"detail\":\{json_string(scenario.review_path)},\"meta\":\"Pending\"}",
    "  ],",
    "  \"page_families\": \{projection_page_families_json(participants, ideas)},",
    "  \"journey\": [",
    "    {\"title\":\{json_string(journey_title)},\"stage\":\"exchange-reduce-distribute\",\"status\":\"review\",\"summary\":\{json_string(journey_summary)},\"highlights\": \{json_string_array(highlights)}}",
    "  ],",
    "  \"links\": [",
    "    {\"label\":\"Question backlog\",\"kind\":\"wiki\",\"url\":\{json_string(scenario.backlog_path)}},",
    "    {\"label\":\"Effectiveness metrics\",\"kind\":\"wiki\",\"url\":\{json_string(scenario.metrics_path)}},",
    "    {\"label\":\"Review queue\",\"kind\":\"wiki\",\"url\":\{json_string(scenario.review_path)}}",
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
      "{\"title\":\{json_string(participant.title)},\"detail\":\{json_string(participant.book_id)},\"meta\":\"Sub-area MoonBook\"}",
    )
  }
  for idea in ideas {
    items.push(
      "{\"title\":\{json_string(idea.title)},\"detail\":\{json_string(idea.id)},\"meta\":\"Idea reduction\"}",
    )
  }
  "[\{items.join(",")}]"
}

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
    "    <p class=\"eyebrow\">\{protocol.title} protocol building</p>",
    "    <h1>\{scenario.title}</h1>",
    "    <p><code>\{round_id}</code> <code>round \{round_number}</code></p>",
    "    <p>\{participants.length()} participant MoonBooks exchange focused views on \{scenario.cadence}, then \{scenario.building_id} reduces the plurality into research questions worth ongoing work.</p>",
    "    <p><code>\{participants.length()} participant books</code> <code>\{ideas.length()} idea reductions</code> <code>review gated</code></p>",
    "    <div class=\"metric\">",
    "      <div class=\"stat\"><b>\{metrics.structural_effectiveness_score}/100</b><span>structural effectiveness</span></div>",
    "      <div class=\"stat\"><b>\{metrics.research_question_count}</b><span>research questions</span></div>",
    "      <div class=\"stat\"><b>\{metrics.idea_return_home_count}</b><span>idea-home returns</span></div>",
    "      <div class=\"stat\"><b>\{metrics.average_books_per_idea}</b><span>books per idea</span></div>",
    "    </div>",
    "  </section>",
    "  <h2>Sub-area MoonBooks</h2>",
    "  <section class=\"grid\">\{civic_salon_participant_cards(participants)}</section>",
    "  <h2>Reduced Research Ideas</h2>",
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

///|
fn civic_salon_participant_table(
  participants : Array[CivicSalonParticipantBook],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("| MoonBook | Focus | Current Question |\n")
  builder.write_string("| --- | --- | --- |\n")
  for participant in participants {
    builder.write_string(
      "|\{participant.book_id}|\{participant.focus_area}|\{participant.current_question}|\n",
    )
  }
  builder.to_string().trim().to_owned()
}

///|
fn civic_salon_idea_sections(ideas : Array[CivicSalonIdea]) -> String {
  let builder = StringBuilder::new()
  for idea in ideas {
    builder.write_string("### ")
    builder.write_string(idea.title)
    builder.write_string("\n\n")
    builder.write_string(idea.summary)
    builder.write_string("\n\n")
    builder.write_string("Participating MoonBooks: `")
    builder.write_string(idea.participating_books.join("`, `"))
    builder.write_string("`.\n\n")
    builder.write_string("Why it matters: ")
    builder.write_string(idea.why_it_matters)
    builder.write_string("\n\n")
    builder.write_string("Research questions:\n")
    for question in idea.research_questions {
      builder.write_string("- ")
      builder.write_string(question)
      builder.write_char('\n')
    }
    builder.write_string("\nNext experiment: ")
    builder.write_string(idea.next_experiment)
    builder.write_string("\n\n")
  }
  builder.to_string().trim().to_owned()
}
