///|
priv struct BuildingProtocolRegistryDocument {
  generated_at : String
  description : String
  protocols : Array[@civic.BuildingProtocolDefinition]
} derive(ToJson)

///|
priv struct EmbodiedRoboticsParticipantBook {
  book_id : String
  title : String
  focus_area : String
  perspective : String
  cadence : String
  current_question : String
  contribution : String
  next_artifact : String
} derive(ToJson)

///|
priv struct EmbodiedRoboticsSalonIdea {
  id : String
  title : String
  summary : String
  participating_books : Array[String]
  research_questions : Array[String]
  why_it_matters : String
  next_experiment : String
} derive(ToJson)

///|
priv struct EmbodiedRoboticsSalonMetric {
  participant_count : Int
  idea_count : Int
  research_question_count : Int
  participant_idea_links : Int
  participating_book_coverage_count : Int
  idea_return_home_count : Int
  average_books_per_idea : String
  structural_effectiveness_score : Int
  summary : String
} derive(ToJson)

///|
priv struct EmbodiedRoboticsIdeaHomeReturn {
  id : String
  building_id : String
  idea_id : String
  target_book_id : String
  target_path : String
  summary : String
  review_status : String
} derive(ToJson)

///|
pub fn default_wenyu_protocol_registry_path() -> String {
  ".moontown/civic/protocols.json"
}

///|
pub fn default_wenyu_protocol_status_path() -> String {
  ".moontown/civic/protocol-status.json"
}

///|
pub async fn bootstrap_wenyu_building_protocols(
  registry_path? : String = default_wenyu_protocol_registry_path(),
  status_path? : String = default_wenyu_protocol_status_path(),
) -> String {
  let protocols = @civic.wenyu_building_protocols()
  let registry_document = BuildingProtocolRegistryDocument::{
    generated_at: "bootstrap",
    description: "Wenyu building protocol registry. Buildings are protocol places for aggregation, exchange, AI-guided reduction, review, and distribution.",
    protocols,
  }
  write_text_file(
    registry_path,
    registry_document.to_json().stringify(indent=2),
  )
  for protocol in protocols {
    write_text_file_if_missing(
      protocol_contract_path(protocol.building_id),
      building_protocol_markdown(protocol),
    )
  }
  match @civic.wenyu_building_protocol_for_building_id("social-square") {
    Some(protocol) => seed_social_square_protocol_slice(protocol)
    None => ()
  }
  ignore(write_wenyu_building_protocol_status(status_path~, registry_path~))
  "Bootstrapped \{protocols.length()} Wenyu building protocol definition(s), including a Social Square inbox/reduction/outbox proof slice."
}

///|
pub async fn bootstrap_embodied_robotics_salon(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  round_id? : String = "embodied-robotics-salon-round-001",
  round_number? : Int = 1,
  workspace_base? : String = "",
) -> String {
  let participants = embodied_robotics_participant_books()
  let ideas = embodied_robotics_salon_ideas()
  let metrics = embodied_robotics_salon_metrics(participants, ideas)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let merged_catalog = merge_embodied_robotics_catalog(
    catalog, participants, workspace_base,
  )
  @moonbook.save_catalog_file(book_catalog_path, merged_catalog)
  for participant in participants {
    write_embodied_robotics_participant_workspace(
      participant,
      ideas,
      round_id,
      round_number,
      embodied_robotics_workspace_root(participant.book_id, workspace_base),
    )
  }
  match @civic.wenyu_building_protocol_for_building_id("social-square") {
    Some(protocol) => {
      seed_embodied_robotics_protocol_slice(
        protocol, participants, ideas, round_id, round_number,
      )
      write_embodied_robotics_building_pages(
        protocol,
        participants,
        ideas,
        metrics,
        round_id,
        round_number,
        embodied_robotics_workspace_root(protocol.book_id, workspace_base),
      )
    }
    None => ()
  }
  ignore(write_wenyu_building_protocol_status())
  ignore(write_wenyu_civic_status())
  "Seeded embodied robotics salon \{round_id}: \{participants.length()} sub-area MoonBook(s), \{ideas.length()} cross-area idea reduction(s), \{metrics.research_question_count} research question(s), and \{metrics.idea_return_home_count} returned idea-home route(s)."
}

///|
pub async fn write_wenyu_building_protocol_status(
  status_path? : String = default_wenyu_protocol_status_path(),
  registry_path? : String = default_wenyu_protocol_registry_path(),
) -> String {
  let portfolio = inspect_wenyu_building_protocols(status_path~, registry_path~)
  write_text_file(status_path, portfolio.to_json().stringify(indent=2))
  write_text_file(
    protocol_status_markdown_path(status_path),
    render_wenyu_building_protocol_portfolio(portfolio),
  )
  "Wrote Wenyu building protocol status for \{portfolio.total} building(s) to \{status_path}."
}

///|
pub async fn render_wenyu_building_protocol_status(
  status_path? : String = default_wenyu_protocol_status_path(),
  registry_path? : String = default_wenyu_protocol_registry_path(),
) -> String {
  render_wenyu_building_protocol_portfolio(
    inspect_wenyu_building_protocols(status_path~, registry_path~),
  )
}

///|
pub async fn inspect_wenyu_building_protocols(
  status_path? : String = default_wenyu_protocol_status_path(),
  registry_path? : String = default_wenyu_protocol_registry_path(),
) -> @civic.BuildingProtocolPortfolio {
  let snapshots : Array[@civic.BuildingProtocolSnapshot] = []
  for protocol in @civic.wenyu_building_protocols() {
    snapshots.push(inspect_wenyu_building_protocol(protocol))
  }
  building_protocol_portfolio(snapshots, status_path, registry_path)
}

///|
async fn inspect_wenyu_building_protocol(
  protocol : @civic.BuildingProtocolDefinition,
) -> @civic.BuildingProtocolSnapshot {
  let inbox_count = count_protocol_jsonl_records(protocol.building_id, "inbox")
  let contribution_count = count_protocol_jsonl_records(
    protocol.building_id,
    "contributions",
  )
  let reduction_count = count_protocol_jsonl_records(
    protocol.building_id,
    "reductions",
  )
  let outbox_count = count_protocol_jsonl_records(
    protocol.building_id,
    "outbox",
  )
  let review_count = count_protocol_jsonl_records(
    protocol.building_id,
    "reviews",
  )
  let latest_reduction = latest_protocol_reduction(protocol.building_id)
  let latest_distribution = latest_protocol_distribution(protocol.building_id)
  let status = protocol_status_label(
    inbox_count~,
    contribution_count~,
    reduction_count~,
    outbox_count~,
    review_count~,
  )
  {
    building_id: protocol.building_id,
    title: protocol.title,
    book_id: protocol.book_id,
    protocol_mode: protocol.protocol_mode,
    social_responsibility: protocol.social_responsibility,
    status,
    ready: status == "reduced" || status == "review",
    inbox_count,
    contribution_count,
    reduction_count,
    outbox_count,
    review_count,
    latest_reduction_summary: match latest_reduction {
      Some(result) => result.summary
      None => ""
    },
    latest_distribution_summary: match latest_distribution {
      Some(record) => record.summary
      None => ""
    },
    skill_packs: protocol.skill_packs,
  }
}

