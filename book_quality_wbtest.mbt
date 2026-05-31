///|
async test "planbook bootstrap creates durable plan workspace and status" {
  let root = "/tmp/moontown-planbook-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let catalog_path = "\{root}/moonbooks.json"
  let workspace_root = "\{root}/books/plan-moontown-quality"
  let message = bootstrap_moontown_planbook(
    book_catalog_path=catalog_path,
    workspace_root~,
  )
  assert_true(message.contains("Bootstrapped planbook"))
  assert_true(@fs.exists("\{workspace_root}/wiki/index.md"))
  assert_true(
    @fs.exists(
      "\{workspace_root}/plans/2026-05-29-book-quality-upgrade/plan.md",
    ),
  )
  assert_true(
    @fs.exists(
      "\{workspace_root}/plans/2026-05-31-editor-mode-real-pipeline/plan.md",
    ),
  )
  assert_true(@fs.exists("\{workspace_root}/skills/code-plan/SKILL.md"))
  let status = render_moontown_planbook_status(workspace_root~)
  assert_true(status.contains("Ready: `true`"))
  assert_true(status.contains("Missing required: `0`"))
}

///|
test "AI quality parser reads semantic review score" {
  let score = parse_ai_quality_score(
    "ai_quality_score: 82\nai_quality_grade: strong\n",
  )
  assert_true(score == Some(82))
}

///|
async test "course bootstrap creates course-shaped MoonBook workspace" {
  let root = "/tmp/moontown-course-book-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let catalog_path = "\{root}/moonbooks.json"
  let workspace_root = "\{root}/books/course-wenyu-game-design"
  let source_workspace_root = "\{root}/source"
  write_text_file(
    "\{source_workspace_root}/raw/bootstrap/deep-report.md",
    "# Beginner Course\n\n## Lesson 1\n\nStart from map reading, then build one tile.",
  )
  let message = bootstrap_wenyu_game_design_course_book(
    book_catalog_path=catalog_path,
    workspace_root~,
    source_workspace_root~,
  )
  assert_true(message.contains("Bootstrapped course book"))
  assert_true(@fs.exists("\{workspace_root}/wiki/course/beginner-course.md"))
  assert_true(@fs.exists("\{workspace_root}/wiki/course/exercises.md"))
  assert_true(@fs.exists("\{workspace_root}/skills/course-builder/SKILL.md"))
  let status = render_wenyu_game_design_course_status(workspace_root~)
  assert_true(status.contains("Ready: `true`"))
  assert_true(status.contains("Missing required: `0`"))
}

///|
async test "book doctor writes structural audit and AI review packets" {
  let root = "/tmp/moontown-book-quality-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let catalog_path = "\{root}/moonbooks.json"
  let coding_root = "\{root}/books/coding"
  let civic_root = "\{root}/books/wenyu-policy-hall"
  let catalog = [
    @moonbook.BookCatalogEntry::new(
      id="coding",
      name="Coding",
      purpose="coding operations",
      workspace_root=coding_root,
      tags=["operational"],
    ),
    @moonbook.BookCatalogEntry::new(
      id="wenyu-policy-hall",
      name="Policy Hall",
      purpose="policy service protocol",
      workspace_root=civic_root,
      tags=["civic-service"],
    ),
  ]
  @moonbook.save_catalog_file(catalog_path, catalog)
  let audit_path = "\{root}/book-quality/audit.json"
  let doctor = write_book_quality_audit(
    book_catalog_path=catalog_path,
    audit_path~,
  )
  assert_true(
    doctor.contains("Wrote book management audit for 2 registered book"),
  )
  assert_true(@fs.exists(audit_path))
  assert_true(@fs.exists("\{root}/book-quality/audit.md"))
  assert_true(@fs.exists("\{coding_root}/wiki/operations/review-policy.md"))
  let audit = render_book_quality(book_catalog_path=catalog_path)
  assert_true(
    audit.contains(
      "|coding|operational-book|100 / world-class|pending|pending-ai-review|true|",
    ),
  )
  assert_true(
    audit.contains(
      "|wenyu-policy-hall|civic-protocol-support|0 / not-managed|pending|pending-ai-review|false|",
    ),
  )
  let review_dir = "\{root}/book-quality/ai-review-packets"
  let packets = write_book_quality_review_packets(
    book_catalog_path=catalog_path,
    review_dir~,
  )
  assert_true(packets.contains("AI quality review packet"))
  assert_true(@fs.exists("\{review_dir}/BOOK_QUALITY_REVIEW_SKILL.md"))
  assert_true(@fs.exists("\{review_dir}/coding.json"))
  assert_true(@fs.exists("\{review_dir}/wenyu-policy-hall.json"))
  let skill = read_text_or_empty("\{review_dir}/BOOK_QUALITY_REVIEW_SKILL.md")
  assert_true(
    skill.contains(
      "Do not score a book as world-class just because files exist",
    ),
  )
}
