///|
test "book quality consumes policy-owned taxonomy" {
  assert_eq(@policy.research_type(), "research-book")
  assert_eq(@policy.course_type(), "course-book")
  assert_true(@policy.reviewable_types().contains(@policy.civic_type()))
}

///|
test "policy package owns catalog classification" {
  assert_false(
    @policy.catalog_entry_active(
      "research-smoke",
      "Smoke Test",
      "temporary smoke test",
      ["research"],
    ),
  )
  assert_true(
    @policy.catalog_entry_active(
      "research-opc",
      "One Person Company",
      "domain watch",
      ["research"],
    ),
  )
  assert_eq(
    @policy.catalog_entry_type("plan-moontown-quality", "Moontown Quality", []),
    @policy.planbook_type(),
  )
  assert_eq(
    @policy.catalog_entry_type("course-wenyu-game-design", "Game Design", []),
    @policy.course_type(),
  )
  assert_eq(
    @policy.catalog_entry_type("wenyu-policy-hall", "Policy Hall", []),
    @policy.civic_type(),
  )
  assert_eq(
    @policy.catalog_entry_type("coding", "Coding", []),
    @policy.operational_type(),
  )
  assert_eq(
    @policy.catalog_entry_type("unknown", "Unknown", []),
    @policy.general_type(),
  )
}

///|
test "book quality generated site path follows policy projection default" {
  assert_eq(
    generated_site_path(),
    @policy.default_generated_site_projection_path(),
  )
  assert_eq(
    policy_type_output_path(@policy.research_type()),
    @policy.output_projection_path(@policy.research()),
  )
  let tool_policy = @policy.general()
    |> @policy.with_web_tool_surface(
      contract="tool.contract.v1",
      projection_path="book/site/generated/tool.html",
    )
  assert_eq(policy_output_path(tool_policy), "book/site/generated/tool.html")
  assert_eq(
    policy_output_required_path(tool_policy, 9).relative,
    "book/site/generated/tool.html",
  )
}

///|
test "book quality review result dir uses storage snapshot base" {
  assert_eq(
    review_result_dir_for_snapshot("town.json"),
    ".moontown/book-quality/ai-review-results",
  )
  assert_eq(
    review_result_dir_for_snapshot("/tmp/moontown/town.json"),
    "/tmp/moontown/book-quality/ai-review-results",
  )
}

///|
fn required_path_count_for_test(
  paths : Array[BookQualityRequiredPath],
  relative : String,
) -> Int {
  let mut count = 0
  for path in paths {
    if path.relative == relative {
      count += 1
    }
  }
  count
}

///|
test "book quality structural paths include policy required files without duplicates" {
  let research_paths = research_required_paths()
  assert_eq(
    required_path_count_for_test(
      research_paths, "raw/bootstrap/evidence-matrix.md",
    ),
    1,
  )
  assert_eq(
    required_path_count_for_test(research_paths, "wiki/synthesis/overview.md"),
    1,
  )
  assert_eq(required_path_count_for_test(research_paths, "wiki/sources/"), 1)
  let course_paths = course_required_paths()
  assert_eq(
    required_path_count_for_test(course_paths, "wiki/course/exercises.md"),
    1,
  )
  assert_eq(
    required_path_count_for_test(course_paths, "wiki/course/outline.md"),
    1,
  )
  assert_eq(
    required_path_count_for_test(course_paths, "wiki/course/lessons.md"),
    1,
  )
}

///|
test "book quality package owns operational book templates" {
  let index = operational_index(
    "ops-book",
    "/tmp/ops-book",
    "Ops Book",
    "Keeps operational memory.",
    ["review queue", "journey notes"],
  )
  assert_true(index.contains("- Book id: `ops-book`"))
  assert_true(index.contains("- Workspace: `/tmp/ops-book`"))
  assert_true(index.contains("- Type: `\{@policy.operational_type()}`"))
  assert_true(index.contains("- review queue"))
  assert_true(index.contains("skills/operational-keeper/SKILL.md"))
  let skill = operational_skill(
    "Ops Book", "## Quality Contract\n\n- Stay useful.",
  )
  assert_true(skill.contains("Operate `Ops Book` as durable workspace memory."))
  assert_true(skill.contains("## Quality Contract"))
  assert_true(skill.contains("## Concrete Example"))
  assert_true(skill.contains("operational_decision: update"))
}

///|
test "book quality package owns operational projection templates" {
  let state = operational_ui_state(
    "ops-book", "Ops <Book>", "Keeps review memory & boundaries.",
  )
  assert_true(state.contains("\"book_id\": \"ops-book\""))
  assert_true(state.contains("\"title\": \"Ops <Book>\""))
  assert_true(state.contains("\"status_chips\""))
  assert_true(
    state.contains(
      "\"label\":\{operational_json_string(@policy.operational_type())}",
    ),
  )
  assert_true(state.contains("\"page_families\""))
  let parsed = @json.parse(state) catch {
    _ => fail("operational UI state should parse")
  }
  assert_true(parsed.stringify().contains("\"book_id\":\"ops-book\""))
  let site = operational_site(
    "/tmp/ops-book", "Ops <Book>", "Keeps review memory & boundaries.",
  )
  assert_true(site.contains("<title>Ops &lt;Book&gt;</title>"))
  assert_true(site.contains("Keeps review memory &amp; boundaries."))
  assert_true(site.contains("<code>/tmp/ops-book</code>"))
}

///|
fn review_candidate_score_for_test(
  book_id : String,
  structural_score : Int,
) -> BookQualityScore {
  BookQualityScore::{
    book_id,
    title: book_id,
    book_type: @policy.research_type(),
    workspace_root: "/tmp/\{book_id}",
    structural_score,
    structural_grade: quality_grade(structural_score),
    semantic_score: None,
    semantic_grade: "pending-ai-review",
    quality_status: "pending-ai-review",
    score: structural_score,
    grade: quality_grade(structural_score),
    ready: false,
    strengths: [],
    gaps: [],
    next_action: "Review semantic quality.",
  }
}

///|
test "book quality package owns review candidate filtering from completed ids" {
  let weakest = review_candidate_score_for_test("weakest", 25)
  let middle = review_candidate_score_for_test("middle", 50)
  let strongest = review_candidate_score_for_test("strongest", 90)
  let pending = review_candidates_without_results(
    [strongest, weakest, middle],
    ["weakest"],
  )
  assert_eq(pending.length(), 2)
  assert_false(pending.any(fn(score) { score.book_id == "weakest" }))
  let candidate = first_review_candidate_without_results(
    [strongest, weakest, middle],
    ["weakest"],
  )
  assert_true(candidate is Some(_))
  assert_eq(candidate.unwrap().book_id, "middle")
  assert_true(
    first_review_candidate_without_results([strongest, weakest, middle], [
      "strongest", "weakest", "middle",
    ])
    is None,
  )
}

