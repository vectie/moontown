///|
test "semantic quality gates readiness and next action" {
  assert_true(@book_quality.semantic_quality_allows_ready(Some(82)))
  assert_true(!@book_quality.semantic_quality_allows_ready(Some(64)))
  let action = @book_quality.next_action(
    @policy.research_type(),
    [],
    100,
    Some(64),
  )
  assert_true(action.contains("AI semantic review"))
  let specific_action = @book_quality.next_action(
    @policy.research_type(),
    [],
    100,
    Some(64),
    semantic_repair_task=Some(
      "Create an evidence matrix from verified sources.",
    ),
  )
  assert_eq(
    specific_action, "AI semantic review repair: Create an evidence matrix from verified sources.",
  )
}

///|
test "book quality policy separates semantic structural and type actions" {
  assert_true(@book_quality.semantic_review_requires_repair(Some(79)))
  assert_true(!@book_quality.semantic_review_requires_repair(Some(80)))
  assert_true(!@book_quality.semantic_review_requires_repair(None))
  assert_true(@book_quality.structural_quality_is_stable([], 90))
  assert_true(
    !@book_quality.structural_quality_is_stable(["missing wiki/index.md"], 100),
  )
  assert_eq(
    @book_quality.next_action(@policy.research_type(), [], 95, None),
    @book_quality.stable_action(),
  )
  assert_eq(
    @book_quality.repair_action_for_type(@policy.course_type()),
    "Run course projection repair: enforce course identity, lesson progression, exercises, checkpoints, and beginner usability.",
  )
  assert_true(
    @book_quality.repair_action_for_type(@policy.planbook_type()).contains(
      "code-plan skill",
    ),
  )
  assert_true(
    @book_quality.repair_action_for_type(@policy.cookbook_type()).contains(
      "book-quality audit",
    ),
  )
  assert_true(
    @book_quality.repair_action_for_type(@policy.civic_type()).contains(
      "protocol-native loop",
    ),
  )
  assert_true(
    @book_quality.repair_action_for_type(@policy.operational_type()).contains(
      "keeper review",
    ),
  )
  assert_true(
    @book_quality.repair_action_for_type("unknown-book").contains(
      "typed MoonBook workspace",
    ),
  )
}

///|
test "book quality policy specs keep repair actions and source policy together" {
  match @book_quality.policy_spec_for_type(@policy.research_type()) {
    Some(spec) => {
      assert_eq(spec.profile.source_policy, @policy.web_first_policy())
      assert_true(spec.repair_action.contains("research quality review"))
      assert_true(@policy.has_skill(spec.profile.policy, "source-diarize"))
      assert_true(@policy.tend_skills(spec.profile.policy).length() > 0)
    }
    None => fail("expected research policy spec")
  }
  match @book_quality.policy_spec_for_type(@policy.civic_type()) {
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
  assert_true(@book_quality.policy_spec_for_type("unknown-book") is None)
  assert_eq(
    @book_quality.source_policy_for_type("unknown-book"),
    @policy.book_first_policy(),
  )
  assert_true(
    @policy.has_skill(
      @book_quality.policy_for_type("unknown-book"),
      "workspace-bootstrap",
    ),
  )
}

///|
test "book quality type classification preserves role precedence" {
  let course = book_quality_catalog_entry(
    id="course-wenyu-game-design",
    name="Wenyu Game Design Course",
    purpose="teach tile-map design",
    workspace_root="/tmp/course",
    tags=["research"],
  )
  assert_eq(
    @book_quality.catalog_entry_type(course.id, course.name, course.tags),
    @policy.course_type(),
  )
  let plan = book_quality_catalog_entry(
    id="plan-moontown-quality",
    name="Research Plan",
    purpose="plan implementation",
    workspace_root="/tmp/plan",
    tags=["research"],
  )
  assert_eq(
    @book_quality.catalog_entry_type(plan.id, plan.name, plan.tags),
    @policy.planbook_type(),
  )
  let civic = book_quality_catalog_entry(
    id="wenyu-policy-hall",
    name="Policy Hall",
    purpose="civic service protocol",
    workspace_root="/tmp/civic",
    tags=[],
  )
  assert_eq(
    @book_quality.catalog_entry_type(civic.id, civic.name, civic.tags),
    @policy.civic_type(),
  )
  let operational = book_quality_catalog_entry(
    id="finance",
    name="Finance",
    purpose="daily finance operations",
    workspace_root="/tmp/finance",
    tags=[],
  )
  assert_eq(
    @book_quality.catalog_entry_type(
      operational.id,
      operational.name,
      operational.tags,
    ),
    @policy.operational_type(),
  )
}

///|
test "book quality active catalog filter excludes only archive and smoke artifacts" {
  let contest = book_quality_catalog_entry(
    id="wenyu-contest-express",
    name="Contest Express",
    purpose="contest service protocol",
    workspace_root="/tmp/contest",
    tags=["civic-service"],
  )
  assert_true(
    @book_quality.catalog_entry_active(
      contest.id,
      contest.name,
      contest.purpose,
      contest.tags,
    ),
  )
  let smoke = book_quality_catalog_entry(
    id="research-codex-pdf-watch-smoke-20260602",
    name="Codex PDF Watch Smoke",
    purpose="Smoke test PDF Evidence Watch publish handoff.",
    workspace_root="/tmp/smoke",
    tags=["research"],
  )
  assert_false(
    @book_quality.catalog_entry_active(
      smoke.id,
      smoke.name,
      smoke.purpose,
      smoke.tags,
    ),
  )
  let archived = book_quality_catalog_entry(
    id="research-old",
    name="Old Research",
    purpose="Archived by operator.",
    workspace_root="/tmp/old",
    tags=["research", "archived"],
  )
  assert_false(
    @book_quality.catalog_entry_active(
      archived.id,
      archived.name,
      archived.purpose,
      archived.tags,
    ),
  )
}

///|
test "book quality review context specs provide typed pages and safe fallback" {
  assert_eq(
    @policy.reviewable_types().join("|"),
    [
      @policy.research_type(),
      @policy.course_type(),
      @policy.planbook_type(),
      @policy.cookbook_type(),
      @policy.civic_type(),
      @policy.operational_type(),
    ].join("|"),
  )
  let research_pages = @book_quality.context_pages_for_type(
    @policy.research_type(),
  )
  assert_true(research_pages.contains("raw/bootstrap/deep-report.md"))
  assert_true(research_pages.contains("raw/bootstrap/evidence-matrix.md"))
  let civic_pages = @book_quality.context_pages_for_type(@policy.civic_type())
  assert_true(
    civic_pages.contains("raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md"),
  )
  assert_true(civic_pages.contains("wiki/ledgers/exchange-ledger.md"))
  assert_eq(
    @book_quality.context_pages_for_type("unknown-book").join("|"),
    [@book_quality.wiki_index_path(), @book_quality.projection_state_path()].join(
      "|",
    ),
  )
}
