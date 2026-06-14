///|
test "book policy separates execute and tend lanes" {
  let policy = research()
  let execute = execute_skills(policy)
  let tend = tend_skills(policy)
  assert_true(execute.length() >= 2)
  assert_true(tend.length() >= 2)
  assert_true(has_skill(policy, "standing-watch"))
  assert_true(has_skill(policy, "claim-audit"))
  assert_false(has_skill(policy, "protocol-round"))
}

///|
test "book policy lanes are parsed through explicit lane model" {
  assert_eq(lane_from_text("execute"), BookLane::Execute)
  assert_eq(lane_from_text("TEND"), BookLane::Tend)
  assert_eq(lane_text(BookLane::Control), "control")
  let custom = lane_from_text("experimental")
  assert_true(custom is BookLane::Unknown("experimental"))
  let policy = new(
    [
      skill("run", " EXECUTE ", "now", "run fast loop"),
      skill("reflect", "tend", "slow", "slow loop"),
      skill("invalid", "invented", "never", "should not join core lanes"),
    ],
    [],
    quality(0, 0, false, "lane test"),
    output("none", "test", "none"),
  )
  assert_eq(execute_skills(policy).length(), 1)
  assert_eq(tend_skills(policy).length(), 1)
  assert_true(has_skill(policy, "invalid"))
}

///|
test "book policy required files include only required paths" {
  let policy = research()
  let required = required_file_paths(policy)
  assert_true(required.contains("wiki/synthesis/overview.md"))
  assert_true(required.contains("wiki/sources/"))
  assert_false(required.contains("raw/bootstrap/evidence-matrix.md"))
}

///|
test "policy archetypes are composable presets not runtime categories" {
  let plan = planbook()
  let civic = civic_protocol()
  let course = course()
  assert_true(has_skill(plan, "repair-dispatch"))
  assert_true(has_skill(civic, "protocol-round"))
  assert_true(has_skill(course, "course-project"))
  assert_true(tend_skills(plan).length() > 0)
  assert_true(tend_skills(civic).length() > 0)
  assert_true(tend_skills(course).length() > 0)
}

///|
test "policy owns catalog classification and legacy type labels" {
  assert_eq(research_type(), "research-book")
  assert_eq(course_type(), "course-book")
  assert_eq(book_type_marker(course_type()), "type: `course-book`")
  assert_eq(book_type_line(research_type()), "Book type: `research-book`")
  assert_eq(book_type_bullet(civic_type()), "- Type: `civic-protocol-support`")
  assert_true(reviewable_types().contains(civic_type()))
  assert_true(catalog_entry_archived(["internal"]))
  assert_false(catalog_entry_archived(["research"]))
  assert_true(
    catalog_entry_transient(
      "research-smoke", "Smoke Test", "temporary smoke test",
    ),
  )
  assert_false(
    catalog_entry_active(
      "research-smoke",
      "Smoke Test",
      "temporary smoke test",
      ["research"],
    ),
  )
  assert_true(
    catalog_entry_active("research-opc", "One Person Company", "domain watch", [
      "research",
    ]),
  )
  assert_eq(
    catalog_entry_type("plan-moontown-quality", "Moontown Quality", []),
    planbook_type(),
  )
  assert_eq(
    catalog_entry_type("course-wenyu-game-design", "Game Design", []),
    course_type(),
  )
  assert_eq(
    catalog_entry_type("wenyu-policy-hall", "Policy Hall", []),
    civic_type(),
  )
  assert_eq(catalog_entry_type("coding", "Coding", []), operational_type())
  assert_eq(catalog_entry_type("unknown", "Unknown", []), general_type())
  match
    catalog_research_topic_hint("research-euv-v2", "EUV", [
      "research", "topic:euv-lithography",
    ]) {
    Some(topic) => assert_eq(topic, "euv-lithography")
    None => fail("expected tagged research topic")
  }
  match catalog_research_topic_hint("research-opc", "OPC", []) {
    Some(topic) => assert_eq(topic, "opc")
    None => fail("expected storage research topic")
  }
  assert_true(catalog_research_topic_hint("coding", "Coding", []) is None)
}

///|
test "policy profiles map legacy labels into composed policies" {
  match policy_profile_for_type(research_type()) {
    Some(profile) => {
      assert_eq(profile.source_policy, web_first_policy())
      assert_true(has_skill(profile.policy, "standing-watch"))
    }
    None => fail("expected research profile")
  }
  match policy_profile_for_type(civic_type()) {
    Some(profile) => {
      assert_eq(profile.source_policy, book_first_policy())
      assert_true(has_skill(profile.policy, "protocol-round"))
    }
    None => fail("expected civic profile")
  }
  assert_true(policy_profile_for_type("unknown-book") is None)
  assert_eq(source_policy_for_type("unknown-book"), book_first_policy())
  assert_eq(
    source_policy_or_default("", web_first_policy()),
    web_first_policy(),
  )
  assert_eq(
    source_policy_or_default(" book-first ", web_first_policy()),
    book_first_policy(),
  )
  assert_true(has_skill(policy_for_type("unknown-book"), "workspace-bootstrap"))
}