///|
fn building_protocol_portfolio(
  protocols : Array[@civic.BuildingProtocolSnapshot],
  status_path : String,
  registry_path : String,
) -> @civic.BuildingProtocolPortfolio {
  {
    total: protocols.length(),
    ready_count: protocols.filter(fn(item) { item.ready }).length(),
    active_count: protocols
    .filter(fn(item) {
      item.inbox_count > 0 ||
      item.contribution_count > 0 ||
      item.reduction_count > 0 ||
      item.outbox_count > 0
    })
    .length(),
    review_count: protocols.filter(fn(item) { item.review_count > 0 }).length(),
    blocked_count: protocols
    .filter(fn(item) { item.status == "blocked" })
    .length(),
    status_path,
    registry_path,
    protocols,
  }
}

///|
fn protocol_status_label(
  inbox_count~ : Int,
  contribution_count~ : Int,
  reduction_count~ : Int,
  outbox_count~ : Int,
  review_count~ : Int,
) -> String {
  if review_count > 0 {
    "review"
  } else if reduction_count > 0 && outbox_count > 0 {
    "reduced"
  } else if reduction_count > 0 {
    "reducing"
  } else if contribution_count > 0 {
    "aggregating"
  } else if inbox_count > 0 {
    "inbox"
  } else {
    "defined"
  }
}

///|
fn render_wenyu_building_protocol_portfolio(
  portfolio : @civic.BuildingProtocolPortfolio,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Wenyu Building Protocol Status\n\n")
  builder.write_string(
    "Total: \{portfolio.total}; active: \{portfolio.active_count}; ready: \{portfolio.ready_count}; review: \{portfolio.review_count}; blocked: \{portfolio.blocked_count}.\n\n",
  )
  builder.write_string(
    "| Building | Protocol | Status | Inbox | Contributions | Reductions | Outbox | Reviews | Latest reduction |\n",
  )
  builder.write_string("|---|---|---:|---:|---:|---:|---:|---:|---|\n")
  for protocol in portfolio.protocols {
    builder.write_string(
      "|\{protocol.title}|\{protocol.protocol_mode}|\{protocol.status}|\{protocol.inbox_count}|\{protocol.contribution_count}|\{protocol.reduction_count}|\{protocol.outbox_count}|\{protocol.review_count}|\{protocol_one_line(protocol.latest_reduction_summary)}|\n",
    )
  }
  builder.to_string()
}

///|
async fn seed_social_square_protocol_slice(
  protocol : @civic.BuildingProtocolDefinition,
) -> Unit {
  let input = @civic.BuildingInputPacket::{
    id: "pkt-social-square-resident-intro-001",
    building_id: protocol.building_id,
    source_kind: "resident_request",
    source_id: "resident-projection/demo-founder",
    channel: "resident_request",
    privacy_label: "projection-safe",
    summary: "A resident founder asks for a low-risk peer introduction around youth AI education events.",
    payload: "interest=AI education; need=community event partner; consent=not-yet-granted",
    review_status: "draft",
    idempotency_key: "social-square/demo-founder/intro-001",
    related_book_id: protocol.book_id,
    related_task_id: "",
    related_run_id: "",
  }
  let contribution = @civic.BuildingContribution::{
    id: "ctr-social-square-compatible-interest-001",
    building_id: protocol.building_id,
    contribution_kind: "match_hypothesis",
    input_packet_ids: [input.id],
    summary: "Projection-safe interests suggest a possible education-event collaboration, but identity exchange still requires consent.",
    basis: [
      "resident request names AI education as an interest", "request asks for a community event partner",
      "no explicit consent for external introduction is present",
    ],
    confidence: "medium",
    privacy_label: "projection-safe",
    review_status: "draft",
    idempotency_key: "social-square/contribution/compatible-interest-001",
  }
  let reduction = @civic.BuildingReductionResult::{
    id: "red-social-square-consent-gate-001",
    building_id: protocol.building_id,
    reduction_kind: "consent_gated_match_candidate",
    decision: "needs_review",
    summary: "Social Square reduced one resident request into a consent-gated match candidate and review item instead of publishing an introduction.",
    contribution_ids: [contribution.id],
    output_channel: "review_item",
    distribution_targets: [
      "moonbook:wiki/reviews/social-introductions.md", "projection:module/social-square",
    ],
    changed_pages: ["wiki/reviews/social-introductions.md"],
    accepted_records: [
      "match candidate requires consent before identity exchange",
    ],
    review_items: ["external_introduction consent gate pending"],
    review_status: "pending",
    idempotency_key: "social-square/reduction/consent-gate-001",
    related_book_id: protocol.book_id,
  }
  let distribution = @civic.BuildingDistributionRecord::{
    id: "out-social-square-review-001",
    building_id: protocol.building_id,
    target_kind: "moonbook_review_queue",
    target_id: protocol.book_id,
    target_path: "wiki/reviews/social-introductions.md",
    summary: "Queued a consent-gated match candidate for keeper/operator review.",
    review_status: "pending",
    idempotency_key: "social-square/outbox/review-001",
  }
  let review = @civic.BuildingReviewGateRecord::{
    id: "rev-social-square-external-intro-001",
    building_id: protocol.building_id,
    gate: "external_introduction",
    status: "pending",
    reason: "No explicit consent exists for resident-identifying introduction.",
    related_packet_id: input.id,
    related_reduction_id: reduction.id,
    owner: "operator",
  }
  write_protocol_jsonl_record(protocol.building_id, "inbox", input.to_json())
  write_protocol_jsonl_record(
    protocol.building_id,
    "contributions",
    contribution.to_json(),
  )
  write_protocol_jsonl_record(
    protocol.building_id,
    "reductions",
    reduction.to_json(),
  )
  write_protocol_jsonl_record(
    protocol.building_id,
    "outbox",
    distribution.to_json(),
  )
  write_protocol_jsonl_record(protocol.building_id, "reviews", review.to_json())
}