///|
async test "book quality package owns pending review selection from result files" {
  let weakest = review_candidate_score_for_test("weakest-file", 25)
  let middle = review_candidate_score_for_test("middle-file", 50)
  let strongest = review_candidate_score_for_test("strongest-file", 90)
  let audit = audit_from_scores("/tmp/catalog.json", [
    strongest, weakest, middle,
  ])
  let candidate = first_pending_review_score_for_completed(audit, [
    "weakest-file",
  ])
  assert_true(candidate is Some(_))
  assert_eq(candidate.unwrap().book_id, "middle-file")
}

///|
test "book quality package owns imported review run status and launch summary" {
  let dispatched = imported_review_run_from_observation(
    "book-run",
    "/tmp/packet.json",
    "/tmp/results",
    "proposal-run",
    Some("run-id"),
    "Imported proposal.",
    Some("moon run src/cmd/main -- proposal run run-id"),
    42UL,
  )
  assert_eq(dispatched.book_id, "book-run")
  assert_eq(dispatched.packet_path, "/tmp/packet.json")
  assert_eq(dispatched.result_path, "/tmp/results/book-run.md")
  assert_true(dispatched.proposal_id is Some("proposal-run"))
  assert_true(dispatched.run_id is Some("run-id"))
  assert_eq(dispatched.status, review_run_dispatched_status())
  assert_eq(
    dispatched.summary,
    "Imported proposal. Detached runner: moon run src/cmd/main -- proposal run run-id",
  )
  assert_eq(dispatched.generated_at_ms, 42UL)
  let queued = imported_review_run_from_observation(
    "book-run",
    "/tmp/packet.json",
    "/tmp/results",
    "proposal-run",
    None,
    "Imported proposal.",
    None,
    43UL,
  )
  assert_eq(queued.status, review_run_queued_status())
  assert_eq(queued.summary, "Imported proposal.")
}

///|
fn repair_bridge_item_for_goal_test(
  book_id : String,
) -> BookQualityRepairBridgeItem {
  BookQualityRepairBridgeItem::{
    book_id,
    book_type: @policy.research_type(),
    workspace_root: "/tmp/\{book_id}",
    semantic_score: 42,
    semantic_grade: "weak",
    repair_owner: "moonbook",
    next_repair_task: "Repair the book.",
    review_result_path: "/tmp/\{book_id}.md",
    book_review_path: "/tmp/\{book_id}/wiki/reviews/book-quality-repair.md",
    standing_goal_id: repair_goal_id(book_id),
    status: review_run_queued_status(),
    generated_at_ms: 1,
  }
}

///|
test "book quality package owns repair standing goal construction and refresh" {
  let item = repair_bridge_item_for_goal_test("research-robotics")
  let created = new_repair_standing_goal(item, 41)
  assert_eq(created.id, item.standing_goal_id)
  assert_eq(created.title, "Repair book quality: research-robotics")
  assert_true(created.target_book_id is Some("research-robotics"))
  assert_eq(created.next_due_tick, 42)
  assert_true(created.last_run_tick is None)
  assert_true(created.enabled)
  assert_eq(created.cadence_ticks, repair_goal_cadence_ticks())
  assert_eq(created.source_policy, @policy.web_first_policy())
  assert_eq(created.quality_threshold, semantic_ready_threshold())
  assert_true(created.prompt.contains("Repair the book."))
  let existing = @core.StandingGoal::new(
    id=item.standing_goal_id,
    title="Old title",
    prompt="Old prompt",
    target_book_id=Some(item.book_id),
    cadence_ticks=5,
    next_due_tick=99,
    last_run_tick=Some(88),
    enabled=false,
  )
  let refreshed = refreshed_repair_standing_goal(existing, item)
  assert_eq(refreshed.next_due_tick, 99)
  assert_true(refreshed.last_run_tick is Some(88))
  assert_true(refreshed.enabled)
  assert_eq(refreshed.cadence_ticks, repair_goal_cadence_ticks())
}

///|
test "book quality package owns repair standing goal upsert" {
  let item = repair_bridge_item_for_goal_test("research-robotics")
  let goals : Array[@core.StandingGoal] = []
  upsert_repair_standing_goal(goals, item, 10)
  assert_eq(goals.length(), 1)
  assert_eq(goals[0].next_due_tick, 11)
  let existing = @core.StandingGoal::new(
    id=item.standing_goal_id,
    title="Old title",
    prompt="Old prompt",
    target_book_id=Some(item.book_id),
    next_due_tick=31,
    last_run_tick=Some(30),
    enabled=false,
  )
  let other = @core.StandingGoal::new(
    id="other-goal",
    title="Other",
    prompt="Other",
  )
  let existing_goals = [other, existing]
  upsert_repair_standing_goal(existing_goals, item, 100)
  assert_eq(existing_goals.length(), 2)
  assert_eq(existing_goals[0].id, "other-goal")
  assert_eq(existing_goals[1].id, item.standing_goal_id)
  assert_eq(existing_goals[1].next_due_tick, 31)
  assert_true(existing_goals[1].last_run_tick is Some(30))
  assert_true(existing_goals[1].enabled)
  let ids = repair_goal_ids(existing_goals)
  assert_eq(ids.length(), 1)
  assert_eq(ids[0], item.standing_goal_id)
  let disabled = disabled_repair_standing_goal(existing_goals[1])
  assert_eq(disabled.id, item.standing_goal_id)
  assert_false(disabled.enabled)
  assert_eq(disabled.next_due_tick, 31)
  assert_true(disabled.last_run_tick is Some(30))
  assert_eq(disabled.cadence_ticks, existing_goals[1].cadence_ticks)
}

///|
test "book quality package maps legacy labels to composed policies" {
  match policy_spec_for_type(@policy.research_type()) {
    Some(spec) => {
      assert_eq(spec.profile.source_policy, @policy.web_first_policy())
      assert_true(spec.repair_action.contains("research quality review"))
      assert_true(@policy.has_skill(spec.profile.policy, "source-diarize"))
      assert_true(@policy.tend_skills(spec.profile.policy).length() > 0)
    }
    None => fail("expected research policy spec")
  }
  match policy_spec_for_type(@policy.civic_type()) {
    Some(spec) => {
      assert_eq(spec.profile.source_policy, @policy.book_first_policy())
      assert_true(spec.repair_action.contains("protocol-native loop"))
      assert_true(@policy.has_skill(spec.profile.policy, "protocol-round"))
      assert_eq(
        @policy.output_contract(spec.profile.policy),
        "moontown.book.civic.v1",
      )
    }
    None => fail("expected civic policy spec")
  }
  assert_true(policy_spec_for_type("unknown-book") is None)
  assert_eq(
    @policy.source_policy_for_type("unknown-book"),
    @policy.book_first_policy(),
  )
  assert_true(
    @policy.has_skill(
      @policy.policy_for_type("unknown-book"),
      "workspace-bootstrap",
    ),
  )
}

