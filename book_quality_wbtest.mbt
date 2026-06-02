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
  assert_true(
    @fs.exists("\{workspace_root}/wiki/planning/operating-architecture.md"),
  )
  assert_true(
    @fs.exists("\{workspace_root}/wiki/history/daily-engineering-digest.md"),
  )
  let architecture = read_text_or_empty(
    "\{workspace_root}/wiki/planning/operating-architecture.md",
  )
  assert_true(architecture.contains("Buildings are protocol places"))
  assert_true(architecture.contains("Growth Contract"))
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
async test "book quality reconcile marks stale detached review orphaned" {
  let root = "/tmp/moontown-book-quality-orphan-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let result_dir = "\{root}/book-quality/ai-review-results"
  let run_path = "\{root}/book-quality/ai-review-runs.json"
  let run = BookQualityReviewRun::{
    book_id: "course-example",
    packet_path: "\{root}/book-quality/moonclaw-packets/course-example.json",
    result_path: "\{result_dir}/course-example.md",
    proposal_id: Some("proposal-stale"),
    run_id: Some("run-stale-book-quality-review"),
    status: "dispatched",
    summary: "started but never produced a result",
    generated_at_ms: 1UL,
  }
  write_text_file(
    run_path,
    BookQualityReviewRunLedger::{ runs: [run] }.to_json().stringify(indent=2),
  )
  let written = reconcile_book_quality_ai_review_results(result_dir~, run_path~)
  assert_eq(written, 0)
  let ledger = load_book_quality_review_run_ledger(run_path)
  assert_eq(ledger.runs.length(), 1)
  assert_eq(ledger.runs[0].status, "orphaned")
  assert_true(ledger.runs[0].summary.contains("Marked orphaned"))
  assert_true(!@fs.exists("\{result_dir}/course-example.md"))
}

///|
async test "book quality treats recent detached review as active until stale" {
  let root = "/tmp/moontown-book-quality-active-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let result_dir = "\{root}/book-quality/ai-review-results"
  let run = BookQualityReviewRun::{
    book_id: "course-example",
    packet_path: "\{root}/book-quality/moonclaw-packets/course-example.json",
    result_path: "\{result_dir}/course-example.md",
    proposal_id: Some("proposal-recent"),
    run_id: Some("run-recent-book-quality-review"),
    status: "dispatched",
    summary: "recent detached runner",
    generated_at_ms: 1_000UL,
  }
  assert_true(book_quality_review_run_active(run, result_dir, now=600_999UL))
  assert_true(!book_quality_review_run_active(run, result_dir, now=601_000UL))
}

///|
test "book quality terminal result preserves failed attempt status" {
  let orphaned = corrected_terminal_book_quality_review_run(BookQualityReviewRun::{
    book_id: "book-a",
    packet_path: "packet.json",
    result_path: "result.md",
    proposal_id: None,
    run_id: Some("run-a"),
    status: "written",
    summary: "Marked orphaned by Book Quality reconciliation because no result artifact was produced.",
    generated_at_ms: 1UL,
  })
  assert_eq(orphaned.status, "orphaned")
  let blocked = corrected_terminal_book_quality_review_run({
    ..orphaned,
    status: "written",
    summary: "MoonClaw AI review dispatch failed: permission denied",
  })
  assert_eq(blocked.status, "blocked")
  let active = corrected_terminal_book_quality_review_run({
    ..orphaned,
    status: "dispatched",
    summary: "imported and completed",
  })
  assert_eq(active.status, "written")
}

