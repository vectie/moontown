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

///|
async test "pdf evidence watch status reports missing files before bootstrap" {
  let status = inspect_pdf_evidence_watch_book(
    book_id="research-missing-pdfs",
    workspace_root="/tmp/moontown-pdf-evidence-watch-wbtest/missing",
    book_catalog_path="/tmp/moontown-pdf-evidence-watch-wbtest/missing-catalog.json",
    standing_goal_path="/tmp/moontown-pdf-evidence-watch-wbtest/missing-goals.json",
  )
  assert_true(status.missing_count > 0)
  assert_false(status.ready)
}

///|
async test "install pdf evidence watch book from moondesk config file" {
  let base = "/tmp/moontown-pdf-evidence-watch-wbtest/config-install"
  let config_path = "\{base}/pdf-watch.json"
  let method_path = "\{base}/method.md"
  let workspace_root = "\{base}/workspace"
  let catalog_path = "\{base}/catalog.json"
  let goals_path = "\{base}/standing-goals.json"
  write_text_file(
    method_path, "# Method From File\n\nAnalyze tables, claims, provenance, and operator deltas.",
  )
  let spec = PdfEvidenceWatchInstallSpec::{
    book_id: "research-configured-pdfs",
    title: "Configured PDF Watch",
    purpose: "Configured by Moondesk-style JSON.",
    websites: ["https://example.net/papers"],
    analysis_method: "",
    analysis_method_path: "method.md",
    cadence_ticks: 17,
    workspace_root,
  }
  write_text_file(config_path, spec.to_json().stringify(indent=2))
  let summary = install_pdf_evidence_watch_book_config(
    config_path,
    book_catalog_path=catalog_path,
    standing_goal_path=goals_path,
  )
  assert_true(summary.contains("Installed PDF Evidence Watch config"))
  let config = read_text_or_empty("\{workspace_root}/book.json")
  assert_true(config.contains("https://example.net/papers"))
  let method_text = read_text_or_empty(
    "\{workspace_root}/wiki/methods/analysis-method.md",
  )
  assert_true(method_text.contains("Method From File"))
  let goals = @storage.load_or_create_standing_goals(path=goals_path)
  let mut found_goal = false
  for goal in goals {
    if goal.id == "watch-research-configured-pdfs-pdfs" {
      found_goal = true
      assert_eq(goal.cadence_ticks, 17)
    }
  }
  assert_true(found_goal)
}

///|
async test "archive pdf evidence watch book disables standing watch and hides catalog entry" {
  let base = "/tmp/moontown-pdf-evidence-watch-wbtest/archive"
  ignore_checked_command("rm", ["-rf", base])
  let workspace_root = "\{base}/workspace"
  let catalog_path = "\{base}/catalog.json"
  let goals_path = "\{base}/standing-goals.json"
  let event_path = "\{base}/book-template-request-events.jsonl"
  ignore(
    bootstrap_pdf_evidence_watch_book(
      book_id="research-archive-pdfs",
      title="Archive PDF Watch",
      purpose="Temporary smoke book.",
      websites=["https://example.org/reports"],
      book_catalog_path=catalog_path,
      standing_goal_path=goals_path,
      workspace_root~,
    ),
  )
  let goals_before = @storage.load_or_create_standing_goals(path=goals_path)
  goals_before.push(
    @core.StandingGoal::new(
      id="book-quality-repair-research-archive-pdfs",
      title="Repair archived PDF watch",
      prompt="This repair goal should be retired with the archived book.",
      target_book_id=Some("research-archive-pdfs"),
      cadence_ticks=60,
      next_due_tick=1,
      enabled=true,
      source_policy="book-first",
    ),
  )
  @storage.save_standing_goals_file(goals_path, goals_before)
  let summary = archive_pdf_evidence_watch_book(
    book_id="research-archive-pdfs",
    reason="Smoke proof complete.",
    book_catalog_path=catalog_path,
    standing_goal_path=goals_path,
    request_event_path=event_path,
  )
  assert_true(summary.contains("Archived PDF Evidence Watch book"))
  let status = inspect_pdf_evidence_watch_book(
    book_id="research-archive-pdfs",
    workspace_root~,
    book_catalog_path=catalog_path,
    standing_goal_path=goals_path,
  )
  assert_true(status.has_catalog_entry)
  assert_true(status.has_standing_goal)
  assert_false(status.standing_goal_enabled)
  assert_false(status.ready)
  assert_true(
    summary.contains("Disabled standing goals targeting this book: `2`"),
  )
  let goals = @storage.load_or_create_standing_goals(path=goals_path)
  for goal in goals {
    if goal.id == "watch-research-archive-pdfs-pdfs" {
      assert_false(goal.enabled)
    }
    if goal.id == "book-quality-repair-research-archive-pdfs" {
      assert_false(goal.enabled)
    }
  }
  let catalog = @moonbook.load_or_create_catalog(path=catalog_path)
  match @moonbook.entry_for_book_id(catalog, "research-archive-pdfs") {
    Some(entry) => {
      assert_true(entry.tags.contains("archived"))
      assert_true(entry.tags.contains("hidden"))
      assert_true(entry.tags.contains("internal"))
    }
    None => fail("expected archived catalog entry")
  }
  let event_text = read_text_or_empty(event_path)
  assert_true(event_text.contains("\"status\":\"archived\""))
  assert_true(event_text.contains("archive-research-archive-pdfs"))
}
