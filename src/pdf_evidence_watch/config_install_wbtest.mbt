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
  assert_true(summary.contains("book_template_install_status: installed"))
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
