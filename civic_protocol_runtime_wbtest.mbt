///|
async test "Social Square protocol proof slice has inbox reduction outbox and review" {
  let root = "/tmp/moontown-protocol-social-square"
  ignore_checked_command("rm", ["-rf", root])
  let registry_path = "\{root}/protocols.json"
  let status_path = "\{root}/protocol-status.json"
  ignore(bootstrap_wenyu_building_protocols(registry_path~, status_path~))
  let portfolio = inspect_wenyu_building_protocols(status_path~, registry_path~)
  let social = portfolio.protocols
    .filter(fn(item) { item.building_id == "social-square" })
    .get(0)
    .unwrap()
  assert_eq(social.protocol_mode, "exchange-reduce-distribute")
  assert_eq(social.status, "review")
  assert_true(social.ready)
  assert_true(social.inbox_count >= 1)
  assert_true(social.contribution_count >= 1)
  assert_true(social.reduction_count >= 1)
  assert_true(social.outbox_count >= 1)
  assert_true(social.review_count >= 1)
  assert_true(!social.latest_reduction_summary.is_empty())
  assert_true(@fs.exists(status_path))
}

///|
test "Protocol status labels follow packet lifecycle" {
  assert_eq(
    protocol_status_label(
      inbox_count=0,
      contribution_count=0,
      reduction_count=0,
      outbox_count=0,
      review_count=0,
    ),
    "defined",
  )
  assert_eq(
    protocol_status_label(
      inbox_count=1,
      contribution_count=0,
      reduction_count=0,
      outbox_count=0,
      review_count=0,
    ),
    "inbox",
  )
  assert_eq(
    protocol_status_label(
      inbox_count=1,
      contribution_count=1,
      reduction_count=1,
      outbox_count=1,
      review_count=0,
    ),
    "reduced",
  )
  assert_eq(
    protocol_status_label(
      inbox_count=1,
      contribution_count=1,
      reduction_count=1,
      outbox_count=1,
      review_count=1,
    ),
    "review",
  )
}

///|
test "civic communication patterns describe reusable protocol shapes" {
  let patterns = civic_communication_patterns()
  assert_true(patterns.length() >= 8)
  match civic_communication_pattern_for_id("research-salon") {
    Some(pattern) => {
      assert_eq(pattern.title, "Research Salon")
      assert_eq(pattern.protocol_mode, "exchange-reduce-distribute")
    }
    None => fail("expected research salon pattern")
  }
  let service = @civic.wenyu_civic_services().filter(fn(item) {
      item.id == "social-square"
    })[0]
  assert_eq(civic_communication_pattern_id_for_service(service), "match-market")
}

///|
test "civic salon scenario carries participant workspaces and cross-area ideas" {
  let scenario = test_civic_salon_scenario()
  let participants = scenario.participants
  let ideas = scenario.ideas
  assert_eq(participants.length(), 2)
  assert_eq(ideas.length(), 1)
  let seen : Array[String] = []
  for participant in participants {
    assert_true(!participant.current_question.is_empty())
    assert_true(!seen.contains(participant.book_id))
    seen.push(participant.book_id)
  }
  for idea in ideas {
    assert_true(idea.participating_books.length() >= 2)
    assert_true(idea.research_questions.length() >= 2)
    assert_true(!idea.next_experiment.is_empty())
    for book_id in idea.participating_books {
      assert_true(seen.contains(book_id))
    }
  }
}

///|
test "civic salon metrics count idea yield and home returns" {
  let scenario = test_civic_salon_scenario()
  let participants = scenario.participants
  let ideas = scenario.ideas
  let metrics = civic_salon_metrics(scenario, participants, ideas)
  assert_eq(metrics.participant_count, 2)
  assert_eq(metrics.idea_count, 1)
  assert_eq(metrics.research_question_count, 2)
  assert_eq(metrics.participant_idea_links, 2)
  assert_eq(metrics.participating_book_coverage_count, 2)
  assert_eq(metrics.idea_return_home_count, 2)
  assert_eq(metrics.average_books_per_idea, "2/1 = 2.0")
  assert_true(metrics.structural_effectiveness_score > 0)
  for participant in participants {
    let returned = civic_salon_returned_ideas_for_book(
      participant.book_id,
      ideas,
    )
    assert_true(returned.length() > 0)
  }
}

///|
test "civic salon home return records map every idea to home books" {
  let scenario = test_civic_salon_scenario()
  let ideas = scenario.ideas
  let records = civic_salon_home_return_records(
    scenario, "social-square", ideas,
  )
  assert_eq(records.length(), 2)
  for record in records {
    assert_eq(record.target_path, "wiki/queries/salon-returned-ideas.md")
    assert_eq(record.review_status, "pending")
  }
}