///|
test "policy owns serialized loop metadata shape" {
  let metadata = policy_context_metadata_for_type(research_type()).stringify()
  assert_true(metadata.contains("\"book_type\":\"research-book\""))
  assert_true(metadata.contains("\"book_policy\":{"))
  assert_true(metadata.contains("\"book_loop_plan\":{"))
  assert_true(metadata.contains("\"book_internal_distance_plan\":["))
  assert_true(metadata.contains("\"phase\":\"read-policy\""))
  assert_true(metadata.contains("\"layer\":\"information\""))
  assert_true(metadata.contains("\"layer\":\"recognition\""))
  assert_true(metadata.contains("\"layer\":\"decisiveness\""))
  let catalog_metadata = catalog_policy_context_metadata(
    "wenyu-policy-hall",
    "Policy Hall",
    [],
  ).stringify()
  assert_true(
    catalog_metadata.contains("\"book_type\":\"civic-protocol-support\""),
  )
}

///|
test "policy capabilities compose without duplicate skills or files" {
  let policy = general() |> with_pdf_watch() |> with_pdf_watch()
  let pdf_skills = skill_specs(policy).filter(skill => skill.id == "pdf-watch")
  let pdf_files = required_file_specs(policy).filter(file => {
    file.path == "raw/pdf/"
  })
  assert_eq(pdf_skills.length(), 1)
  assert_eq(pdf_files.length(), 1)
  assert_true(has_skill(policy, "pdf-analysis"))
  assert_true(required_file_paths(policy).contains("wiki/sources/pdf-index.md"))
}

///|
test "web tool surface is a policy capability not a separate book type" {
  let policy = research()
    |> with_web_tool_surface(
      contract="moontown.book.custom-tool.v1",
      projection_path="book/site/generated/app.html",
    )
  assert_true(has_skill(policy, "tool-projection"))
  assert_true(has_skill(policy, "tool-review"))
  assert_eq(output_surface(policy), "web-tool")
  assert_eq(output_contract(policy), "moontown.book.custom-tool.v1")
  assert_eq(output_projection_path(policy), "book/site/generated/app.html")
}

///|
test "policy capability ids are derived from composed policy choices" {
  let policy = general()
    |> with_standing_watch()
    |> with_pdf_watch()
    |> with_web_tool_surface(
      contract="moontown.book.tool.v1",
      projection_path="book/site/generated/tool.html",
    )
  let capabilities = capability_ids(policy)
  assert_true(capabilities.contains(standing_watch_capability()))
  assert_false(capabilities.contains(research_evidence_capability()))
  assert_true(capabilities.contains(pdf_watch_capability()))
  assert_true(capabilities.contains(web_tool_surface_capability()))
  assert_true(!capabilities.contains(generated_site_capability()))
  assert_true(has_capability(policy, pdf_watch_capability()))
  assert_false(has_capability(policy, "missing"))
}

///|
test "generated-site capability remains derived from output surface" {
  assert_true(has_capability(research(), generated_site_capability()))
  assert_false(has_capability(research(), web_tool_surface_capability()))
}

///|
test "catalog entry policy exposes capabilities without downstream type checks" {
  assert_true(
    catalog_entry_runs_standing_watch("research-opc", "OPC", ["research"]),
  )
  assert_true(
    catalog_entry_runs_research_evidence("research-opc", "OPC", ["research"]),
  )
  assert_false(
    catalog_entry_runs_standing_watch("course-game", "Game", ["course"]),
  )
  assert_false(
    catalog_entry_runs_research_evidence("course-game", "Game", ["course"]),
  )
  assert_true(
    catalog_entry_runs_civic_protocol("wenyu-policy-hall", "Policy Hall", []),
  )
  assert_false(
    catalog_entry_runs_civic_protocol("research-opc", "OPC", ["research"]),
  )
  let policy = catalog_entry_policy("wenyu-policy-hall", "Policy Hall", [])
  assert_true(has_capability(policy, civic_protocol_capability()))
}

///|
test "policy owns default generated site projection path" {
  assert_eq(
    default_generated_site_projection_path(),
    "book/site/generated/index.html",
  )
  assert_eq(default_generated_site_surface(), "generated-site")
  assert_eq(output_surface(research()), default_generated_site_surface())
  assert_eq(
    output_projection_path(research()),
    default_generated_site_projection_path(),
  )
}