///|
async test "book quality status separates current success from historical failed attempts" {
  let root = "/tmp/moontown-book-quality-current-status-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let result_dir = "\{root}/book-quality/ai-review-results"
  let run_path = "\{root}/book-quality/ai-review-runs.json"
  let old_run = BookQualityReviewRun::{
    book_id: "wenyu-contest-express",
    packet_path: "\{root}/book-quality/moonclaw-packets/contest.json",
    result_path: "\{result_dir}/wenyu-contest-express.md",
    proposal_id: Some("proposal-old"),
    run_id: Some("run-old"),
    status: "orphaned",
    summary: "Marked orphaned by Book Quality reconciliation because no result artifact was produced.",
    generated_at_ms: 1UL,
  }
  let current_run = BookQualityReviewRun::{
    ..old_run,
    proposal_id: Some("proposal-current"),
    run_id: Some("run-current"),
    status: "written",
    summary: "Harvested MoonClaw AI semantic review result from run-current.",
    generated_at_ms: 2UL,
  }
  write_text_file(
    "\{result_dir}/wenyu-contest-express.md",
    "ai_quality_score: 82\nbook_role_fit: strong\n",
  )
  write_text_file(
    run_path,
    BookQualityReviewRunLedger::{ runs: [old_run, current_run] }
    .to_json()
    .stringify(indent=2),
  )
  let status = render_book_quality_ai_review_status(result_dir~, run_path~)
  assert_true(status.contains("- current books: `1`"))
  assert_true(status.contains("- historical attempts: `1`"))
  assert_true(status.contains("- historical problem attempts: `1`"))
  assert_true(status.contains("## Current By Book"))
  assert_true(
    status.contains(
      "|wenyu-contest-express|written|written|`run-current`|Harvested MoonClaw AI semantic review result from run-current.|",
    ),
  )
  assert_true(status.contains("## Historical Attempts"))
  assert_true(
    status.contains(
      "|wenyu-contest-express|orphaned|written|`run-old`|Marked orphaned by Book Quality reconciliation because no result artifact was produced.|",
    ),
  )
}

///|
test "semantic quality gates readiness and next action" {
  assert_true(semantic_quality_allows_ready(Some(82)))
  assert_true(!semantic_quality_allows_ready(Some(64)))
  let action = next_book_quality_action("research-book", [], 100, Some(64))
  assert_true(action.contains("AI semantic review"))
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
  let snapshot_path = "\{root}/town.json"
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
    snapshot_path~,
    audit_path~,
  )
  assert_true(
    doctor.contains("Wrote book management audit for 2 registered book"),
  )
  assert_true(@fs.exists(audit_path))
  assert_true(@fs.exists("\{root}/book-quality/audit.md"))
  assert_true(@fs.exists("\{coding_root}/wiki/operations/review-policy.md"))
  let audit = render_book_quality(
    book_catalog_path=catalog_path,
    snapshot_path~,
  )
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
    snapshot_path~,
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

///|
async test "book quality includes live runtime books outside catalog" {
  let root = "/tmp/moontown-book-quality-runtime-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let catalog_path = "\{root}/moonbooks.json"
  let snapshot_path = "\{root}/town.json"
  let catalog = [
    @moonbook.BookCatalogEntry::new(
      id="coding",
      name="Coding",
      purpose="coding operations",
      workspace_root="\{root}/books/coding",
      tags=["operational"],
    ),
  ]
  @moonbook.save_catalog_file(catalog_path, catalog)
  let state = @core.empty_state(
    @core.TownConfig::new(id="quality-test", name="Quality Test Town"),
  )
  state.register_book(
    @core.BookRef::new(
      id="research-opc",
      name="OPC Research",
      purpose="Track One Person Company research over time.",
      workspace_root="\{root}/books/research-opc",
      tags=["research", "standing-watch"],
    ),
  )
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  let audit = inspect_book_quality(
    book_catalog_path=catalog_path,
    snapshot_path~,
  )
  assert_true(audit.total == 2)
  assert_true(audit.scores.any(fn(score) { score.book_id == "research-opc" }))
  let rendered = render_book_quality(
    book_catalog_path=catalog_path,
    snapshot_path~,
  )
  assert_true(rendered.contains("|research-opc|research-book|"))
}

