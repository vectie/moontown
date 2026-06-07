///|
test "semantic quality gates readiness and next action" {
  assert_true(semantic_quality_allows_ready(Some(82)))
  assert_true(!semantic_quality_allows_ready(Some(64)))
  let action = next_book_quality_action(
    book_quality_research_type(),
    [],
    100,
    Some(64),
  )
  assert_true(action.contains("AI semantic review"))
}

///|
test "book quality policy separates semantic structural and type actions" {
  assert_true(semantic_review_requires_repair(Some(79)))
  assert_true(!semantic_review_requires_repair(Some(80)))
  assert_true(!semantic_review_requires_repair(None))
  assert_true(structural_quality_is_stable([], 90))
  assert_true(!structural_quality_is_stable(["missing wiki/index.md"], 100))
  assert_eq(
    next_book_quality_action(book_quality_research_type(), [], 95, None),
    stable_book_quality_action(),
  )
  assert_eq(
    book_type_repair_action(book_quality_course_type()),
    "Run course projection repair: enforce course identity, lesson progression, exercises, checkpoints, and beginner usability.",
  )
  assert_true(
    book_type_repair_action(book_quality_planbook_type()).contains(
      "code-plan skill",
    ),
  )
  assert_true(
    book_type_repair_action(book_quality_cookbook_type()).contains(
      "book-quality audit",
    ),
  )
  assert_true(
    book_type_repair_action(book_quality_civic_type()).contains(
      "protocol-native loop",
    ),
  )
  assert_true(
    book_type_repair_action(book_quality_operational_type()).contains(
      "keeper review",
    ),
  )
  assert_true(
    book_type_repair_action("unknown-book").contains("typed MoonBook workspace"),
  )
}

///|
test "book quality policy specs keep repair actions and source policy together" {
  let custom = book_quality_policy_spec(
    "custom-book",
    "custom repair",
    book_quality_web_first_policy(),
  )
  assert_eq(custom.book_type, "custom-book")
  assert_eq(custom.repair_action, "custom repair")
  assert_eq(custom.source_policy, book_quality_web_first_policy())
  let book_first = book_first_quality_policy_spec("custom-book", "repair")
  assert_eq(book_first.source_policy, book_quality_book_first_policy())
  match book_quality_policy_spec_for_type(book_quality_research_type()) {
    Some(spec) => {
      assert_eq(spec.source_policy, book_quality_web_first_policy())
      assert_true(spec.repair_action.contains("research quality review"))
    }
    None => fail("expected research policy spec")
  }
  match book_quality_policy_spec_for_type(book_quality_civic_type()) {
    Some(spec) => {
      assert_eq(spec.source_policy, book_quality_book_first_policy())
      assert_true(spec.repair_action.contains("protocol-native loop"))
    }
    None => fail("expected civic policy spec")
  }
  assert_true(book_quality_policy_spec_for_type("unknown-book") is None)
  assert_eq(
    book_quality_source_policy_for_type("unknown-book"),
    book_quality_book_first_policy(),
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
  assert_eq(book_quality_type(course), book_quality_course_type())
  let plan = book_quality_catalog_entry(
    id="plan-moontown-quality",
    name="Research Plan",
    purpose="plan implementation",
    workspace_root="/tmp/plan",
    tags=["research"],
  )
  assert_eq(book_quality_type(plan), book_quality_planbook_type())
  let civic = book_quality_catalog_entry(
    id="wenyu-policy-hall",
    name="Policy Hall",
    purpose="civic service protocol",
    workspace_root="/tmp/civic",
    tags=[],
  )
  assert_eq(book_quality_type(civic), book_quality_civic_type())
  let operational = book_quality_catalog_entry(
    id="finance",
    name="Finance",
    purpose="daily finance operations",
    workspace_root="/tmp/finance",
    tags=[],
  )
  assert_eq(book_quality_type(operational), book_quality_operational_type())
}

///|
test "book quality review context specs provide typed pages and safe fallback" {
  let custom_spec = book_quality_context_spec("custom-book", ["middle.md"])
  assert_eq(custom_spec.book_type, "custom-book")
  assert_eq(
    custom_spec.pages.join("|"),
    [
      book_quality_wiki_index_path(),
      "middle.md",
      book_quality_generated_site_path(),
    ].join("|"),
  )
  assert_eq(
    book_quality_reviewable_types().join("|"),
    [
      book_quality_research_type(),
      book_quality_course_type(),
      book_quality_planbook_type(),
      book_quality_cookbook_type(),
      book_quality_civic_type(),
      book_quality_operational_type(),
    ].join("|"),
  )
  let research_pages = book_quality_context_pages_for_type(
    book_quality_research_type(),
  )
  assert_true(research_pages.contains("raw/bootstrap/deep-report.md"))
  assert_true(research_pages.contains("raw/bootstrap/evidence-matrix.md"))
  let civic_pages = book_quality_context_pages_for_type(
    book_quality_civic_type(),
  )
  assert_true(
    civic_pages.contains("raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md"),
  )
  assert_true(civic_pages.contains("wiki/ledgers/exchange-ledger.md"))
  assert_eq(
    book_quality_context_pages_for_type("unknown-book").join("|"),
    [book_quality_wiki_index_path(), book_quality_projection_state_path()].join(
      "|",
    ),
  )
}