///|
test "policy health evaluates required files and lane availability" {
  let policy = research()
  let health = evaluate_health(policy, 95, Some(85), [
    "wiki/synthesis/overview.md", "wiki/sources/", "wiki/history/standing-watch.md",
  ])
  assert_true(health.ready)
  assert_eq(health.status, "ready")
  assert_eq(health.execute_skill_count, 2)
  assert_eq(health.tend_skill_count, 2)
  let missing = evaluate_health(policy, 95, Some(85), ["wiki/sources/"])
  assert_false(missing.ready)
  assert_eq(missing.status, "missing-required-files")
  assert_true(
    missing.missing_required_files.contains("wiki/synthesis/overview.md"),
  )
}

///|
test "policy health uses policy-specific semantic threshold" {
  let policy = with_quality(
    research(),
    quality(90, 88, true, "semantic threshold should be policy-owned"),
  )
  let health = evaluate_health(policy, 95, Some(87), [
    "wiki/synthesis/overview.md", "wiki/sources/", "wiki/history/standing-watch.md",
  ])
  assert_false(health.ready)
  assert_eq(health.status, "below-semantic-threshold")
}

///|
test "policy loop exposes read execute record tend evaluate order" {
  let plan = loop_plan(research())
  assert_true(plan.steps.length() >= 6)
  assert_eq(plan.steps[0].phase, "read-policy")
  assert_eq(plan.steps[1].phase, "execute-skill")
  assert_eq(plan.steps[2].phase, "execute-skill")
  assert_eq(plan.steps[3].phase, "record-results")
  assert_eq(plan.steps[4].phase, "tend-skill")
  assert_eq(plan.steps[plan.steps.length() - 1].phase, "evaluate-health")
  assert_eq(plan.required_record_contract, "moontown.book.research.v1")
}

///|
test "policy loop markdown names dual lanes and health gate" {
  let text = loop_markdown(planbook())
  assert_true(text.contains("Book loop:"))
  assert_true(text.contains("`read-policy` lane=`control`"))
  assert_true(text.contains("`execute-skill` lane=`execute`"))
  assert_true(text.contains("`tend-skill` lane=`tend`"))
  assert_true(text.contains("`evaluate-health` lane=`tend`"))
  assert_true(text.contains("result contract: `moontown.book.planbook.v1`"))
  assert_true(text.contains("validation evidence"))
}

///|
test "policy internal distance plan maps execute tend and quality gates" {
  assert_eq(
    internal_distance_layer_from_text("Information"),
    InternalDistanceLayer::Information,
  )
  assert_eq(
    internal_distance_layer_text(InternalDistanceLayer::Decisiveness),
    "decisiveness",
  )
  let steps = internal_distance_plan(research())
  assert_eq(steps.length(), 3)
  assert_eq(steps[0].layer, "information")
  assert_true(steps[0].subjects.contains("standing-watch"))
  assert_eq(steps[1].layer, "recognition")
  assert_true(steps[1].subjects.contains("claim-audit"))
  assert_eq(steps[2].layer, "decisiveness")
  assert_true(steps[2].subjects.contains("moontown.book.research.v1"))
}

///|
test "policy markdown includes internal distance section" {
  let text = markdown(planbook())
  assert_true(text.contains("Internal distances:"))
  assert_true(text.contains("unknown -> known"))
  assert_true(text.contains("known -> matters"))
  assert_true(text.contains("matters -> act"))
  assert_true(text.contains("repair-dispatch"))
  assert_true(text.contains("architecture-review"))
}

///|
test "policy owns reusable goal text vocabulary" {
  assert_true(research_goal_text("research OPC companies"))
  assert_true(research_goal_text("Compare Moontown MoonBook and MoonClaw"))
  assert_true(
    research_goal_text(
      "Build Wenyu Valley AI Innovation Town according to docs/WENYU_VALLEY_PRD.md",
    ),
  )
  assert_true(wenyu_valley_goal_text("Wenyu Valley AI Innovation Town PRD"))
  assert_true(research_request_goal_text("compare lithography routes"))
  assert_true(research_request_goal_text("survey robotics world models"))
  assert_true(research_request_goal_text("map the hardware agent ecosystem"))
  assert_true(!research_goal_text("Create a bookkeeping workspace"))
  assert_true(!research_request_goal_text("Create a bookkeeping workspace"))
  assert_true(!wenyu_valley_goal_text("Create a bookkeeping workspace"))
  match research_topic_from_goal("research OPC companies") {
    Some(topic) => assert_eq(topic, "OPC companies")
    None => fail("expected research topic")
  }
  match research_topic_from_goal("survey robotics world models") {
    Some(topic) => assert_eq(topic, "robotics world models")
    None => fail("expected survey topic")
  }
  match research_topic_from_goal("compare the hardware ecosystem") {
    Some(topic) => assert_eq(topic, "hardware ecosystem")
    None => fail("expected comparison topic")
  }
  assert_true(research_topic_from_goal("   ") is None)
}