///|
async test "civic salon scenario template can seed a non-hardcoded domain" {
  let root = "/tmp/moontown-civic-salon-template"
  ignore_checked_command("rm", ["-rf", root])
  let template_path = "\{root}/template.json"
  let book_catalog_path = "\{root}/catalog.json"
  let scenario = test_civic_salon_scenario()
  write_text_file(template_path, scenario.to_json().stringify(indent=2))
  let summary = bootstrap_civic_salon_scenario_file(
    template_path,
    book_catalog_path~,
    round_id="future-energy-round-1",
    round_number=1,
    workspace_base=root,
    reducer_mode=FixtureReducer,
  )
  assert_true(summary.contains("Future Energy Social Square Salon"))
  assert_true(summary.contains("2 internal participant perspective"))
  assert_true(
    @fs.exists(
      "\{root}/books/future-energy-storage/raw/bootstrap/FUTURE_ENERGY_SALON_CONTRACT.md",
    ),
  )
  let projection = @fs.read_file(
    "\{root}/books/wenyu-social-square/book/moonbook-ui-state.json",
  ).text()
  assert_true(projection.contains("Future Energy Social Square Salon"))
  assert_true(projection.contains("future energy"))
  assert_true(projection.contains("\"projection_scope\": \"public\""))
  let returned = @fs.read_file(
    "\{root}/books/future-energy-grid-ai/wiki/queries/salon-returned-ideas.md",
  ).text()
  assert_true(returned.contains("Storage-Grid Control Contract"))
  let participant_projection = @fs.read_file(
    "\{root}/books/future-energy-grid-ai/book/moonbook-ui-state.json",
  ).text()
  assert_true(
    participant_projection.contains("\"projection_scope\": \"internal\""),
  )
  assert_true(participant_projection.contains("\"participant-workspace\""))
}

///|
async test "civic salon scenario can define a building protocol without registry code" {
  let root = "/tmp/moontown-civic-salon-generic-building"
  ignore_checked_command("rm", ["-rf", root])
  let scenario = {
    ..test_civic_salon_scenario(),
    id: "future-energy-forum",
    title: "Future Energy Forum Salon",
    building_id: "future-energy-forum",
    building_book_id: "future-energy-forum-book",
  }
  let summary = bootstrap_civic_salon_scenario(
    scenario,
    book_catalog_path="\{root}/catalog.json",
    round_id="future-energy-forum-round-1",
    round_number=1,
    workspace_base=root,
    reducer_mode=FixtureReducer,
  )
  assert_true(summary.contains("Future Energy Forum Salon"))
  assert_true(
    @fs.exists(
      "\{root}/books/future-energy-forum-book/book/moonbook-ui-state.json",
    ),
  )
  let projection = @fs.read_file(
    "\{root}/books/future-energy-forum-book/book/moonbook-ui-state.json",
  ).text()
  assert_true(projection.contains("\"book_id\": \"future-energy-forum-book\""))
  assert_true(projection.contains("\"projection_scope\": \"public\""))
  let protocol = civic_salon_protocol_for_scenario(scenario)
  assert_eq(protocol.building_id, "future-energy-forum")
  assert_eq(protocol.book_id, "future-energy-forum-book")
  assert_eq(protocol.input_channels.length(), 1)
  assert_eq(protocol.input_channels[0], "domain_perspective")
}

///|
test "civic salon participant workspaces do not pollute the public catalog" {
  let scenario = test_civic_salon_scenario()
  let stale_participant = @moonbook.BookCatalogEntry::new(
    id=scenario.participants[0].book_id,
    name="Old participant",
    purpose="stale intermediate participant book",
    workspace_root="/tmp/moontown-civic-salon-template/books/\{scenario.participants[0].book_id}",
  )
  let durable_book = @moonbook.BookCatalogEntry::new(
    id=scenario.building_book_id,
    name="Durable building book",
    purpose="public salon aggregate",
    workspace_root="/tmp/moontown-civic-salon-template/books/\{scenario.building_book_id}",
  )
  let merged = merge_civic_salon_catalog(
    scenario,
    [durable_book, stale_participant],
    scenario.participants,
    "/tmp/moontown-civic-salon-template",
  )
  assert_eq(merged.length(), 1)
  assert_eq(merged[0].id, scenario.building_book_id)
}