///|
test "book quality package owns scoring thresholds and next action" {
  assert_eq(clamp_score(-1), 0)
  assert_eq(clamp_score(120), 100)
  assert_eq(quality_grade(95), "world-class")
  assert_eq(
    workspace_path("/tmp/book", wiki_index_path()),
    "/tmp/book/wiki/index.md",
  )
  let required = required_path(generated_site_path(), 6)
  assert_eq(required.relative, generated_site_path())
  assert_eq(required.points, 6)
  let policy_required = policy_type_output_required_path(
    @policy.civic_type(),
    7,
  )
  assert_eq(
    policy_required.relative,
    @policy.output_projection_path(@policy.civic_protocol()),
  )
  assert_eq(policy_required.points, 7)
  let existing_path = path_presence_assessment("wiki/index.md", 7, true)
  assert_eq(existing_path.score, 7)
  assert_true(existing_path.strength is Some(_))
  assert_true(existing_path.gap is None)
  let missing_path = path_presence_assessment("wiki/missing.md", 7, false)
  assert_eq(missing_path.score, 0)
  assert_true(missing_path.strength is None)
  assert_true(missing_path.gap is Some(_))
  let base_complete = base_workspace_assessment(true, true, true)
  assert_eq(base_complete.score, 28)
  assert_eq(base_complete.strengths.length(), 3)
  assert_true(base_complete.gaps.is_empty())
  let base_missing = base_workspace_assessment(false, false, false)
  assert_eq(base_missing.score, 0)
  assert_eq(base_missing.gaps.length(), 3)
  assert_eq(research_deep_report_word_assessment(12000).score, 18)
  assert_eq(research_deep_report_word_assessment(8000).score, 12)
  assert_eq(research_deep_report_word_assessment(2000).score, 6)
  assert_eq(research_deep_report_word_assessment(1999).score, 0)
  let course_ok = course_identity_assessment(
    "course-town-design", "# Course\n\ntype: `course-book`\n",
  )
  assert_eq(course_ok.score, 8)
  assert_true(course_ok.strengths.contains("course identity is explicit"))
  let course_bad = course_identity_assessment(
    "research-town-design", "## Research Report\n",
  )
  assert_eq(course_bad.score, 0)
  assert_true(
    course_bad.gaps.contains(
      "course still looks research-shaped in id or index",
    ),
  )
  assert_eq(civic_latest_result_assessment(true).score, 10)
  assert_false(civic_latest_result_assessment(false).gaps.is_empty())
  assert_eq(cookbook_audit_link_assessment(true).score, 6)
  assert_false(cookbook_audit_link_assessment(false).gaps.is_empty())
  let complete_paths = path_set_assessment(["wiki/a.md", "wiki/b.md"], [], 10)
  assert_eq(complete_paths.score, 10)
  assert_true(complete_paths.strength is Some(_))
  assert_true(complete_paths.gap is None)
  let partial_paths = path_set_assessment(
    ["wiki/a.md", "wiki/b.md"],
    ["wiki/b.md"],
    10,
  )
  assert_eq(partial_paths.score, 5)
  assert_true(partial_paths.strength is None)
  assert_true(partial_paths.gap is Some(_))
  assert_eq(path_set_assessment([], [], 10).score, 10)
  let notes : Array[String] = []
  push_unique_note(notes, "same note")
  push_unique_note(notes, "same note")
  assert_eq(notes.length(), 1)
  assert_true(semantic_review_requires_repair(Some(79)))
  assert_false(semantic_review_requires_repair(Some(80)))
  assert_true(structural_quality_is_stable([], 90))
  assert_false(structural_quality_is_stable(["missing wiki/index.md"], 100))
  assert_eq(next_action(@policy.research_type(), [], 95, None), stable_action())
  assert_true(
    next_action(@policy.research_type(), [], 100, Some(64)).contains(
      "AI semantic review",
    ),
  )
  assert_true(
    next_action(@policy.course_type(), ["missing course"], 70, None).contains(
      "course projection",
    ),
  )
}

///|
test "book quality package owns repair standing-goal policy text" {
  let item = BookQualityRepairBridgeItem::{
    book_id: "course-ui",
    book_type: @policy.course_type(),
    workspace_root: "/tmp/course-ui",
    semantic_score: 52,
    semantic_grade: "weak",
    next_repair_task: "Replace research framing with lessons.",
    repair_owner: "moonbook",
    review_result_path: "/tmp/course-ui/review-result.md",
    book_review_path: "/tmp/course-ui/wiki/reviews/book-quality-repair.md",
    standing_goal_id: repair_goal_id("course-ui"),
    status: review_run_queued_status(),
    generated_at_ms: 1UL,
  }
  assert_eq(repair_goal_cadence_ticks(), 60)
  assert_eq(repair_goal_id_prefix(), "book-quality-repair-")
  assert_eq(repair_goal_id("course-ui"), "book-quality-repair-course-ui")
  assert_true(is_repair_goal_id(repair_goal_id("course-ui")))
  assert_false(is_repair_goal_id("standing-watch-course-ui"))
  assert_eq(
    repair_goal_source_policy(@policy.course_type()),
    @policy.book_first_policy(),
  )
  let prompt = repair_goal_prompt(item)
  assert_true(prompt.contains("Book id: `course-ui`"))
  assert_true(prompt.contains("Replace research framing with lessons."))
  assert_true(prompt.contains("do not create v1/v2/v3/v4 alternates"))
  let appendix = repair_goal_standing_watch_appendix()
  assert_true(appendix.contains("Book-quality repair mode"))
  assert_true(appendix.contains("wiki/reviews/book-quality-repair.md"))
  assert_true(
    appendix.contains("while the repair queue still names missing artifacts"),
  )
  assert_true(appendix.contains("Return `update` when durable book artifacts"))
  assert_true(repair_goal_generic_empty_review_summary("Inline run finished."))
  assert_true(repair_goal_generic_empty_review_summary("Workflow completed."))
  assert_false(
    repair_goal_generic_empty_review_summary(
      "Workflow completed.\nstanding_goal_decision: update",
    ),
  )
  assert_false(
    repair_goal_generic_empty_review_summary(
      "Inline run finished with pending_review item.",
    ),
  )
}

