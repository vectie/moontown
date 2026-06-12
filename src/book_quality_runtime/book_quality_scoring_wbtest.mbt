///|
test "AI quality parser reads semantic review score" {
  let score = @book_quality.parse_ai_quality_score(
    "ai_quality_score: 82\nai_quality_grade: strong\n",
  )
  assert_true(score == Some(82))
}

///|
test "AI quality parser reads concrete repair task" {
  let task = @book_quality.semantic_repair_task_from_review_text(
    "ai_quality_score: 42\nnext_repair_task: Create a source screen and revise the projection.\n",
  )
  assert_true(task == Some("Create a source screen and revise the projection."))
}

///|
test "book quality structural assessment caps gapped scores below excellent" {
  let clean = @book_quality.assess_structural_quality(120, [])
  assert_eq(clean.score, 100)
  assert_eq(clean.grade, "world-class")
  assert_true(clean.ready_without_semantic)
  let gapped = @book_quality.assess_structural_quality(100, [
    "missing wiki/index.md",
  ])
  assert_eq(gapped.score, 89)
  assert_eq(gapped.grade, "strong")
  assert_false(gapped.ready_without_semantic)
  let weak = @book_quality.assess_structural_quality(-5, [])
  assert_eq(weak.score, 0)
  assert_eq(weak.grade, "not-managed")
  assert_false(weak.ready_without_semantic)
}

///|
test "book quality semantic assessment separates status and readiness" {
  let pending = @book_quality.semantic_quality_assessment(None)
  assert_true(pending.score is None)
  assert_eq(pending.grade, "pending-ai-review")
  assert_eq(pending.status, "pending-ai-review")
  assert_true(pending.allows_ready)
  let weak = @book_quality.semantic_quality_assessment(Some(79))
  assert_true(weak.score is Some(79))
  assert_eq(weak.grade, "usable")
  assert_eq(weak.status, "ai-reviewed")
  assert_false(weak.allows_ready)
  let strong = @book_quality.semantic_quality_assessment(Some(80))
  assert_true(strong.score is Some(80))
  assert_eq(strong.grade, "strong")
  assert_eq(strong.status, "ai-reviewed")
  assert_true(strong.allows_ready)
}

///|
test "book quality required path constructor keeps scoring contract explicit" {
  let path = @book_quality.required_path(@book_quality.wiki_index_path(), 7)
  assert_eq(path.relative, @book_quality.wiki_index_path())
  assert_eq(path.points, 7)
  assert_eq(@book_quality.wiki_index_path(), "wiki/index.md")
  assert_eq(
    @book_quality.projection_state_path(),
    "book/moonbook-ui-state.json",
  )
  assert_eq(
    @book_quality.generated_site_path(),
    @policy.default_generated_site_projection_path(),
  )
  assert_eq(
    @book_quality.workspace_path("/tmp/book", @book_quality.wiki_index_path()),
    "/tmp/book/wiki/index.md",
  )
}

///|
async test "book quality package scorer reports general strengths and gaps" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-general-score",
  )
  @support.write_text_file(
    @book_quality.workspace_path(root, @book_quality.wiki_index_path()),
    "# Index\n",
  )
  @support.write_text_file(
    @book_quality.workspace_path(root, @book_quality.projection_state_path()),
    "{}\n",
  )
  let entry = book_quality_catalog_entry(
    id="draft-book",
    name="Draft Book",
    purpose="validate package scoring setup",
    workspace_root=root,
    tags=[],
  )
  let score = @book_quality.score_book(
    entry,
    @book_quality.default_review_result_dir(),
  )
  assert_eq(score.book_type, @book_quality.general_type())
  assert_eq(score.structural_score, 63)
  assert_true(score.strengths.contains("workspace exists"))
  assert_true(score.strengths.contains("wiki index exists"))
  assert_true(score.strengths.contains("MoonBook projection state exists"))
  assert_true(score.strengths.contains("has `wiki/index.md`"))
  assert_true(score.strengths.contains("has `book/moonbook-ui-state.json`"))
  assert_false(score.gaps.is_empty())
  assert_true(
    score.gaps.any(fn(gap) { gap.contains("policy missing required file") }),
  )
  assert_false(score.ready)
}