///|
async test "semantic review bridge queues repair page and standing goal" {
  let root = "/tmp/moontown-book-quality-bridge-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let catalog_path = "\{root}/moonbooks.json"
  let snapshot_path = "\{root}/town.json"
  let result_dir = "\{root}/book-quality/ai-review-results"
  let bridge_path = "\{root}/book-quality/repair-bridge.json"
  let workspace_root = "\{root}/books/research-robotics"
  write_text_file(
    "\{root}/daemon.json",
    "{\"daemon_id\":\"test\",\"tick_sequence\":41}",
  )
  write_text_file(
    "\{result_dir}/research-robotics.md",
    [
      "ai_quality_score: 32", "ai_quality_grade: weak", "book_role_fit: acceptable",
      "repair_owner: moonbook", "next_repair_task: Build source-screen and evidence-matrix from verified robotics sources.",
      "projection_quality: weak", "evidence_accounting_ok: no",
    ].join("\n"),
  )
  @moonbook.save_catalog_file(catalog_path, [
    @moonbook.BookCatalogEntry::new(
      id="research-robotics",
      name="Robotics Research",
      purpose="Research embodied robotics.",
      workspace_root~,
      tags=["research"],
    ),
  ])
  let state = @core.empty_state(
    @core.TownConfig::new(id="bridge-test", name="Bridge Test"),
  )
  state.register_book(
    @core.BookRef::new(
      id="research-robotics",
      name="Robotics Research",
      purpose="Research embodied robotics.",
      workspace_root~,
      tags=["research"],
    ),
  )
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  @storage.save_standing_goals_file("\{root}/standing-goals.json", [])
  let summary = reconcile_book_quality_repair_bridge(
    book_catalog_path=catalog_path,
    snapshot_path~,
    result_dir~,
    bridge_path~,
  )
  assert_true(
    summary.contains("Bridged 1 weak AI semantic book-quality review"),
  )
  assert_true(
    @fs.exists("\{workspace_root}/wiki/reviews/book-quality-repair.md"),
  )
  let review = read_text_or_empty(
    "\{workspace_root}/wiki/reviews/book-quality-repair.md",
  )
  assert_true(review.contains("Build source-screen and evidence-matrix"))
  let goals = @storage.load_or_create_standing_goals(
    path="\{root}/standing-goals.json",
  )
  assert_eq(goals.length(), 1)
  assert_eq(goals[0].id, "book-quality-repair-research-robotics")
  assert_eq(goals[0].next_due_tick, 42)
  assert_eq(goals[0].source_policy, "web-first")
  assert_true(@fs.exists(bridge_path))
}

///|
async test "semantic review bridge skips archived hidden internal books" {
  let root = "/tmp/moontown-book-quality-bridge-archived-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let catalog_path = "\{root}/moonbooks.json"
  let snapshot_path = "\{root}/town.json"
  let result_dir = "\{root}/book-quality/ai-review-results"
  let bridge_path = "\{root}/book-quality/repair-bridge.json"
  let workspace_root = "\{root}/books/codex-smoke-pdf-watch"
  write_text_file(
    "\{root}/daemon.json",
    "{\"daemon_id\":\"test\",\"tick_sequence\":41}",
  )
  write_text_file(
    "\{result_dir}/codex-smoke-pdf-watch.md",
    [
      "ai_quality_score: 20", "ai_quality_grade: weak", "repair_owner: moonbook",
      "next_repair_task: Repair should not be queued for an archived smoke book.",
    ].join("\n"),
  )
  @moonbook.save_catalog_file(catalog_path, [
    @moonbook.BookCatalogEntry::new(
      id="codex-smoke-pdf-watch",
      name="Smoke PDF Watch",
      purpose="Archived proof artifact.",
      workspace_root~,
      tags=["research", "archived", "hidden", "internal"],
    ),
  ])
  let state = @core.empty_state(
    @core.TownConfig::new(
      id="bridge-archived-test",
      name="Bridge Archived Test",
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="codex-smoke-pdf-watch",
      name="Smoke PDF Watch",
      purpose="Archived proof artifact.",
      workspace_root~,
      tags=["research", "archived", "hidden", "internal"],
    ),
  )
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  @storage.save_standing_goals_file("\{root}/standing-goals.json", [
    @core.StandingGoal::new(
      id="book-quality-repair-codex-smoke-pdf-watch",
      title="Repair archived smoke book",
      prompt="This should be retired because the book is archived.",
      target_book_id=Some("codex-smoke-pdf-watch"),
      cadence_ticks=60,
      next_due_tick=42,
      enabled=true,
      source_policy="web-first",
      quality_threshold=80,
    ),
  ])
  let summary = reconcile_book_quality_repair_bridge(
    book_catalog_path=catalog_path,
    snapshot_path~,
    result_dir~,
    bridge_path~,
  )
  assert_true(
    summary.contains(
      "No weak AI semantic book-quality review needed repair bridging.",
    ),
  )
  assert_true(summary.contains("Retired 1 stale repair goal"))
  assert_false(
    @fs.exists("\{workspace_root}/wiki/reviews/book-quality-repair.md"),
  )
  let goals = @storage.load_or_create_standing_goals(
    path="\{root}/standing-goals.json",
  )
  assert_eq(goals.length(), 1)
  assert_eq(goals[0].id, "book-quality-repair-codex-smoke-pdf-watch")
  assert_false(goals[0].enabled)
  assert_true(@fs.exists(bridge_path))
}