///|
test "book quality package owns repair bridge item construction" {
  let score = BookQualityScore::{
    book_id: "research-robotics",
    title: "Robotics",
    book_type: @policy.research_type(),
    workspace_root: "/tmp/research-robotics",
    structural_score: 72,
    structural_grade: "usable",
    semantic_score: None,
    semantic_grade: "pending-ai-review",
    quality_status: "pending-ai-review",
    score: 72,
    grade: "usable",
    ready: false,
    strengths: [],
    gaps: [],
    next_action: "fallback repair",
  }
  let item = repair_bridge_item(
    score,
    "/tmp/result.md",
    [
      "ai_quality_score: 71", "ai_quality_grade: usable", "repair_owner: moonbook",
      "next_repair_task: improve source synthesis",
    ].join("\n"),
    71,
    generated_at_ms=99UL,
  )
  assert_eq(item.book_id, "research-robotics")
  assert_eq(item.semantic_grade, "usable")
  assert_eq(item.repair_owner, "moonbook")
  assert_eq(item.next_repair_task, "improve source synthesis")
  assert_eq(item.review_result_path, "/tmp/result.md")
  assert_eq(
    item.book_review_path,
    "/tmp/research-robotics/wiki/reviews/book-quality-repair.md",
  )
  assert_eq(item.standing_goal_id, repair_goal_id("research-robotics"))
  assert_eq(item.generated_at_ms, 99UL)
}

///|
test "book quality package owns repair bridge review-text candidate policy" {
  let score = BookQualityScore::{
    book_id: "research-robotics",
    title: "Robotics",
    book_type: @policy.research_type(),
    workspace_root: "/tmp/research-robotics",
    structural_score: 72,
    structural_grade: "usable",
    semantic_score: None,
    semantic_grade: "pending-ai-review",
    quality_status: "pending-ai-review",
    score: 72,
    grade: "usable",
    ready: false,
    strengths: [],
    gaps: [],
    next_action: "fallback repair",
  }
  assert_true(
    repair_bridge_item_from_review_text(
      score,
      "/tmp/result.md",
      "ai_quality_score: \{semantic_ready_threshold()}\nnext_repair_task: no repair\n",
      generated_at_ms=1UL,
    )
    is None,
  )
  match
    repair_bridge_item_from_review_text(
      score,
      "/tmp/result.md",
      "ai_quality_score: \{semantic_ready_threshold() - 1}\nai_quality_grade: weak\nrepair_owner: moonbook\nnext_repair_task: build better evidence\n",
      generated_at_ms=2UL,
    ) {
    Some(item) => {
      assert_eq(item.book_id, "research-robotics")
      assert_eq(item.semantic_score, semantic_ready_threshold() - 1)
      assert_eq(item.semantic_grade, "weak")
      assert_eq(item.repair_owner, "moonbook")
      assert_eq(item.next_repair_task, "build better evidence")
      assert_eq(item.generated_at_ms, 2UL)
    }
    None => fail("expected weak semantic review to create a repair item")
  }
}

///|
test "book quality package owns semantic review profile policy" {
  assert_eq(review_profile_id(), "book_quality_ai_reviewer")
  assert_true(review_preferred_skills().contains("book-quality-ai-review"))
  let role = review_role_runtime_json().stringify()
  assert_true(role.contains("\"runtime_mode\":\"semantic-review\""))
  assert_true(role.contains("\"memory_scope\":\"book-quality\""))
  assert_true(role.contains(review_output_contract()))
  let jobs = review_moonclaw_jobs_json("codex-main").stringify()
  assert_true(jobs.contains("\"book_quality_ai_reviewer\""))
  assert_true(jobs.contains("\"review_book_semantic_quality\""))
  assert_true(jobs.contains("\"semantic-review\""))
  assert_true(jobs.contains("\"enable_tools\":true"))
  assert_true(jobs.contains("\"execution_target\":\"codex-main\""))
}

///|
test "book quality package owns external review packet contract" {
  let packet = BookQualityReviewPacket::{
    book_id: "coding",
    book_type: @policy.operational_type(),
    policy: @policy.operational(),
    workspace_root: "/tmp/coding",
    structural_score: 100,
    review_skill_path: "/tmp/review/BOOK_QUALITY_REVIEW_SKILL.md",
    context_pages: ["wiki/index.md"],
    prompt: "Review the book.",
    output_contract: review_output_contract(),
  }
  let external = review_external_proposal_spec(
    packet, "/tmp/results", "codex-main",
  )
  assert_true(
    external.notes.contains(
      "Do not inflate score for operational logs or scaffolding.",
    ),
  )
  assert_true(external.tags.contains(@policy.operational_type()))
  assert_true(external.request_text.contains("Workspace root: `/tmp/coding`"))
  assert_true(
    external.request_text.contains(
      "Result target after reconciliation: `/tmp/results/coding.md`",
    ),
  )
  assert_true(
    external.request_text.contains(@policy.markdown(@policy.operational())),
  )
  let metadata = external.metadata.stringify()
  assert_true(metadata.contains("\"disable_waiting_for_input\":true"))
  assert_true(metadata.contains("\"best_effort_on_missing_input\":true"))
  assert_true(metadata.contains("\"book_policy\":{"))
  assert_true(metadata.contains("\"book_loop_plan\":{"))
  assert_true(metadata.contains("\"book_internal_distance_plan\":["))
  assert_true(metadata.contains("\"read-policy\""))
  assert_true(metadata.contains("\"evaluate-health\""))
  assert_true(metadata.contains("\"information\""))
  assert_true(metadata.contains("\"recognition\""))
  assert_true(metadata.contains("\"decisiveness\""))
  assert_true(metadata.contains("\"operational-keeper\""))
  assert_true(metadata.contains("\"kind\":\"book_quality_ai_review\""))
  assert_true(metadata.contains("\"execution_mode\":\"acp\""))
  assert_true(metadata.contains("\"execution_target\":\"codex-main\""))
  assert_true(metadata.contains("\"profile_metadata\":{"))
  assert_true(metadata.contains("\"step_metadata\":{"))
  assert_true(metadata.contains("\"result_path\":\"/tmp/results/coding.md\""))
}

///|
test "book quality package builds external MoonClaw review packet" {
  let packet = BookQualityReviewPacket::{
    book_id: "coding",
    book_type: @policy.operational_type(),
    policy: @policy.operational(),
    workspace_root: "/tmp/coding",
    structural_score: 100,
    review_skill_path: "/tmp/review/BOOK_QUALITY_REVIEW_SKILL.md",
    context_pages: ["wiki/index.md"],
    prompt: "Review the book.",
    output_contract: review_output_contract(),
  }
  let external = review_external_proposal_spec(
    packet, "/tmp/results", "codex-main",
  )
  assert_eq(external.packet_id, "book-quality-ai-review-coding")
  assert_eq(external.profile, review_profile_id())
  assert_eq(external.output_contract, review_output_contract())
  assert_true(external.tags.contains("book-quality"))
  assert_true(
    external.skill_paths.contains("/tmp/review/BOOK_QUALITY_REVIEW_SKILL.md"),
  )
  assert_true(external.context_pages.contains("/tmp/coding/wiki/index.md"))
  let metadata = external.metadata.stringify()
  assert_true(metadata.contains("\"disable_waiting_for_input\":true"))
  assert_true(metadata.contains("\"best_effort_on_missing_input\":true"))
  assert_true(metadata.contains("\"book_policy\":{"))
  assert_true(metadata.contains("\"result_path\":\"/tmp/results/coding.md\""))
}

