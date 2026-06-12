///|
async test "bootstrap pdf evidence watch book installs workspace catalog and standing goal" {
  let root = "/tmp/moontown-pdf-evidence-watch-wbtest/book"
  let catalog_path = "/tmp/moontown-pdf-evidence-watch-wbtest/catalog.json"
  let goals_path = "/tmp/moontown-pdf-evidence-watch-wbtest/standing-goals.json"
  let summary = bootstrap_pdf_evidence_watch_book(
    book_id="research-domain-pdfs",
    title="Domain PDF Watch",
    purpose="Watch domain reports and promote accepted findings.",
    websites=["https://example.org/reports", "https://example.com/briefs"],
    analysis_method="# Custom PDF Analysis Method\n\nExtract definitions, deltas, claims, data tables, and decision implications.",
    cadence_ticks=42,
    book_catalog_path=catalog_path,
    standing_goal_path=goals_path,
    workspace_root=root,
  )
  assert_true(summary.contains("book_template_install_status: installed"))
  assert_true(summary.contains("research-domain-pdfs"))
  assert_true(@fs.exists("\{root}/book.json"))
  assert_true(@fs.exists("\{root}/raw/pdfs/.keep"))
  assert_true(@fs.exists("\{root}/raw/extracted/.keep"))
  assert_true(@fs.exists("\{root}/skills/pdf-watch/SKILL.md"))
  assert_true(@fs.exists("\{root}/skills/pdf-analysis/SKILL.md"))
  assert_true(@fs.exists("\{root}/book/site/generated/index.html"))
  let config = read_text_or_empty("\{root}/book.json")
  assert_true(config.contains("\"book_type\": \"pdf-evidence-watch\""))
  assert_true(config.contains("https://example.org/reports"))
  let method_text = read_text_or_empty(
    "\{root}/wiki/methods/analysis-method.md",
  )
  assert_true(method_text.contains("Custom PDF Analysis Method"))
  let catalog = @moonbook.load_or_create_catalog(path=catalog_path)
  let entry = @moonbook.entry_for_book_id(catalog, "research-domain-pdfs")
  assert_true(entry is Some(_))
  let goals = @storage.load_or_create_standing_goals(path=goals_path)
  let mut found_goal = false
  for goal in goals {
    if goal.id == "watch-research-domain-pdfs-pdfs" {
      found_goal = true
      match goal.target_book_id {
        Some(target_book_id) =>
          assert_eq(target_book_id, "research-domain-pdfs")
        None => fail("expected target book id")
      }
      assert_eq(goal.cadence_ticks, 42)
      assert_eq(goal.source_policy, "web-first")
      assert_true(goal.prompt.contains("https://example.com/briefs"))
    }
  }
  assert_true(found_goal)
  let status = inspect_pdf_evidence_watch_book(
    book_id="research-domain-pdfs",
    workspace_root=root,
    book_catalog_path=catalog_path,
    standing_goal_path=goals_path,
  )
  assert_eq(status.missing_count, 0)
  assert_true(status.has_catalog_entry)
  assert_true(status.has_standing_goal)
  assert_true(status.standing_goal_enabled)
  assert_true(status.ready)
}
