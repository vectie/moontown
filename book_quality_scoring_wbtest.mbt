///|
test "AI quality parser reads semantic review score" {
  let score = parse_ai_quality_score(
    "ai_quality_score: 82\nai_quality_grade: strong\n",
  )
  assert_true(score == Some(82))
}

///|
test "AI quality parser reads concrete repair task" {
  let task = book_quality_semantic_repair_task(
    "ai_quality_score: 42\nnext_repair_task: Create a source screen and revise the projection.\n",
  )
  assert_true(task == Some("Create a source screen and revise the projection."))
}

///|
test "book quality structural assessment caps gapped scores below excellent" {
  let clean = assess_structural_quality(120, [])
  assert_eq(clean.score, 100)
  assert_eq(clean.grade, "world-class")
  assert_true(clean.ready_without_semantic)
  let gapped = assess_structural_quality(100, ["missing wiki/index.md"])
  assert_eq(gapped.score, 89)
  assert_eq(gapped.grade, "strong")
  assert_false(gapped.ready_without_semantic)
  let weak = assess_structural_quality(-5, [])
  assert_eq(weak.score, 0)
  assert_eq(weak.grade, "not-managed")
  assert_false(weak.ready_without_semantic)
}

///|
test "book quality semantic assessment separates status and readiness" {
  let pending = semantic_quality_assessment(None)
  assert_true(pending.score is None)
  assert_eq(pending.grade, "pending-ai-review")
  assert_eq(pending.status, "pending-ai-review")
  assert_true(pending.allows_ready)
  let weak = semantic_quality_assessment(Some(79))
  assert_true(weak.score is Some(79))
  assert_eq(weak.grade, "usable")
  assert_eq(weak.status, "ai-reviewed")
  assert_false(weak.allows_ready)
  let strong = semantic_quality_assessment(Some(80))
  assert_true(strong.score is Some(80))
  assert_eq(strong.grade, "strong")
  assert_eq(strong.status, "ai-reviewed")
  assert_true(strong.allows_ready)
}

///|
test "book quality required path constructor keeps scoring contract explicit" {
  let path = book_quality_required_path(book_quality_wiki_index_path(), 7)
  assert_eq(path.relative, book_quality_wiki_index_path())
  assert_eq(path.points, 7)
  assert_eq(book_quality_wiki_index_path(), "wiki/index.md")
  assert_eq(book_quality_projection_state_path(), "book/moonbook-ui-state.json")
  assert_eq(
    book_quality_generated_site_path(),
    "book/site/generated/index.html",
  )
  assert_eq(
    book_quality_workspace_path("/tmp/book", book_quality_wiki_index_path()),
    "/tmp/book/wiki/index.md",
  )
}

///|
async test "book quality required path scoring reports strengths and gaps" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-required-paths",
  )
  write_text_file("\{root}/present.md", "# Present\n")
  let strengths : Array[String] = []
  let gaps : Array[String] = []
  let score = required_paths_score(
    root,
    [
      { relative: "present.md", points: 7 },
      { relative: "missing.md", points: 5 },
    ],
    strengths,
    gaps,
  )
  assert_eq(score, 7)
  assert_true(strengths.contains("has `present.md`"))
  assert_true(gaps.contains("missing `missing.md`"))
}

///|
async test "book quality score draft centralizes workspace setup" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-score-draft",
  )
  write_text_file(
    book_quality_workspace_path(root, book_quality_wiki_index_path()),
    "# Index\n",
  )
  write_text_file(
    book_quality_workspace_path(root, book_quality_projection_state_path()),
    "{}\n",
  )
  let entry = book_quality_catalog_entry(
    id="draft-book",
    name="Draft Book",
    purpose="validate score draft setup",
    workspace_root=root,
    tags=[],
  )
  let draft = new_book_quality_score_draft(entry)
  assert_eq(draft.root, root)
  assert_eq(draft.base_score, 28)
  assert_true(draft.strengths.contains("workspace exists"))
  assert_true(draft.strengths.contains("wiki index exists"))
  assert_true(draft.strengths.contains("MoonBook projection state exists"))
  assert_true(draft.gaps.is_empty())
}

///|
test "research book required paths expose scoring contract as data" {
  assert_required_path_contract(research_book_required_paths(), 8, [
    { relative: "raw/bootstrap/deep-report.md", points: 12 },
    { relative: book_quality_generated_site_path(), points: 6 },
  ])
}

///|
test "course book required paths expose scoring contract as data" {
  assert_required_path_contract(course_book_required_paths(), 8, [
    { relative: "raw/bootstrap/COURSE_CONTRACT.md", points: 12 },
    { relative: "wiki/course/beginner-course.md", points: 16 },
    { relative: "skills/course-builder/SKILL.md", points: 12 },
  ])
}

///|
test "planbook required paths expose scoring contract as data" {
  assert_required_path_contract(planbook_required_paths(), 12, [
    { relative: "raw/bootstrap/PLANBOOK_CONTRACT.md", points: 14 },
    { relative: "plans/2026-05-29-book-quality-upgrade/plan.md", points: 16 },
    { relative: "skills/code-plan/SKILL.md", points: 12 },
  ])
}

///|
test "cookbook required paths expose scoring contract as data" {
  assert_required_path_contract(cookbook_required_paths(), 10, [
    { relative: "raw/bootstrap/COOKBOOK_CONTRACT.md", points: 14 },
    { relative: "wiki/definitions/stable-state.md", points: 16 },
    { relative: "schemas/stable-state-manifest.schema.md", points: 8 },
  ])
}

///|
test "operational book required paths expose scoring contract as data" {
  assert_required_path_contract(operational_book_required_paths(), 5, [
    { relative: "raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md", points: 18 },
    { relative: "wiki/operations/review-policy.md", points: 16 },
    { relative: "skills/operational-keeper/SKILL.md", points: 16 },
  ])
}

///|
test "civic book base required paths expose scoring contract as data" {
  assert_required_path_contract(civic_book_base_required_paths(), 5, [
    { relative: "raw/bootstrap/CIVIC_SERVICE_CONTRACT.md", points: 12 },
    { relative: "raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md", points: 12 },
    { relative: "moonclaw.jobs.json", points: 10 },
  ])
}

///|
test "civic service workspace required paths include ledger and skill contract" {
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  assert_required_path_contract(
    civic_service_workspace_required_paths(service),
    4,
    [
      { relative: "wiki/ledgers/service-ledger.md", points: 5 },
      { relative: "wiki/history/service-history.md", points: 5 },
      { relative: service.skill_path, points: 10 },
    ],
  )
}

///|
async test "civic service definition scorer rewards typed pages ledgers skill and result" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-civic-service-score",
  )
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  seed_complete_civic_service_workspace(root, service)
  let strengths : Array[String] = []
  let gaps : Array[String] = []
  let score = score_civic_service_definition(root, service, strengths, gaps)
  assert_eq(score, 63)
  assert_true(strengths.contains("latest civic service result exists"))
  assert_true(gaps.is_empty())
}