///|
test "book quality package owns review status section rendering" {
  let run = BookQualityReviewRun::{
    book_id: "book-table",
    packet_path: "packet.json",
    result_path: "result.md",
    proposal_id: None,
    run_id: Some("run-table"),
    status: review_run_queued_status(),
    summary: "table | summary",
    generated_at_ms: 1UL,
  }
  let row = review_run_display_row(
    run,
    book_quality_review_pending_result_state(),
  )
  let row_from_exists = review_run_display_row_for_result_exists(run, true)
  assert_eq(
    row_from_exists.result_state,
    book_quality_review_written_result_state(),
  )
  assert_eq(review_result_state_for_exists(false), "pending")
  let table = review_run_table_lines([row])
  assert_eq(table.length(), 2)
  assert_eq(table[0], book_quality_review_run_table_header())
  assert_eq(
    table[1],
    "|book-table|queued|pending|`run-table`|table \\| summary|",
  )
  let current = review_current_section([row])
  assert_eq(current[0], "## Current By Book")
  assert_true(current.join("\n").contains("|book-table|queued|pending|"))
  let history = review_historical_section([row])
  assert_true(history.join("\n").contains("## Historical Attempts"))
  assert_true(history.join("\n").contains("recovered failures"))
  assert_true(review_historical_section([]).is_empty())
}

///|
test "book quality package owns review ledger view current replacement" {
  let first_a = BookQualityReviewRun::{
    book_id: "book-a",
    packet_path: "a-1.json",
    result_path: "book-a.md",
    proposal_id: None,
    run_id: Some("run-a-1"),
    status: review_run_queued_status(),
    summary: "first a",
    generated_at_ms: 1UL,
  }
  let first_b = {
    ..first_a,
    book_id: "book-b",
    packet_path: "b-1.json",
    result_path: "book-b.md",
    run_id: Some("run-b-1"),
    summary: "first b",
    generated_at_ms: 2UL,
  }
  let latest_a = {
    ..first_a,
    packet_path: "a-2.json",
    run_id: Some("run-a-2"),
    status: review_run_written_status(),
    summary: "latest a",
    generated_at_ms: 3UL,
  }
  let view = book_quality_review_ledger_view(BookQualityReviewRunLedger::{
    runs: [first_a, first_b, latest_a],
  })
  assert_eq(view.current_runs.length(), 2)
  assert_eq(view.current_runs[0].book_id, "book-a")
  assert_true(view.current_runs[0].run_id == Some("run-a-2"))
  assert_eq(view.current_runs[1].book_id, "book-b")
  assert_true(view.current_runs[1].run_id == Some("run-b-1"))
}

///|
test "book quality package owns review run identity for view replacement" {
  let first = BookQualityReviewRun::{
    book_id: "book-a",
    packet_path: "packet-a.json",
    result_path: "book-a.md",
    proposal_id: Some("proposal-a"),
    run_id: Some("run-a"),
    status: review_run_written_status(),
    summary: "summary",
    generated_at_ms: 3UL,
  }
  let moved_packet = { ..first, packet_path: "packet-moved.json" }
  let changed_summary = { ..first, summary: "changed" }
  let changed_generation = { ..first, generated_at_ms: 4UL }
  let packet_only_view = book_quality_review_ledger_view(BookQualityReviewRunLedger::{
    runs: [first, moved_packet],
  })
  assert_eq(packet_only_view.current_runs.length(), 1)
  assert_true(
    packet_only_view.current_runs[0].packet_path == "packet-moved.json",
  )
  assert_true(packet_only_view.historical_runs.is_empty())
  let view = book_quality_review_ledger_view(BookQualityReviewRunLedger::{
    runs: [first, moved_packet, changed_summary, changed_generation],
  })
  assert_eq(view.current_runs.length(), 1)
  assert_true(view.current_runs[0].generated_at_ms == 4UL)
  assert_eq(view.historical_runs.length(), 3)
  assert_true(view.historical_runs.any(fn(run) { run.summary == "summary" }))
  assert_true(view.historical_runs.any(fn(run) { run.summary == "changed" }))
}

///|
test "book quality package owns review ledger view history accounting" {
  let old_a = BookQualityReviewRun::{
    book_id: "book-a",
    packet_path: "a-old.json",
    result_path: "book-a.md",
    proposal_id: Some("proposal-a-old"),
    run_id: Some("run-a-old"),
    status: review_run_orphaned_status(),
    summary: "old failure",
    generated_at_ms: 1UL,
  }
  let current_b = BookQualityReviewRun::{
    book_id: "book-b",
    packet_path: "b.json",
    result_path: "book-b.md",
    proposal_id: Some("proposal-b"),
    run_id: Some("run-b"),
    status: review_run_written_status(),
    summary: "current b",
    generated_at_ms: 2UL,
  }
  let current_a = {
    ..old_a,
    packet_path: "a-current.json",
    proposal_id: Some("proposal-a-current"),
    run_id: Some("run-a-current"),
    status: review_run_written_status(),
    summary: "current a",
    generated_at_ms: 3UL,
  }
  let ledger = BookQualityReviewRunLedger::{
    runs: [old_a, current_b, current_a],
  }
  let view = book_quality_review_ledger_view(ledger)
  assert_eq(view.current_runs.length(), 2)
  assert_eq(view.current_runs[0].book_id, "book-a")
  assert_true(view.current_runs[0].run_id == Some("run-a-current"))
  assert_eq(view.current_runs[1].book_id, "book-b")
  assert_eq(view.historical_runs.length(), 1)
  assert_true(view.historical_runs[0].run_id == Some("run-a-old"))
  let markdown = review_status_markdown(
    "runs.json",
    "results",
    0,
    ledger,
    view,
    [],
    [],
  )
  assert_true(markdown.contains("- historical problem attempts: `1`"))
}