///|
async test "MoonClaw reducer workspace excludes template seed ideas" {
  let root = "/tmp/moontown-civic-salon-reducer-input"
  ignore_checked_command("rm", ["-rf", root])
  let scenario = test_civic_salon_scenario()
  write_civic_salon_reducer_workspace(
    scenario, root, "future-energy-round-2", 2,
  )
  let input = @fs.read_file(
    "\{root}/raw/bootstrap/civic-salon-reducer-input.md",
  ).text()
  let participants = @fs.read_file(
    "\{root}/raw/bootstrap/civic-salon-participants.json",
  ).text()
  let skill = @fs.read_file("\{root}/skills/future-energy-salon/SKILL.md").text()
  assert_true(!input.contains("storage-grid-control-contract"))
  assert_true(!participants.contains("storage-grid-control-contract"))
  assert_true(skill.contains("CivicSalonIdea"))
  assert_true(@fs.exists("\{root}/moonclaw.jobs.json"))
}

///|
async test "civic salon reducer parses object ideas contract" {
  let root = "/tmp/moontown-civic-salon-reducer-contract"
  ignore_checked_command("rm", ["-rf", root])
  let scenario = test_civic_salon_scenario()
  let path = "\{root}/ideas.json"
  write_text_file(
    path,
    Json::object({ "ideas": scenario.ideas.to_json() }).stringify(indent=2),
  )
  match load_civic_salon_ideas_file(path) {
    Some(ideas) => {
      assert_eq(ideas.length(), 1)
      assert_eq(ideas.get(0).unwrap().id, "storage-grid-control-contract")
    }
    None => fail("expected reducer ideas JSON")
  }
}

///|
fn test_civic_salon_scenario() -> CivicSalonScenario {
  {
    id: "future-energy-social-square",
    title: "Future Energy Social Square Salon",
    communication_pattern_id: Some("research-salon"),
    communication_pattern_label: Some("Research Salon"),
    building_id: "social-square",
    building_book_id: "wenyu-social-square",
    domain_label: "future energy",
    topic: "future energy cross-area exchange",
    cadence: "operator-triggered salon",
    skill_name: "future-energy-salon",
    skill_description: "Exchange future-energy perspectives and reduce them into testable research questions.",
    protocol_channel: "domain_perspective",
    reduction_kind: "cross_area_research_idea",
    output_channel: "research_question_backlog",
    review_gate: "research_program_quality",
    review_owner: "keeper",
    review_reason: "keeper reviews novelty, feasibility, evidence gaps, and owner books",
    backlog_path: "wiki/queries/future-energy-salon.md",
    synthesis_path: "wiki/civic/future-energy-salon.md",
    metrics_path: "wiki/metrics/future-energy-salon.md",
    review_path: "wiki/reviews/future-energy-salon.md",
    returned_ideas_path: "wiki/queries/salon-returned-ideas.md",
    participant_contract_path: "raw/bootstrap/FUTURE_ENERGY_SALON_CONTRACT.md",
    quality_rules: [
      "Every output must connect more than one participant book.", "Every idea must include a testable next experiment.",
    ],
    skill_rules: [
      "Bring one domain-specific bottleneck.", "Turn disagreements into questions rather than accepted facts.",
    ],
    participants: [
      {
        book_id: "future-energy-storage",
        title: "Storage Desk",
        focus_area: "long-duration storage",
        perspective: "Storage bottlenecks determine whether intermittent supply becomes useful capacity.",
        cadence: "operator-triggered salon",
        current_question: "Which storage constraints most change deployment economics?",
        contribution: "Storage contributes cost, duration, degradation, and siting constraints.",
        next_artifact: "wiki/queries/storage-constraints.md",
      },
      {
        book_id: "future-energy-grid-ai",
        title: "Grid AI Desk",
        focus_area: "grid forecasting and autonomous control",
        perspective: "Grid AI matters only when it respects physical constraints and operator trust.",
        cadence: "operator-triggered salon",
        current_question: "Which control decisions are safe enough for autonomy?",
        contribution: "Grid AI contributes forecasting, dispatch policy, and operator-review loops.",
        next_artifact: "wiki/queries/grid-ai-control.md",
      },
    ],
    ideas: [
      {
        id: "storage-grid-control-contract",
        title: "Storage-Grid Control Contract",
        summary: "Define the interface between long-duration storage constraints and AI grid-control decisions.",
        participating_books: ["future-energy-storage", "future-energy-grid-ai"],
        research_questions: [
          "Which storage constraints must a grid-control model see before dispatch?",
          "What operator review gate is needed before autonomous storage dispatch?",
        ],
        why_it_matters: "It turns a cross-domain dependency into a concrete protocol contract.",
        next_experiment: "Prototype a dispatch schema that carries duration, degradation, confidence, and review status.",
      },
    ],
  }
}