///|
async test "book quality package scorer reports missing general projection" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-general-missing-projection",
  )
  @support.write_text_file(
    @book_quality.workspace_path(root, @book_quality.wiki_index_path()),
    "# Index\n",
  )
  let entry = book_quality_catalog_entry(
    id="general-book",
    name="General Book",
    purpose="validate missing projection scoring",
    workspace_root=root,
    tags=[],
  )
  let score = @book_quality.score_book(
    entry,
    @book_quality.default_review_result_dir(),
  )
  assert_eq(score.book_type, @book_quality.general_type())
  assert_true(score.gaps.contains("missing `book/moonbook-ui-state.json`"))
  assert_true(score.gaps.contains("missing book/moonbook-ui-state.json"))
  assert_false(score.ready)
}

///|
test "research book required paths expose scoring contract as data" {
  assert_required_path_contract(@book_quality.research_required_paths(), 8, [
    { relative: "raw/bootstrap/deep-report.md", points: 12 },
    { relative: @book_quality.generated_site_path(), points: 6 },
  ])
}

///|
test "course book required paths expose scoring contract as data" {
  assert_required_path_contract(@book_quality.course_required_paths(), 8, [
    { relative: "raw/bootstrap/COURSE_CONTRACT.md", points: 12 },
    { relative: "wiki/course/beginner-course.md", points: 16 },
    { relative: "skills/course-builder/SKILL.md", points: 12 },
  ])
}

///|
test "planbook required paths expose scoring contract as data" {
  assert_required_path_contract(@book_quality.planbook_required_paths(), 12, [
    { relative: "raw/bootstrap/PLANBOOK_CONTRACT.md", points: 14 },
    { relative: "plans/2026-05-29-book-quality-upgrade/plan.md", points: 16 },
    { relative: "skills/code-plan/SKILL.md", points: 12 },
  ])
}

///|
test "cookbook required paths expose scoring contract as data" {
  assert_required_path_contract(@book_quality.cookbook_required_paths(), 10, [
    { relative: "raw/bootstrap/COOKBOOK_CONTRACT.md", points: 14 },
    { relative: "wiki/definitions/stable-state.md", points: 16 },
    { relative: "schemas/stable-state-manifest.schema.md", points: 8 },
  ])
}

///|
test "operational book required paths expose scoring contract as data" {
  assert_required_path_contract(@book_quality.operational_required_paths(), 5, [
    { relative: "raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md", points: 18 },
    { relative: "wiki/operations/review-policy.md", points: 16 },
    { relative: "skills/operational-keeper/SKILL.md", points: 16 },
  ])
}

///|
test "civic book base required paths expose scoring contract as data" {
  assert_required_path_contract(@book_quality.civic_base_required_paths(), 5, [
    { relative: "raw/bootstrap/CIVIC_SERVICE_CONTRACT.md", points: 12 },
    { relative: "raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md", points: 12 },
    { relative: "moonclaw.jobs.json", points: 10 },
  ])
}

///|
async test "book quality package scorer rewards complete civic service workspace" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-civic-service-score",
  )
  let service = @civic.wenyu_civic_service_for_book_id("wenyu-policy-hall").unwrap()
  seed_complete_civic_service_workspace(root, service)
  let entry = book_quality_catalog_entry(
    id="wenyu-policy-hall",
    name="Wenyu Policy Hall",
    purpose="Policy support module",
    workspace_root=root,
    tags=[],
  )
  let score = @book_quality.score_book(
    entry,
    @book_quality.default_review_result_dir(),
  )
  assert_eq(score.book_type, @book_quality.civic_type())
  assert_true(score.strengths.contains("latest civic service result exists"))
  assert_false(
    score.gaps.contains("no civic service definition matched this book"),
  )
  assert_true(score.structural_score >= 80)
}