///|
async test "book quality package owns review ledger append storage" {
  let root = "/tmp/moontown-book-quality-package-append-ledger-wbtest"
  let run_path = "\{root}/book-quality/ai-review-runs.json"
  let original = BookQualityReviewRun::{
    book_id: "book-a",
    packet_path: "\{root}/packet-old.json",
    result_path: "\{root}/result-old.md",
    proposal_id: Some("proposal-old"),
    run_id: Some("run-a"),
    status: review_run_dispatched_status(),
    summary: "old",
    generated_at_ms: 1UL,
  }
  let replacement = {
    ..original,
    packet_path: "\{root}/packet-new.json",
    result_path: "\{root}/result-new.md",
    summary: "new",
    generated_at_ms: 2UL,
  }
  let other = {
    ..original,
    book_id: "book-b",
    packet_path: "\{root}/packet-other.json",
    result_path: "\{root}/result-other.md",
    run_id: Some("run-b"),
    summary: "other",
  }
  ignore(run_path)
  let ledger = review_run_ledger_with_appended_run(
    review_run_ledger_with_appended_run(
      review_run_ledger_with_appended_run(empty_review_run_ledger(), original),
      other,
    ),
    replacement,
  )
  assert_eq(ledger.runs.length(), 2)
  assert_eq(ledger.runs[0].book_id, "book-b")
  assert_eq(ledger.runs[1].book_id, "book-a")
  assert_eq(ledger.runs[1].summary, "new")
}

///|
test "book quality package owns review ledger text parsing" {
  let run = BookQualityReviewRun::{
    book_id: "book-a",
    packet_path: "/tmp/packet.json",
    result_path: "/tmp/result.md",
    proposal_id: Some("proposal-a"),
    run_id: Some("run-a"),
    status: review_run_dispatched_status(),
    summary: "summary",
    generated_at_ms: 1UL,
  }
  let parsed = review_run_ledger_from_text(
    review_run_ledger_to_text(BookQualityReviewRunLedger::{ runs: [run] }),
  )
  assert_eq(parsed.runs.length(), 1)
  assert_eq(parsed.runs[0].book_id, "book-a")
  assert_eq(parsed.runs[0].summary, "summary")
}

///|
test "book quality package owns review ledger serializer roundtrip" {
  let run = BookQualityReviewRun::{
    book_id: "book-roundtrip",
    packet_path: "/tmp/packet.json",
    result_path: "/tmp/result.md",
    proposal_id: Some("proposal-roundtrip"),
    run_id: Some("run-roundtrip"),
    status: review_run_written_status(),
    summary: "roundtrip summary",
    generated_at_ms: 7UL,
  }
  let text = review_run_ledger_to_text(BookQualityReviewRunLedger::{
    runs: [run],
  })
  assert_true(text.contains("\"runs\""))
  assert_true(text.contains("\"book_id\": \"book-roundtrip\""))
  let parsed = review_run_ledger_from_text(text)
  assert_eq(parsed.runs.length(), 1)
  assert_eq(parsed.runs[0].book_id, "book-roundtrip")
  assert_eq(parsed.runs[0].summary, "roundtrip summary")
}

///|
test "book quality package owns review ledger parse fallback" {
  let malformed = review_run_ledger_from_text("{not valid json")
  assert_eq(malformed.runs.length(), 0)

  let wrong_schema = review_run_ledger_from_text("{\"runs\":\"not an array\"}")
  assert_eq(wrong_schema.runs.length(), 0)
}

///|
test "book quality package owns repair goal retirement policy" {
  let score = review_candidate_score_for_test("book-a", 40)
  assert_true(score_exists([score], "book-a"))
  assert_false(score_exists([score], "book-b"))
  assert_eq(
    repair_goal_retirement_decision_label(
      repair_goal_retirement_decision(
        repair_goal_id("book-a"),
        true,
        has_target_book=false,
        score_exists=false,
        repairable_book=false,
        semantic_score=None,
      ),
    ),
    "missing-target-book",
  )
  assert_eq(
    repair_goal_retirement_decision_label(
      repair_goal_retirement_decision(
        repair_goal_id("book-a"),
        true,
        has_target_book=true,
        score_exists=false,
        repairable_book=true,
        semantic_score=None,
      ),
    ),
    "missing-book-score",
  )
  assert_eq(
    repair_goal_retirement_decision_label(
      repair_goal_retirement_decision(
        repair_goal_id("book-a"),
        true,
        has_target_book=true,
        score_exists=true,
        repairable_book=false,
        semantic_score=None,
      ),
    ),
    "no-longer-repairable-book",
  )
  assert_eq(
    repair_goal_retirement_decision_label(
      repair_goal_retirement_decision(
        repair_goal_id("book-a"),
        true,
        has_target_book=true,
        score_exists=true,
        repairable_book=true,
        semantic_score=Some(semantic_ready_threshold()),
      ),
    ),
    "ready-semantic-review",
  )
  assert_false(
    repair_goal_retirement_decision_should_retire(
      repair_goal_retirement_decision(
        "ordinary-watch",
        true,
        has_target_book=true,
        score_exists=true,
        repairable_book=true,
        semantic_score=Some(semantic_ready_threshold()),
      ),
    ),
  )
}

///|
test "book quality package owns repair bridge summary wording" {
  let item = BookQualityRepairBridgeItem::{
    book_id: "research-robotics",
    book_type: @policy.research_type(),
    workspace_root: "/tmp/research-robotics",
    semantic_score: 44,
    semantic_grade: "weak",
    repair_owner: "moonbook",
    next_repair_task: "Improve evidence matrix.",
    review_result_path: "/tmp/result.md",
    book_review_path: "/tmp/reviews/book-quality-repair.md",
    standing_goal_id: repair_goal_id("research-robotics"),
    status: review_run_queued_status(),
    generated_at_ms: 1UL,
  }
  assert_eq(
    repair_bridge_summary([], [], []),
    "No weak AI semantic book-quality review needed repair bridging.",
  )
  assert_true(
    repair_bridge_summary([item], [], []).contains(
      "Queued 1 new weak AI semantic book-quality repair(s): research-robotics.",
    ),
  )
  assert_true(
    repair_bridge_summary([item], [], [item.standing_goal_id]).contains(
      "Refreshed 1 existing weak AI semantic book-quality repair(s): research-robotics.",
    ),
  )
  assert_true(
    repair_bridge_summary([], ["book-quality-repair-old"], []).contains(
      "Retired 1 stale repair goal(s): book-quality-repair-old.",
    ),
  )
}

///|
test "book quality package owns repair review page markdown" {
  let item = BookQualityRepairBridgeItem::{
    book_id: "research-robotics",
    book_type: @policy.research_type(),
    workspace_root: "/tmp/research-robotics",
    semantic_score: 41,
    semantic_grade: "weak",
    repair_owner: "moonbook",
    next_repair_task: "Build a source screen.",
    review_result_path: "/tmp/result.md",
    book_review_path: "/tmp/reviews/book-quality-repair.md",
    standing_goal_id: repair_goal_id("research-robotics"),
    status: review_run_queued_status(),
    generated_at_ms: 1UL,
  }
  let page = repair_review_page_markdown(
    item, "ai_quality_score: 41\nnext_repair_task: Build a source screen.\n",
  )
  assert_true(page.contains("# Book Quality Repair Queue"))
  assert_true(page.contains("- Book: `research-robotics`"))
  assert_true(
    page.contains(
      "- Standing repair goal: `book-quality-repair-research-robotics`",
    ),
  )
  assert_true(page.contains("Build a source screen."))
  assert_true(page.contains("```md\nai_quality_score: 41"))
  assert_true(page.contains("not accepted domain evidence"))
}