///|
async fn seed_embodied_robotics_protocol_slice(
  protocol : @civic.BuildingProtocolDefinition,
  participants : Array[EmbodiedRoboticsParticipantBook],
  ideas : Array[EmbodiedRoboticsSalonIdea],
  round_id : String,
  round_number : Int,
) -> Unit {
  let inputs : Array[Json] = []
  let contributions : Array[Json] = []
  for participant in participants {
    let input_id = "pkt-robotics-\{round_id}-\{participant.book_id}"
    inputs.push(
      @civic.BuildingInputPacket::{
        id: input_id,
        building_id: protocol.building_id,
        source_kind: "moonbook_subarea",
        source_id: participant.book_id,
        channel: "domain_perspective",
        privacy_label: "book-public",
        summary: "\{participant.title} joins the embodied robotics salon on \{participant.cadence}.",
        payload: "focus=\{participant.focus_area}; question=\{participant.current_question}; contribution=\{participant.contribution}",
        review_status: "accepted",
        idempotency_key: "embodied-robotics/\{participant.book_id}/round-\{round_number}",
        related_book_id: participant.book_id,
        related_task_id: round_id,
        related_run_id: "protocol-seed",
      }.to_json(),
    )
    contributions.push(
      @civic.BuildingContribution::{
        id: "ctr-robotics-\{round_id}-\{participant.book_id}",
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
        idempotency_key: "embodied-robotics/contribution/\{participant.book_id}/round-\{round_number}",
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
        reduction_kind: "cross_area_research_idea",
        decision: "update",
        summary: "\{idea.title}: \{idea.summary}",
        contribution_ids: idea.participating_books.map(fn(book_id) {
          "ctr-robotics-\{round_id}-\{book_id}"
        }),
        output_channel: "research_question_backlog",
        distribution_targets: [
          "moonbook:wenyu-social-square/wiki/queries/embodied-robotics-salon.md",
          "projection:module/social-square",
          ..idea.participating_books.map(fn(book_id) {
            "moonbook:\{book_id}/wiki/queries/open-questions.md"
          }),
        ],
        changed_pages: [
          "wiki/queries/embodied-robotics-salon.md", "wiki/civic/embodied-robotics-salon.md",
        ],
        accepted_records: [
          idea.summary,
          "Next experiment: \{idea.next_experiment}",
        ],
        review_items: [
          "keeper should review feasibility, source gaps, and experiment safety before promotion",
        ],
        review_status: "pending",
        idempotency_key: "embodied-robotics/reduction/\{idea.id}/round-\{round_number}",
        related_book_id: protocol.book_id,
      }.to_json(),
    )
    outbox.push(
      @civic.BuildingDistributionRecord::{
        id: "out-\{round_id}-\{idea.id}",
        building_id: protocol.building_id,
        target_kind: "moonbook_question_backlog",
        target_id: protocol.book_id,
        target_path: "wiki/queries/embodied-robotics-salon.md",
        summary: "Distributed cross-area question set for `\{idea.title}` to \{idea.participating_books.length()} sub-area MoonBook(s).",
        review_status: "pending",
        idempotency_key: "embodied-robotics/outbox/\{idea.id}/round-\{round_number}",
      }.to_json(),
    )
  }
  let review = @civic.BuildingReviewGateRecord::{
    id: "rev-\{round_id}",
    building_id: protocol.building_id,
    gate: "research_program_quality",
    status: "pending",
    reason: "The salon generated cross-area research questions that need keeper review before becoming long-horizon research programs.",
    related_packet_id: "pkt-robotics-\{round_id}-\{participants.get(0).unwrap().book_id}",
    related_reduction_id: "red-\{round_id}-\{ideas.get(0).unwrap().id}",
    owner: "keeper",
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
    embodied_robotics_home_return_records(
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
async fn write_protocol_jsonl_record(
  building_id : String,
  ledger : String,
  value : Json,
) -> Unit {
  write_text_file(
    protocol_ledger_path(building_id, ledger),
    value.stringify() + "\n",
  )
}

///|
async fn write_protocol_jsonl_records(
  building_id : String,
  ledger : String,
  values : Array[Json],
) -> Unit {
  let builder = StringBuilder::new()
  for value in values {
    builder.write_string(value.stringify())
    builder.write_char('\n')
  }
  write_text_file(
    protocol_ledger_path(building_id, ledger),
    builder.to_string(),
  )
}

///|
async fn count_protocol_jsonl_records(
  building_id : String,
  ledger : String,
) -> Int {
  let text = read_text_or_empty(protocol_ledger_path(building_id, ledger))
  let mut count = 0
  for raw in text.split("\n") {
    if !raw.trim().is_empty() {
      count += 1
    }
  }
  count
}

///|
async fn latest_protocol_reduction(
  building_id : String,
) -> @civic.BuildingReductionResult? {
  match latest_protocol_json_line(building_id, "reductions") {
    Some(line) =>
      Some(@json.from_json(@json.parse(line)) catch { _ => return None })
    None => None
  }
}

///|
async fn latest_protocol_distribution(
  building_id : String,
) -> @civic.BuildingDistributionRecord? {
  match latest_protocol_json_line(building_id, "outbox") {
    Some(line) =>
      Some(@json.from_json(@json.parse(line)) catch { _ => return None })
    None => None
  }
}

///|
async fn latest_protocol_json_line(
  building_id : String,
  ledger : String,
) -> String? {
  let text = read_text_or_empty(protocol_ledger_path(building_id, ledger))
  let mut latest = ""
  for raw in text.split("\n") {
    let line = raw.trim().to_string()
    if !line.is_empty() {
      latest = line
    }
  }
  if latest.is_empty() {
    None
  } else {
    Some(latest)
  }
}

///|
fn protocol_contract_path(building_id : String) -> String {
  "\{protocol_ledger_dir(building_id)}/PROTOCOL.md"
}

///|
fn protocol_ledger_path(building_id : String, ledger : String) -> String {
  "\{protocol_ledger_dir(building_id)}/\{ledger}.jsonl"
}

///|
fn protocol_ledger_dir(building_id : String) -> String {
  ".moontown/civic/protocols/\{building_id}"
}

///|
fn protocol_status_markdown_path(status_path : String) -> String {
  if status_path.has_suffix(".json") {
    status_path[:status_path.length() - 5].to_string() + ".md"
  } else {
    status_path + ".md"
  }
}

///|
fn building_protocol_markdown(
  protocol : @civic.BuildingProtocolDefinition,
) -> String {
  [
    "# \{protocol.title} Building Protocol",
    "",
    protocol.social_responsibility,
    "",
    "## Protocol",
    "",
    "- Building: `\{protocol.building_id}`",
    "- Mode: `\{protocol.protocol_mode}`",
    "- Book: `\{protocol.book_id}`",
    "- MoonBook role: `\{protocol.moonbook_role}`",
    "- Projection contract: `\{protocol.projection_contract}`",
    "",
    "## Input Channels",
    "",
    protocol_markdown_bullets(protocol.input_channels),
    "",
    "## Output Channels",
    "",
    protocol_markdown_bullets(protocol.output_channels),
    "",
    "## Review Gates",
    "",
    protocol_markdown_bullets(protocol.review_gates),
    "",
    "## AI Reducer Boundary",
    "",
    "- Moontown owns the envelope, channels, ledgers, idempotency, and review gates.",
    "- MoonClaw chooses the building-native reduction strategy through the skill packs.",
    "- MoonBook persists accepted civic records and review queues.",
  ].join("\n")
}

///|
fn protocol_markdown_bullets(items : Array[String]) -> String {
  let builder = StringBuilder::new()
  for item in items {
    builder.write_string("- \{item}\n")
  }
  builder.to_string().trim().to_string()
}

///|
fn protocol_one_line(text : String) -> String {
  text.replace(old="\n", new=" ").trim().to_string()
}

///|
fn embodied_robotics_participant_books() -> Array[
  EmbodiedRoboticsParticipantBook,
] {
  [
    embodied_robotics_participant(
      book_id="embodied-robotics-large-models",
      title="Large Model Lab",
      focus_area="robot foundation models and multimodal pretraining",
      perspective="Models should become reusable priors for perception, planning, and action, but only if their embodiment assumptions are explicit.",
      current_question="Which parts of robotic intelligence should be learned as general priors, and which must remain robot-specific?",
      contribution="Large-model agents can provide semantic priors, task decomposition, and failure explanation, but need grounding tests that expose hallucinated affordances.",
      next_artifact="wiki/queries/foundation-model-grounding.md",
    ),
    embodied_robotics_participant(
      book_id="embodied-robotics-agent-systems",
      title="Agent Systems Lab",
      focus_area="planner-agent loops, tool use, memory, and self-correction",
      perspective="Robots need agents that can ask for help, recover from failure, and decide when not to act.",
      current_question="What memory and review loop lets a robot agent improve without quietly accumulating unsafe habits?",
      contribution="Agent loops should treat failed attempts as first-class memory and route uncertain physical actions through review gates.",
      next_artifact="wiki/queries/robot-agent-memory.md",
    ),
    embodied_robotics_participant(
      book_id="embodied-robotics-vla",
      title="VLA Lab",
      focus_area="vision-language-action policies and instruction following",
      perspective="VLA is the bridge from language goals to continuous action, but evaluation must move beyond short demos.",
      current_question="How can VLA policies be tested for long-horizon recovery under changed layouts, tools, and lighting?",
      contribution="VLA work contributes policy grounding, instruction following, and evaluation pressure around generalization and recovery.",
      next_artifact="wiki/queries/vla-long-horizon-eval.md",
    ),
    embodied_robotics_participant(
      book_id="embodied-robotics-world-models",
      title="World Model Lab",
      focus_area="predictive dynamics, spatial memory, and counterfactual simulation",
      perspective="World models should be judged by whether they make robot plans falsifiable before execution.",
      current_question="Can a robot reject an action plan because its world model predicts contact, occlusion, or tool failure?",
      contribution="World-model work contributes predictive state, counterfactual planning, and a way to score whether a plan deserves physical execution.",
      next_artifact="wiki/queries/world-model-falsification.md",
    ),
    embodied_robotics_participant(
      book_id="embodied-robotics-locomotion",
      title="Locomotion Lab",
      focus_area="mobility, balance, terrain adaptation, and whole-body control",
      perspective="Locomotion is not a separate low-level module when robots must move, perceive, and manipulate in the same plan.",
      current_question="What interface lets high-level agents request movement without breaking balance, energy, or safety constraints?",
      contribution="Locomotion contributes contact-rich constraints, terrain awareness, and embodiment limits that other subfields must respect.",
      next_artifact="wiki/queries/whole-body-agent-interface.md",
    ),
    embodied_robotics_participant(
      book_id="embodied-robotics-manipulation",
      title="Manipulation Lab",
      focus_area="grasping, dexterity, tool use, contact, and tactile feedback",
      perspective="Manipulation exposes the gap between symbolic task plans and the physics of contact.",
      current_question="Which tactile and force signals should be promoted into language-visible robot memory?",
      contribution="Manipulation contributes contact-state abstractions, tool-affordance failures, and practical tests for embodied reasoning.",
      next_artifact="wiki/queries/contact-state-language.md",
    ),
    embodied_robotics_participant(
      book_id="embodied-robotics-brain",
      title="Robot Brain Lab",
      focus_area="runtime architecture, arbitration, memory, policy routing, and safety envelope",
      perspective="A robot brain is a governance system over models, skills, sensors, memory, and actuation.",
      current_question="How should the robot brain arbitrate between VLA policy, world model warning, and safety gate?",
      contribution="Robot-brain work contributes architectural boundaries, arbitration contracts, and review policies for physical action.",
      next_artifact="wiki/queries/robot-brain-arbitration.md",
    ),
    embodied_robotics_participant(
      book_id="embodied-robotics-data-engine",
      title="Data Engine Lab",
      focus_area="robot data flywheels, simulation, teleoperation, video, and failure mining",
      perspective="The field needs provenance-aware data loops, not just more videos or more teleoperation traces.",
      current_question="Which data should enter the robot learning loop after a failure, and how should provenance be tracked?",
      contribution="Data-engine work contributes source labels, collection strategy, failure mining, and dataset quality gates.",
      next_artifact="wiki/queries/robot-data-flywheel.md",
    ),
    embodied_robotics_participant(
      book_id="embodied-robotics-sim2real",
      title="Sim2Real Lab",
      focus_area="simulation transfer, domain randomization, digital twins, and real-world validation",
      perspective="Simulation is useful when it is designed around what must be invalidated on real robots.",
      current_question="What simulation signals predict whether a policy will fail safely or dangerously in the real world?",
      contribution="Sim2Real contributes cheap variation, stress tests, and transfer-risk estimates for the shared research program.",
      next_artifact="wiki/queries/sim2real-risk.md",
    ),
    embodied_robotics_participant(
      book_id="embodied-robotics-evaluation-safety",
      title="Evaluation and Safety Lab",
      focus_area="benchmarks, red-team tests, physical safety, interpretability, and operator review",
      perspective="Embodied AI progress is not real until it survives adversarial, long-horizon, and safety-critical evaluation.",
      current_question="What benchmark reveals whether a robot knows when to stop, ask, recover, or refuse?",
      contribution="Evaluation and safety work contributes test design, risk taxonomy, refusal criteria, and promotion gates.",
      next_artifact="wiki/queries/embodied-ai-safety-benchmarks.md",
    ),
  ]
}

///|
fn embodied_robotics_participant(
  book_id~ : String,
  title~ : String,
  focus_area~ : String,
  perspective~ : String,
  current_question~ : String,
  contribution~ : String,
  next_artifact~ : String,
) -> EmbodiedRoboticsParticipantBook {
  {
    book_id,
    title,
    focus_area,
    perspective,
    cadence: "30m salon exchange",
    current_question,
    contribution,
    next_artifact,
  }
}

///|
fn embodied_robotics_salon_ideas() -> Array[EmbodiedRoboticsSalonIdea] {
  [
    {
      id: "robot-grounding-falsification",
      title: "Grounding as falsification, not confidence",
      summary: "Connect large models, VLA, and world models so robot plans must predict their own failure modes before acting.",
      participating_books: [
        "embodied-robotics-large-models", "embodied-robotics-vla", "embodied-robotics-world-models",
        "embodied-robotics-evaluation-safety",
      ],
      research_questions: [
        "What concrete pre-action predictions should a robot make before executing a language command?",
        "Can a world model invalidate a VLA action before contact happens?", "How should evaluation score correct refusal versus successful completion?",
      ],
      why_it_matters: "This reframes embodied intelligence around accountable physical prediction instead of impressive but brittle demos.",
      next_experiment: "Build a small benchmark where a robot must explain predicted failure for changed tools, blocked paths, and hidden objects before acting.",
    },
    {
      id: "contact-language-memory",
      title: "Contact-rich memory for robot agents",
      summary: "Promote tactile, force, balance, and manipulation failures into agent-visible memory so future plans can avoid repeated physical mistakes.",
      participating_books: [
        "embodied-robotics-agent-systems", "embodied-robotics-locomotion", "embodied-robotics-manipulation",
        "embodied-robotics-brain",
      ],
      research_questions: [
        "Which contact events deserve durable memory rather than temporary controller state?",
        "How should a language agent refer to balance, slip, force, and grasp uncertainty without losing precision?",
        "Can failed contact histories improve planning without overfitting to one robot body?",
      ],
      why_it_matters: "Robots repeatedly fail where language plans meet physics; preserving contact knowledge may be a practical bridge.",
      next_experiment: "Create a contact-event schema and test whether it improves retry plans in grasping and uneven-terrain tasks.",
    },
    {
      id: "provenance-aware-data-flywheel",
      title: "Provenance-aware robot data flywheel",
      summary: "Combine simulation, teleoperation, web video, and on-robot failure traces with source labels and promotion gates.",
      participating_books: [
        "embodied-robotics-data-engine", "embodied-robotics-sim2real", "embodied-robotics-vla",
        "embodied-robotics-evaluation-safety",
      ],
      research_questions: [
        "Which data sources improve real-world transfer and which only inflate benchmark scores?",
        "How should failed on-robot attempts be labeled for retraining versus review?",
        "What provenance labels should follow a sample from collection to policy update?",
      ],
      why_it_matters: "The next bottleneck may be data accounting quality, not model size.",
      next_experiment: "Define a source-provenance matrix and run one policy update that separates simulated success, teleop success, and real failure traces.",
    },
    {
      id: "robot-brain-arbitration",
      title: "Robot brain arbitration contract",
      summary: "Define how the robot brain chooses between VLA policy, world-model warning, locomotion constraints, manipulation signals, and safety review.",
      participating_books: [
        "embodied-robotics-brain", "embodied-robotics-world-models", "embodied-robotics-locomotion",
        "embodied-robotics-manipulation", "embodied-robotics-evaluation-safety",
      ],
      research_questions: [
        "When should a safety gate override a high-confidence action policy?", "How should a robot explain arbitration decisions to an operator?",
        "Which arbitration records should become MoonBook memory for future runs?",
      ],
      why_it_matters: "Without an arbitration contract, embodied AI systems become a pile of strong models with weak governance.",
      next_experiment: "Prototype an arbitration log for one task where world-model risk, motion feasibility, and manipulation uncertainty disagree.",
    },
    {
      id: "long-horizon-recovery-benchmark",
      title: "Long-horizon recovery benchmark",
      summary: "Evaluate whether robots can continue useful work after changed layouts, substituted tools, partial failures, and uncertainty.",
      participating_books: [
        "embodied-robotics-vla", "embodied-robotics-agent-systems", "embodied-robotics-world-models",
        "embodied-robotics-evaluation-safety",
      ],
      research_questions: [
        "Can a robot update its plan after discovering that the expected tool is missing?",
        "What is the difference between graceful degradation and unsafe persistence?",
        "How many recovery steps should be required before an agent asks for human help?",
      ],
      why_it_matters: "Real users care less about one perfect demo and more about recovery when reality changes.",
      next_experiment: "Design five household or lab tasks with planned disruptions and score completion, refusal, help-seeking, and memory updates.",
    },
  ]
}

///|
fn embodied_robotics_salon_metrics(
  participants : Array[EmbodiedRoboticsParticipantBook],
  ideas : Array[EmbodiedRoboticsSalonIdea],
) -> EmbodiedRoboticsSalonMetric {
  let research_question_count = embodied_robotics_research_question_count(ideas)
  let participant_idea_links = embodied_robotics_participant_idea_link_count(
    ideas,
  )
  let participating_book_coverage_count = embodied_robotics_covered_book_count(
    ideas,
  )
  let idea_return_home_count = participant_idea_links
  let average_books_per_idea = embodied_robotics_average_books_per_idea_label(
    ideas,
  )
  let structural_effectiveness_score = embodied_robotics_structural_score(
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
    summary: "The salon converted \{participants.length()} embodied-robotics sub-area perspectives into \{ideas.length()} cross-area ideas, \{research_question_count} testable questions, and \{idea_return_home_count} returned idea-home records.",
  }
}

///|
fn embodied_robotics_research_question_count(
  ideas : Array[EmbodiedRoboticsSalonIdea],
) -> Int {
  let mut count = 0
  for idea in ideas {
    count += idea.research_questions.length()
  }
  count
}

///|
fn embodied_robotics_participant_idea_link_count(
  ideas : Array[EmbodiedRoboticsSalonIdea],
) -> Int {
  let mut count = 0
  for idea in ideas {
    count += idea.participating_books.length()
  }
  count
}

///|
fn embodied_robotics_covered_book_count(
  ideas : Array[EmbodiedRoboticsSalonIdea],
) -> Int {
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
fn embodied_robotics_average_books_per_idea_label(
  ideas : Array[EmbodiedRoboticsSalonIdea],
) -> String {
  if ideas.length() == 0 {
    "0"
  } else {
    let links = embodied_robotics_participant_idea_link_count(ideas)
    let scaled = links * 10 / ideas.length()
    "\{links}/\{ideas.length()} = \{scaled / 10}.\{scaled % 10}"
  }
}

///|
fn embodied_robotics_score_component(
  value : Int,
  target : Int,
  max : Int,
) -> Int {
  if target <= 0 {
    0
  } else if value >= target {
    max
  } else {
    value * max / target
  }
}

///|
fn embodied_robotics_structural_score(
  participant_count~ : Int,
  idea_count~ : Int,
  research_question_count~ : Int,
  participating_book_coverage_count~ : Int,
  idea_return_home_count~ : Int,
  participant_idea_links~ : Int,
) -> Int {
  embodied_robotics_score_component(participant_count, 10, 20) +
  embodied_robotics_score_component(idea_count, 5, 20) +
  embodied_robotics_score_component(research_question_count, 15, 20) +
  embodied_robotics_score_component(
    participating_book_coverage_count, participant_count, 20,
  ) +
  embodied_robotics_score_component(
    idea_return_home_count, participant_idea_links, 20,
  )
}

///|
fn embodied_robotics_returned_ideas_for_book(
  book_id : String,
  ideas : Array[EmbodiedRoboticsSalonIdea],
) -> Array[EmbodiedRoboticsSalonIdea] {
  ideas.filter(fn(idea) { idea.participating_books.contains(book_id) })
}

///|
fn embodied_robotics_home_return_records(
  building_id : String,
  ideas : Array[EmbodiedRoboticsSalonIdea],
  round_id? : String = "embodied-robotics-salon-round-001",
) -> Array[EmbodiedRoboticsIdeaHomeReturn] {
  let records : Array[EmbodiedRoboticsIdeaHomeReturn] = []
  for idea in ideas {
    for book_id in idea.participating_books {
      records.push({
        id: "home-\{round_id}-\{idea.id}-\{book_id}",
        building_id,
        idea_id: idea.id,
        target_book_id: book_id,
        target_path: "wiki/queries/salon-returned-ideas.md",
        summary: "Returned `\{idea.title}` to \{book_id} for review and follow-up research shaping.",
        review_status: "pending",
      })
    }
  }
  records
}

///|
fn merge_embodied_robotics_catalog(
  catalog : Array[@moonbook.BookCatalogEntry],
  participants : Array[EmbodiedRoboticsParticipantBook],
  workspace_base : String,
) -> Array[@moonbook.BookCatalogEntry] {
  let merged : Array[@moonbook.BookCatalogEntry] = []
  for entry in catalog {
    if !embodied_robotics_participant_book_ids(participants).contains(entry.id) {
      merged.push(entry)
    }
  }
  for participant in participants {
    merged.push(embodied_robotics_catalog_entry(participant, workspace_base))
  }
  merged
}

///|
fn embodied_robotics_participant_book_ids(
  participants : Array[EmbodiedRoboticsParticipantBook],
) -> Array[String] {
  participants.map(fn(item) { item.book_id })
}

///|
fn embodied_robotics_catalog_entry(
  participant : EmbodiedRoboticsParticipantBook,
  workspace_base : String,
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id=participant.book_id,
    name="Embodied Robotics / \{participant.title}",
    purpose="Sub-area MoonBook for \{participant.focus_area}; participates in the Social Square embodied robotics salon and maintains durable questions, evidence, and research memory.",
    workspace_root=embodied_robotics_workspace_root(
      participant.book_id,
      workspace_base,
    ),
    memory_scope=@core.MemoryScope::BookPrivate,
    tags=[
      "embodied-robotics",
      "protocol-salon",
      "social-square",
      "subarea",
      participant.book_id,
    ],
    skills=[
      "embodied-robotics-salon", "research-question-generation", "cross-area-synthesis",
      "review",
    ],
  )
}

///|
fn embodied_robotics_workspace_root(
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
async fn write_embodied_robotics_participant_workspace(
  participant : EmbodiedRoboticsParticipantBook,
  ideas : Array[EmbodiedRoboticsSalonIdea],
  round_id : String,
  round_number : Int,
  root : String,
) -> Unit {
  let returned_ideas = embodied_robotics_returned_ideas_for_book(
    participant.book_id,
    ideas,
  )
  write_text_file(
    "\{root}/wiki/index.md",
    embodied_robotics_participant_index(participant, returned_ideas),
  )
  write_text_file(
    "\{root}/raw/bootstrap/EMBODIED_ROBOTICS_SUBAREA_CONTRACT.md",
    embodied_robotics_participant_contract(participant),
  )
  write_text_file(
    "\{root}/skills/embodied-robotics-salon/SKILL.md",
    embodied_robotics_salon_skill_text(),
  )
  write_text_file(
    "\{root}/wiki/contributions/current-perspective.md",
    embodied_robotics_participant_perspective(participant),
  )
  write_text_file(
    "\{root}/\{participant.next_artifact}",
    embodied_robotics_participant_question_page(participant),
  )
  write_text_file(
    "\{root}/wiki/queries/salon-returned-ideas.md",
    embodied_robotics_returned_ideas_page(
      participant, returned_ideas, round_id, round_number,
    ),
  )
  write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    embodied_robotics_participant_projection(
      participant, returned_ideas, round_id, round_number,
    ).stringify(indent=2),
  )
  write_text_file(
    "\{root}/book/site/generated/index.html",
    embodied_robotics_participant_html(
      participant, returned_ideas, round_id, round_number,
    ),
  )
}

///|
async fn write_embodied_robotics_building_pages(
  protocol : @civic.BuildingProtocolDefinition,
  participants : Array[EmbodiedRoboticsParticipantBook],
  ideas : Array[EmbodiedRoboticsSalonIdea],
  metrics : EmbodiedRoboticsSalonMetric,
  round_id : String,
  round_number : Int,
  root : String,
) -> Unit {
  write_text_file(
    "\{root}/wiki/civic/embodied-robotics-salon.md",
    embodied_robotics_building_synthesis(
      protocol, participants, ideas, metrics, round_id, round_number,
    ),
  )
  write_text_file(
    "\{root}/wiki/queries/embodied-robotics-salon.md",
    embodied_robotics_idea_backlog(ideas),
  )
  write_text_file(
    "\{root}/wiki/reviews/embodied-robotics-salon.md",
    embodied_robotics_review_queue(ideas),
  )
  write_text_file(
    "\{root}/wiki/metrics/embodied-robotics-salon.md",
    embodied_robotics_metrics_markdown(
      metrics, participants, ideas, round_id, round_number,
    ),
  )
  write_text_file(
    "\{root}/raw/bootstrap/embodied-robotics-salon-metrics.json",
    metrics.to_json().stringify(indent=2),
  )
  write_text_file(
    "\{protocol_ledger_dir(protocol.building_id)}/metrics.json",
    metrics.to_json().stringify(indent=2),
  )
  let html = embodied_robotics_building_html(
    protocol, participants, ideas, metrics, round_id, round_number,
  )
  write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    embodied_robotics_building_projection_json(
      protocol, participants, ideas, metrics, round_id, round_number,
    ),
  )
  write_text_file("\{root}/book/Home.html", html)
  write_text_file("\{root}/book/site/generated/index.html", html)
}

///|
fn embodied_robotics_participant_index(
  participant : EmbodiedRoboticsParticipantBook,
  returned_ideas : Array[EmbodiedRoboticsSalonIdea],
) -> String {
  [
    "# \{participant.title}",
    "",
    "Sub-area MoonBook for the embodied robotics salon.",
    "",
    "- Focus: \{participant.focus_area}",
    "- Cadence: \{participant.cadence}",
    "- Shared building: `social-square`",
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
    "## Returned Ideas From Social Square",
    "",
    if returned_ideas.length() == 0 {
      "No returned salon ideas yet."
    } else {
      "This book received \{returned_ideas.length()} reduced idea(s) back from the Social Square salon. See `wiki/queries/salon-returned-ideas.md`."
    },
  ].join("\n")
}

///|
fn embodied_robotics_participant_contract(
  participant : EmbodiedRoboticsParticipantBook,
) -> String {
  [
    "# Embodied Robotics Sub-area Contract",
    "",
    "- Book id: `\{participant.book_id}`",
    "- Focus area: \{participant.focus_area}",
    "- Salon cadence: \{participant.cadence}",
    "- Building channel: `domain_perspective`",
    "- Expected output: short perspective packet, open question, evidence gap, and useful cross-area dependency.",
    "",
    "## Rules",
    "",
    "- Do not produce a generic literature report for every round.",
    "- Bring one strong view, one uncertainty, and one concrete research question.",
    "- Treat other sub-area books as peers, not subordinates.",
    "- Promote questions only when they connect at least two sub-areas or reveal a bottleneck.",
  ].join("\n")
}

///|
fn embodied_robotics_salon_skill_text() -> String {
  [
    "---", "name: embodied-robotics-salon", "description: Participate in an embodied robotics multi-book exchange and produce cross-area questions worth ongoing research.",
    "---", "", "# Embodied Robotics Salon Skill", "", "This skill is for a sub-area MoonBook participating in a shared building protocol.",
    "", "## Behavior", "", "- Contribute one focused perspective from the sub-area, not a full report.",
    "- Name one current bottleneck, one disagreement with another sub-area, and one research question.",
    "- Prefer questions that can become experiments, benchmark designs, data schemas, or architecture contracts.",
    "- Separate domain insight from operational chatter.", "- Avoid vague questions like \"how can robots improve\". Make questions testable.",
    "", "## Output Example", "", "```md", "salon_decision: update", "subarea: VLA",
    "bottleneck: short-horizon demos hide recovery failures", "cross_area_dependency: world models and safety evaluation",
    "research_question: How should a VLA policy revise its plan when the expected tool is missing?",
    "next_artifact: wiki/queries/vla-long-horizon-eval.md", "```",
  ].join("\n")
}

///|
fn embodied_robotics_participant_perspective(
  participant : EmbodiedRoboticsParticipantBook,
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
fn embodied_robotics_participant_question_page(
  participant : EmbodiedRoboticsParticipantBook,
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
    "- It connects this sub-area to another embodied robotics bottleneck.",
    "- It can become a benchmark, experiment, architecture contract, or data schema.",
    "- It changes what the shared building should ask next.",
  ].join("\n")
}

///|
fn embodied_robotics_returned_ideas_page(
  participant : EmbodiedRoboticsParticipantBook,
  returned_ideas : Array[EmbodiedRoboticsSalonIdea],
  round_id : String,
  round_number : Int,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Returned Ideas From Embodied Robotics Salon\n\n")
  builder.write_string(
    "This page records which Social Square salon reductions came back home to `\{participant.book_id}` in round `\{round_id}` (#\{round_number}).\n\n",
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
fn embodied_robotics_participant_projection(
  participant : EmbodiedRoboticsParticipantBook,
  returned_ideas : Array[EmbodiedRoboticsSalonIdea],
  round_id : String,
  round_number : Int,
) -> Json {
  @json.parse(
    "{ \"title\": \"Embodied Robotics / \{json_escape(participant.title)}\", \"summary\": \"\{json_escape(participant.contribution)}\", \"status_chips\": [{\"label\":\"protocol salon\",\"tone\":\"info\"},{\"label\":\"30m exchange\",\"tone\":\"healthy\"},{\"label\":\"round \{round_number}\",\"tone\":\"info\"},{\"label\":\"returned ideas \{returned_ideas.length()}\",\"tone\":\"review\"}], \"metrics\": [{\"label\":\"Focus\",\"value\":\"\{json_escape(participant.focus_area)}\",\"note\":\"sub-area\",\"tone\":\"info\"},{\"label\":\"Returned ideas\",\"value\":\"\{returned_ideas.length()}\",\"note\":\"from Social Square\",\"tone\":\"healthy\"}], \"readiness\": [{\"title\":\"Returned salon ideas\",\"detail\":\"wiki/queries/salon-returned-ideas.md\",\"meta\":\"Reviewable\"}], \"review_queue\": [{\"title\":\"Review returned ideas\",\"detail\":\"wiki/queries/salon-returned-ideas.md\",\"meta\":\"Pending\"}], \"page_families\": \{participant_returned_idea_page_families_json(returned_ideas)}, \"journey\": [{\"title\":\"Salon return-home \{json_escape(round_id)}\",\"stage\":\"distribute\",\"status\":\"review\",\"summary\":\"Social Square returned \{returned_ideas.length()} relevant cross-area idea(s) to this sub-area book in round \{round_number}.\",\"highlights\": []}] }",
  ) catch {
    _ => Json::object({})
  }
}

///|
fn participant_returned_idea_page_families_json(
  returned_ideas : Array[EmbodiedRoboticsSalonIdea],
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
fn embodied_robotics_participant_html(
  participant : EmbodiedRoboticsParticipantBook,
  returned_ideas : Array[EmbodiedRoboticsSalonIdea],
  round_id : String,
  round_number : Int,
) -> String {
  [
    "<!doctype html>",
    "<html><head><meta charset=\"utf-8\"><title>\{participant.title}</title>",
    "<style>body{font-family:Georgia,serif;background:#f4f0df;color:#1f2d22;margin:0}main{max-width:920px;margin:auto;padding:48px 24px}.card{background:#fff;border:1px solid #d9d0ad;border-radius:22px;padding:28px;box-shadow:0 18px 50px rgba(58,73,44,.12)}code{background:#ecf0d5;padding:2px 6px;border-radius:6px}</style>",
    "</head><body><main><section class=\"card\">",
    "<p><code>Embodied Robotics Salon</code> <code>\{participant.cadence}</code> <code>round \{round_number}</code></p>",
    "<h1>\{participant.title}</h1>",
    "<p><code>\{round_id}</code></p>",
    "<p>\{participant.perspective}</p>",
    "<h2>Contribution</h2><p>\{participant.contribution}</p>",
    "<h2>Question</h2><p>\{participant.current_question}</p>",
    "<h2>Returned Ideas</h2>",
    embodied_robotics_returned_idea_cards(returned_ideas),
    "</section></main></body></html>",
  ].join("\n")
}

///|
fn embodied_robotics_returned_idea_cards(
  returned_ideas : Array[EmbodiedRoboticsSalonIdea],
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
fn embodied_robotics_building_synthesis(
  protocol : @civic.BuildingProtocolDefinition,
  participants : Array[EmbodiedRoboticsParticipantBook],
  ideas : Array[EmbodiedRoboticsSalonIdea],
  metrics : EmbodiedRoboticsSalonMetric,
  round_id : String,
  round_number : Int,
) -> String {
  [
    "# Embodied Robotics Salon",
    "",
    "- Round: `\{round_id}`",
    "- Round number: `\{round_number}`",
    "",
    "This is a live protocol test for `\{protocol.title}` as a domain exchange building. Ten sub-area MoonBooks contribute focused perspectives, and the building reduces them into research ideas and questions worth ongoing work.",
    "",
    "## Participants",
    "",
    embodied_robotics_participant_table(participants),
    "",
    "## Cross-area Ideas",
    "",
    embodied_robotics_idea_sections(ideas),
    "",
    "## Effectiveness Metrics",
    "",
    embodied_robotics_metrics_table(metrics),
    "",
    "This metric is structural: it proves the building moved from exchange to reduction to distribution. It does not claim the ideas are correct; the review queue still decides which become accepted research programs.",
    "",
    "## Quality Standard",
    "",
    "- A good salon output is not a generic research report.",
    "- It should expose tensions between subfields, convert them into testable questions, and route follow-up work back to the right MoonBooks.",
    "- The building should preserve plurality: different expert books disagree productively before reduction.",
  ].join("\n")
}

///|
fn embodied_robotics_idea_backlog(
  ideas : Array[EmbodiedRoboticsSalonIdea],
) -> String {
  [
    "# Embodied Robotics Open Question Backlog",
    "",
    "Questions generated by the Social Square embodied robotics salon.",
    "",
    embodied_robotics_idea_sections(ideas),
  ].join("\n")
}

///|
fn embodied_robotics_review_queue(
  ideas : Array[EmbodiedRoboticsSalonIdea],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Embodied Robotics Salon Review\n\n")
  builder.write_string("| ID | Idea | Review Need | Status |\n")
  builder.write_string("| --- | --- | --- | --- |\n")
  for idea in ideas {
    builder.write_string(
      "|\{idea.id}|\{idea.title}|check feasibility, evidence gaps, safety boundary, and best owner MoonBooks|pending|\n",
    )
  }
  builder.to_string()
}

///|
fn embodied_robotics_metrics_markdown(
  metrics : EmbodiedRoboticsSalonMetric,
  participants : Array[EmbodiedRoboticsParticipantBook],
  ideas : Array[EmbodiedRoboticsSalonIdea],
  round_id : String,
  round_number : Int,
) -> String {
  [
    "# Embodied Robotics Salon Effectiveness Metrics",
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
    embodied_robotics_idea_metric_table(ideas),
    "",
    "## Return Home Contract",
    "",
    "Each participating book receives `wiki/queries/salon-returned-ideas.md` with the reduced ideas relevant to its sub-area. That page is the next place for each home book to review, accept, refine, or reject the salon output.",
  ].join("\n")
}

///|
fn embodied_robotics_metrics_table(
  metrics : EmbodiedRoboticsSalonMetric,
) -> String {
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
fn embodied_robotics_idea_metric_table(
  ideas : Array[EmbodiedRoboticsSalonIdea],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("| Idea | Books | Questions | Home books |\n")
  builder.write_string("| --- | ---:| ---:| --- |\n")
  for idea in ideas {
    builder.write_string(
      "|\{idea.title}|\{idea.participating_books.length()}|\{idea.research_questions.length()}|`\{idea.participating_books.join("`, `")}`|\n",
    )
  }
  builder.to_string().trim().to_string()
}

///|
fn embodied_robotics_building_projection_json(
  protocol : @civic.BuildingProtocolDefinition,
  participants : Array[EmbodiedRoboticsParticipantBook],
  ideas : Array[EmbodiedRoboticsSalonIdea],
  metrics : EmbodiedRoboticsSalonMetric,
  round_id : String,
  round_number : Int,
) -> String {
  let highlights : Array[String] = [
    "Round \{round_number}: \{round_id}",
    "\{participants.length()} sub-area MoonBooks joined the round",
    "\{ideas.length()} cross-area idea reductions were produced",
    "\{metrics.research_question_count} testable research questions were generated",
    "\{metrics.idea_return_home_count} idea-home records were distributed back to participant books",
    "Outputs are review-gated before becoming long-horizon research programs",
    "Cadence: 30m salon exchange",
  ]
  [
    "{",
    "  \"book_id\": \{json_string(protocol.book_id)},",
    "  \"title\": \"Embodied Robotics Salon / Social Square\",",
    "  \"summary\": \"Ten embodied-robotics sub-area MoonBooks exchange focused perspectives through Social Square and reduce them into testable research questions.\",",
    "  \"status_chips\": [",
    "    {\"label\":\"protocol salon\",\"tone\":\"healthy\"},",
    "    {\"label\":\"30m exchange\",\"tone\":\"info\"},",
    "    {\"label\":\"round \{round_number}\",\"tone\":\"info\"},",
    "    {\"label\":\"review gated\",\"tone\":\"review\"}",
    "  ],",
    "  \"metrics\": [",
    "    {\"label\":\"Sub-area books\",\"value\":\"\{participants.length()}\",\"note\":\"active perspectives\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Idea reductions\",\"value\":\"\{ideas.length()}\",\"note\":\"cross-area questions\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Effectiveness\",\"value\":\"\{metrics.structural_effectiveness_score}/100\",\"note\":\"structural exchange score\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Research questions\",\"value\":\"\{metrics.research_question_count}\",\"note\":\"testable follow-ups\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Home returns\",\"value\":\"\{metrics.idea_return_home_count}\",\"note\":\"idea-book routes\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Review gates\",\"value\":\"1\",\"note\":\"research program quality\",\"tone\":\"review\"}",
    "  ],",
    "  \"readiness\": [",
    "    {\"title\":\"Building synthesis\",\"detail\":\"wiki/civic/embodied-robotics-salon.md\",\"meta\":\"Ready\"},",
    "    {\"title\":\"Question backlog\",\"detail\":\"wiki/queries/embodied-robotics-salon.md\",\"meta\":\"Ready\"},",
    "    {\"title\":\"Effectiveness metrics\",\"detail\":\"wiki/metrics/embodied-robotics-salon.md\",\"meta\":\"Ready\"},",
    "    {\"title\":\"Review queue\",\"detail\":\"wiki/reviews/embodied-robotics-salon.md\",\"meta\":\"Pending\"}",
    "  ],",
    "  \"review_queue\": [",
    "    {\"title\":\"Research program quality\",\"detail\":\"wiki/reviews/embodied-robotics-salon.md\",\"meta\":\"Pending\"}",
    "  ],",
    "  \"page_families\": \{projection_page_families_json(participants, ideas)},",
    "  \"journey\": [",
    "    {\"title\":\"Embodied robotics salon round \{round_number}\",\"stage\":\"exchange-reduce-distribute\",\"status\":\"review\",\"summary\":\"The building received 10 domain perspectives and reduced them into five research programs worth ongoing review.\",\"highlights\": \{json_string_array(highlights)}}",
    "  ],",
    "  \"links\": [",
    "    {\"label\":\"Question backlog\",\"kind\":\"wiki\",\"url\":\"wiki/queries/embodied-robotics-salon.md\"},",
    "    {\"label\":\"Effectiveness metrics\",\"kind\":\"wiki\",\"url\":\"wiki/metrics/embodied-robotics-salon.md\"},",
    "    {\"label\":\"Review queue\",\"kind\":\"wiki\",\"url\":\"wiki/reviews/embodied-robotics-salon.md\"}",
    "  ]",
    "}",
  ].join("\n")
}

///|
fn projection_page_families_json(
  participants : Array[EmbodiedRoboticsParticipantBook],
  ideas : Array[EmbodiedRoboticsSalonIdea],
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
fn embodied_robotics_building_html(
  protocol : @civic.BuildingProtocolDefinition,
  participants : Array[EmbodiedRoboticsParticipantBook],
  ideas : Array[EmbodiedRoboticsSalonIdea],
  metrics : EmbodiedRoboticsSalonMetric,
  round_id : String,
  round_number : Int,
) -> String {
  [
    "<!doctype html>",
    "<html lang=\"en\">",
    "<head>",
    "  <meta charset=\"utf-8\">",
    "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
    "  <title>Embodied Robotics Salon</title>",
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
    "    <h1>Embodied Robotics Salon</h1>",
    "    <p><code>\{round_id}</code> <code>round \{round_number}</code></p>",
    "    <p>Ten sub-area MoonBooks exchange focused views every 30 minutes, then Social Square reduces the plurality into research questions worth ongoing work.</p>",
    "    <p><code>\{participants.length()} sub-area books</code> <code>\{ideas.length()} idea reductions</code> <code>review gated</code></p>",
    "    <div class=\"metric\">",
    "      <div class=\"stat\"><b>\{metrics.structural_effectiveness_score}/100</b><span>structural effectiveness</span></div>",
    "      <div class=\"stat\"><b>\{metrics.research_question_count}</b><span>research questions</span></div>",
    "      <div class=\"stat\"><b>\{metrics.idea_return_home_count}</b><span>idea-home returns</span></div>",
    "      <div class=\"stat\"><b>\{metrics.average_books_per_idea}</b><span>books per idea</span></div>",
    "    </div>",
    "  </section>",
    "  <h2>Sub-area MoonBooks</h2>",
    "  <section class=\"grid\">\{embodied_robotics_participant_cards(participants)}</section>",
    "  <h2>Reduced Research Ideas</h2>",
    "  <section class=\"grid\">\{embodied_robotics_idea_cards(ideas)}</section>",
    "</main></body></html>",
  ].join("\n")
}

///|
fn embodied_robotics_participant_cards(
  participants : Array[EmbodiedRoboticsParticipantBook],
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
fn embodied_robotics_idea_cards(
  ideas : Array[EmbodiedRoboticsSalonIdea],
) -> String {
  let builder = StringBuilder::new()
  for idea in ideas {
    builder.write_string(
      "<article class=\"card idea\"><h3>\{idea.title}</h3><p>\{idea.summary}</p><p><strong>Why:</strong> \{idea.why_it_matters}</p><p><strong>Next:</strong> \{idea.next_experiment}</p></article>",
    )
  }
  builder.to_string()
}

///|
fn embodied_robotics_participant_table(
  participants : Array[EmbodiedRoboticsParticipantBook],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("| MoonBook | Focus | Current Question |\n")
  builder.write_string("| --- | --- | --- |\n")
  for participant in participants {
    builder.write_string(
      "|\{participant.book_id}|\{participant.focus_area}|\{participant.current_question}|\n",
    )
  }
  builder.to_string().trim().to_string()
}

///|
fn embodied_robotics_idea_sections(
  ideas : Array[EmbodiedRoboticsSalonIdea],
) -> String {
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
  builder.to_string().trim().to_string()
}

///|
fn json_escape(text : String) -> String {
  text
  .replace(old="\\", new="\\\\")
  .replace(old="\"", new="\\\"")
  .replace(old="\n", new=" ")
}

///|
fn json_string(text : String) -> String {
  "\"\{json_escape(text)}\""
}

///|
fn json_string_array(items : Array[String]) -> String {
  let encoded : Array[String] = []
  for item in items {
    encoded.push(json_string(item))
  }
  "[\{encoded.join(",")}]"
}