///|
async test "semantic review bridge retires satisfied repair goals" {
  let root = "/tmp/moontown-book-quality-bridge-retire-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let catalog_path = "\{root}/moonbooks.json"
  let snapshot_path = "\{root}/town.json"
  let result_dir = "\{root}/book-quality/ai-review-results"
  let bridge_path = "\{root}/book-quality/repair-bridge.json"
  let workspace_root = "\{root}/books/research-strong"
  write_text_file(
    "\{root}/daemon.json",
    "{\"daemon_id\":\"test\",\"tick_sequence\":41}",
  )
  write_text_file(
    "\{result_dir}/research-strong.md",
    [
      "ai_quality_score: 91", "ai_quality_grade: excellent", "repair_owner: none",
      "next_repair_task: No repair needed.",
    ].join("\n"),
  )
  @moonbook.save_catalog_file(catalog_path, [
    @moonbook.BookCatalogEntry::new(
      id="research-strong",
      name="Strong Research",
      purpose="Already repaired research book.",
      workspace_root~,
      tags=["research"],
    ),
  ])
  let state = @core.empty_state(
    @core.TownConfig::new(id="bridge-retire-test", name="Bridge Retire Test"),
  )
  state.register_book(
    @core.BookRef::new(
      id="research-strong",
      name="Strong Research",
      purpose="Already repaired research book.",
      workspace_root~,
      tags=["research"],
    ),
  )
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  @storage.save_standing_goals_file("\{root}/standing-goals.json", [
    @core.StandingGoal::new(
      id="book-quality-repair-research-strong",
      title="Repair book quality: research-strong",
      prompt="Stale repair goal.",
      target_book_id=Some("research-strong"),
      cadence_ticks=60,
      next_due_tick=42,
      enabled=true,
      source_policy="web-first",
      quality_threshold=80,
    ),
  ])
  let summary = reconcile_book_quality_repair_bridge(
    book_catalog_path=catalog_path,
    snapshot_path~,
    result_dir~,
    bridge_path~,
  )
  assert_true(summary.contains("Retired 1 stale repair goal"))
  let goals = @storage.load_or_create_standing_goals(
    path="\{root}/standing-goals.json",
  )
  assert_eq(goals.length(), 1)
  assert_eq(goals[0].id, "book-quality-repair-research-strong")
  assert_false(goals[0].enabled)
  assert_false(
    @fs.exists("\{workspace_root}/wiki/reviews/book-quality-repair.md"),
  )
  assert_true(@fs.exists(bridge_path))
}