///|
test "book quality package owns review lifecycle contract" {
  assert_eq(
    review_run_status_bucket(review_run_dispatched_status()),
    "in-progress",
  )
  assert_true(review_run_in_progress_status(review_run_queued_status()))
  assert_true(review_run_terminal_status(review_run_written_status()))
  assert_true(review_run_problem_status(review_run_orphaned_status()))
  assert_true(
    review_result_satisfies_contract(
      "ai_quality_score: 88\nbook_role_fit: strong\n",
    ),
  )
  assert_false(
    review_result_satisfies_contract("book_role_fit: missing score\n"),
  )
  let run = BookQualityReviewRun::{
    book_id: "book-a",
    packet_path: "packet.json",
    result_path: "result.md",
    proposal_id: None,
    run_id: Some("run-a"),
    status: review_run_dispatched_status(),
    summary: "completed",
    generated_at_ms: 100UL,
  }
  assert_true(
    review_run_within_stale_window(run, 100UL + review_stale_after_ms() - 1UL),
  )
  assert_false(
    review_run_within_stale_window(run, 100UL + review_stale_after_ms()),
  )
  assert_true(
    review_run_active_by_observation(
      run,
      has_result=false,
      process_alive=false,
      now_ms=100UL + review_stale_after_ms() - 1UL,
    ),
  )
  assert_false(
    review_run_active_by_observation(
      run,
      has_result=false,
      process_alive=false,
      now_ms=100UL + review_stale_after_ms(),
    ),
  )
  assert_true(
    review_run_active_by_observation(
      run,
      has_result=false,
      process_alive=true,
      now_ms=100UL + review_stale_after_ms(),
    ),
  )
  assert_false(
    review_run_active_by_observation(
      run,
      has_result=true,
      process_alive=true,
      now_ms=100UL,
    ),
  )
  let corrected = corrected_terminal_review_run(run)
  assert_eq(corrected.status, review_run_written_status())
  let accepted = accepted_review_run(corrected, "run-a", now_ms=999UL)
  assert_eq(accepted.summary, harvested_review_summary("run-a"))
  assert_eq(accepted.generated_at_ms, 999UL)
  let accepted_result = accepted_review_run_reconcile_result(
    corrected,
    "run-a",
    now_ms=1000UL,
  )
  assert_true(accepted_result.written)
  assert_true(accepted_result.changed)
  assert_eq(accepted_result.run.status, review_run_written_status())
  assert_eq(accepted_result.run.summary, harvested_review_summary("run-a"))
  let orphaned = orphaned_review_run(run, "run-a", "", now_ms=1000UL)
  assert_eq(orphaned.status, review_run_orphaned_status())
  assert_eq(orphaned.generated_at_ms, 1000UL)
  assert_true(orphaned.summary.contains("stale"))
  assert_true(orphaned.summary.contains("no result artifact"))
  let orphaned_with_poll = orphaned_review_run(
    run,
    "run-a",
    "Provider stopped early.",
    now_ms=1001UL,
  )
  assert_true(orphaned_with_poll.summary.contains("Provider stopped early."))
  assert_true(orphaned_with_poll.summary.contains("Marked orphaned"))
  let unchanged = unchanged_review_run_reconcile_result(run)
  assert_false(unchanged.written)
  assert_false(unchanged.changed)
  assert_eq(unchanged.run.status, review_run_dispatched_status())
  let existing = existing_result_review_run_reconcile_result(run)
  assert_false(existing.written)
  assert_true(existing.changed)
  assert_eq(existing.run.status, review_run_written_status())
}

///|
async test "book quality package counts active review runs" {
  let result_dir = "/tmp/moontown-book-quality-package-active-count-wbtest/results"
  let recent = BookQualityReviewRun::{
    book_id: "recent",
    packet_path: "packet-recent.json",
    result_path: "\{result_dir}/recent.md",
    proposal_id: None,
    run_id: Some("run-recent"),
    status: review_run_dispatched_status(),
    summary: "recent",
    generated_at_ms: 100UL,
  }
  let stale = {
    ..recent,
    book_id: "stale",
    result_path: "\{result_dir}/stale.md",
    generated_at_ms: 100UL,
  }
  let written = {
    ..recent,
    book_id: "written",
    result_path: "\{result_dir}/written.md",
    status: review_run_written_status(),
  }
  let observations = [
    BookQualityReviewRunObservation::{
      run: recent,
      has_result: false,
      process_alive: false,
    },
    BookQualityReviewRunObservation::{
      run: stale,
      has_result: false,
      process_alive: false,
    },
    BookQualityReviewRunObservation::{
      run: written,
      has_result: true,
      process_alive: false,
    },
  ]
  assert_eq(active_review_count_for_observations(observations, 200UL), 2)
  assert_eq(
    active_review_count_for_observations(
      observations,
      100UL + review_stale_after_ms(),
    ),
    0,
  )
}

///|
async test "book quality package marks stale review runs orphaned" {
  let run = BookQualityReviewRun::{
    book_id: "stale-review",
    packet_path: "packet.json",
    result_path: "result.md",
    proposal_id: Some("proposal-stale"),
    run_id: Some("run-stale-review-package-test"),
    status: review_run_dispatched_status(),
    summary: "started",
    generated_at_ms: 1UL,
  }
  let result = stale_review_run_reconcile_result_from_observation(
    run,
    process_alive=false,
    poll_summary="",
    now_ms=review_stale_after_ms() + 2UL,
  )
  assert_false(result.written)
  assert_true(result.changed)
  assert_eq(result.run.status, review_run_orphaned_status())
  assert_true(result.run.summary.contains("marked orphaned"))
}

///|
async test "book quality package owns public active boundary through internal check" {
  let root = "/tmp/moontown-book-quality-package-active-boundary-wbtest-\{@async.now().to_int()}"
  let result_dir = "\{root}/book-quality/ai-review-results"
  let run = BookQualityReviewRun::{
    book_id: "book-stale-window",
    packet_path: "packet.json",
    result_path: "result.md",
    proposal_id: None,
    run_id: Some("run-stale-window"),
    status: review_run_dispatched_status(),
    summary: "recent runner",
    generated_at_ms: 1_000UL,
  }
  assert_eq(result_dir, "\{root}/book-quality/ai-review-results")
  assert_true(
    review_run_active_by_observation(
      run,
      has_result=false,
      process_alive=false,
      now_ms=600_999UL,
    ),
  )
  assert_false(
    review_run_active_by_observation(
      run,
      has_result=false,
      process_alive=false,
      now_ms=601_000UL,
    ),
  )
}

///|
async test "book quality package preserves terminal failed attempt status" {
  let orphaned_result = reconcile_review_run_from_observation(
    BookQualityReviewRun::{
      book_id: "book-a",
      packet_path: "packet.json",
      result_path: "book-a.md",
      proposal_id: None,
      run_id: Some("run-a"),
      status: review_run_written_status(),
      summary: "Marked orphaned by Book Quality reconciliation because no result artifact was produced.",
      generated_at_ms: 1UL,
    },
    result_exists=true,
    process_alive=false,
    poll_summary="",
    now_ms=2UL,
  )
  assert_eq(orphaned_result.run.status, review_run_orphaned_status())
  let blocked_result = reconcile_review_run_from_observation(
    {
      ..orphaned_result.run,
      status: review_run_written_status(),
      summary: "MoonClaw AI review dispatch failed: permission denied",
    },
    result_exists=true,
    process_alive=false,
    poll_summary="",
    now_ms=3UL,
  )
  assert_eq(blocked_result.run.status, review_run_blocked_status())
  let active_result = reconcile_review_run_from_observation(
    {
      ..orphaned_result.run,
      status: review_run_dispatched_status(),
      summary: "imported and completed",
    },
    result_exists=true,
    process_alive=false,
    poll_summary="",
    now_ms=4UL,
  )
  assert_eq(active_result.run.status, review_run_written_status())
}

///|
async test "book quality package owns per-run reconciliation transitions" {
  let root = "/tmp/moontown-book-quality-package-reconcile-single-wbtest-\{@async.now().to_int()}"
  let queued = BookQualityReviewRun::{
    book_id: "book-stable",
    packet_path: "\{root}/packet.json",
    result_path: "\{root}/result.md",
    proposal_id: None,
    run_id: None,
    status: review_run_queued_status(),
    summary: "waiting for dispatch",
    generated_at_ms: 1UL,
  }
  let unchanged = reconcile_review_run_from_observation(
    queued,
    result_exists=false,
    process_alive=false,
    poll_summary="",
    now_ms=2UL,
  )
  assert_eq(unchanged.run.status, review_run_queued_status())
  assert_eq(unchanged.run.summary, "waiting for dispatch")
  assert_false(unchanged.written)
  assert_false(unchanged.changed)

  let accepted = reconcile_review_run_from_observation(
    BookQualityReviewRun::{
      book_id: "book-accepted",
      packet_path: "packet.json",
      result_path: "\{root}/accepted-results/book-accepted.md",
      proposal_id: Some("proposal-accepted"),
      run_id: Some("run-accepted"),
      status: review_run_dispatched_status(),
      summary: "dispatch summary",
      generated_at_ms: 1UL,
    },
    result_exists=false,
    result_content="ai_quality_score: 88\nbook_role_fit: strong\n",
    process_alive=false,
    poll_summary="done",
    now_ms=42UL,
  )
  assert_eq(accepted.run.status, review_run_written_status())
  assert_true(accepted.run.summary.contains("run-accepted"))
  assert_eq(accepted.run.generated_at_ms, 42UL)
  assert_true(accepted.written)
  assert_true(accepted.changed)
}

///|
async test "book quality package existing result transition is internal" {
  let run = BookQualityReviewRun::{
    book_id: "book-existing",
    packet_path: "packet.json",
    result_path: "book-existing.md",
    proposal_id: None,
    run_id: Some("run-existing"),
    status: review_run_dispatched_status(),
    summary: "imported and completed",
    generated_at_ms: 1UL,
  }
  let result = reconcile_review_run_from_observation(
    run,
    result_exists=true,
    process_alive=false,
    poll_summary="",
    now_ms=2UL,
  )
  assert_false(result.written)
  assert_true(result.changed)
  assert_eq(result.run.status, review_run_written_status())
}

///|
async test "book quality package writes accepted review results" {
  let result_dir = "/tmp/moontown-book-quality-package-accepted-result-wbtest/results"
  let run = BookQualityReviewRun::{
    book_id: "accepted-book",
    packet_path: "packet.json",
    result_path: "\{result_dir}/accepted-book.md",
    proposal_id: None,
    run_id: Some("run-accepted"),
    status: review_run_dispatched_status(),
    summary: "accepted",
    generated_at_ms: 1UL,
  }
  write_accepted_review_result(
    result_dir, run, "ai_quality_score: 91\nbook_role_fit: excellent\n",
  )
  let text = read_review_result_text(result_dir, "accepted-book")
  assert_true(text.contains("ai_quality_score: 91"))
  assert_true(text.contains("book_role_fit: excellent"))
  assert_eq(read_review_result_text(result_dir, "missing-book"), "")
}

///|
test "book quality package owns review markdown row formatting" {
  let run = BookQualityReviewRun::{
    book_id: "book-row",
    packet_path: "packet.json",
    result_path: "result.md",
    proposal_id: None,
    run_id: Some("run-row"),
    status: review_run_queued_status(),
    summary: "row | summary\nnext",
    generated_at_ms: 1UL,
  }
  assert_eq(
    book_quality_review_run_table_header(),
    "| Book | Status | Result | Run | Summary |\n| --- | --- | --- | --- | --- |",
  )
  assert_eq(book_quality_review_pending_result_state(), "pending")
  assert_eq(book_quality_review_written_result_state(), "written")
  assert_eq(
    book_quality_review_run_markdown_row(
      run,
      book_quality_review_pending_result_state(),
    ),
    "|book-row|queued|pending|`run-row`|row \\| summary next|",
  )
  let ledger = BookQualityReviewRunLedger::{ runs: [run] }
  let view = BookQualityReviewLedgerView::{
    current_runs: [run],
    historical_runs: [run],
  }
  let summary = review_status_summary_lines(
    "/tmp/runs.json", "/tmp/results", 1, ledger, view,
  ).join("\n")
  assert_true(summary.contains("- active reviews: `1`"))
  assert_true(summary.contains("- current books: `1`"))
  assert_true(summary.contains("- historical attempts: `1`"))
}

///|
test "book quality package owns review dispatch message policy" {
  assert_eq(
    active_review_dispatch_message(2),
    "AI semantic book-quality review already active; daemon will not dispatch a duplicate. active=2",
  )
  assert_eq(
    no_pending_review_dispatch_message("/tmp/results"),
    "No pending AI semantic book-quality review remains. Results are stored under /tmp/results.",
  )
}
