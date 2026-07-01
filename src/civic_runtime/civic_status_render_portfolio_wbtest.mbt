///|
test "civic status markdown row and note line render service evidence" {
  let service = test_civic_service_health(
    title="Policy Hall",
    status="needs-review",
    protocol_status="review",
    latest_decision="needs_review",
    latest_pages_changed=2,
    latest_accepted_facts=3,
    latest_review_items=1,
    missing_required_paths=["wiki/a.md", "wiki/b.md", "wiki/c.md", "wiki/d.md"],
    notes=["workspace is operable", "1 review item requires judgment"],
  )
  let row = civic_service_markdown_row(service)
  assert_true(
    row.has_prefix(
      "|Policy Hall|agent-workspace|policy-intelligence|review|needs-review|yes|needs_review|2|3|1|",
    ),
  )
  assert_true(row.contains("wiki/a.md<br>wiki/b.md<br>wiki/c.md<br>+1 more"))
  assert_true(row.has_suffix("|\n"))
  assert_eq(
    civic_service_note_line(service),
    "- Policy Hall: workspace is operable; 1 review item requires judgment\n",
  )
}

///|
test "civic status table header centralizes columns and alignments" {
  let columns = civic_status_table_columns()
  let alignments = civic_status_table_alignments()
  assert_eq(columns.length(), 11)
  assert_eq(alignments.length(), columns.length())
  assert_eq(
    civic_status_table_header(),
    [
      "| Service | Mode | Skill | Protocol | Status | Operable | Latest decision | Changed pages | Accepted facts | Review items | Missing paths |",
      "|---|---|---|---:|---:|---:|---|---:|---:|---:|---|", "",
    ].join("\n"),
  )
}

///|
test "civic portfolio markdown starts with summary and service table" {
  let services = [
    test_civic_service_health(
      title="Policy Hall",
      protocol_status="review",
      status="needs-review",
      operable=true,
      latest_decision="needs_review",
      latest_pages_changed=2,
      latest_accepted_facts=3,
      latest_review_items=1,
      notes=["workspace is operable"],
    ),
  ]
  let portfolio = civic_service_portfolio(
    services, ".moonsuite/products/moontown/civic/status.json",
  )
  let markdown = render_wenyu_civic_portfolio(portfolio)
  assert_true(markdown.has_prefix("# Wenyu Civic Service Status\n\n"))
  assert_true(
    markdown.contains(
      "Total: 1; operable: 1; proven by result: 1; review: 1; blocked: 0; missing/incomplete: 0.",
    ),
  )
  assert_true(markdown.contains(civic_status_table_header()))
  assert_true(markdown.contains("|Policy Hall|agent-workspace|"))
  assert_true(markdown.contains("\n## Notes\n\n"))
}

///|
test "compact missing paths summarizes empty short and long lists" {
  assert_eq(compact_missing_paths([]), "none")
  assert_eq(compact_missing_paths(["a.md", "b.md"]), "a.md<br>b.md")
  assert_eq(
    compact_missing_paths(["a.md", "b.md", "c.md", "d.md", "e.md"]),
    "a.md<br>b.md<br>c.md<br>+2 more",
  )
}

///|
test "civic portfolio counts operable and review services" {
  let services = [
    test_civic_service_health(
      title="Policy Hall",
      protocol_status="review",
      status="needs-review",
      operable=true,
      latest_decision="needs_review",
      latest_pages_changed=2,
      latest_accepted_facts=3,
      latest_review_items=1,
      notes=["workspace is operable"],
    ),
    test_civic_service_health(
      title="Contest Express",
      protocol_status="defined",
      status="missing-workspace",
      operable=false,
      missing_required_paths=["wiki/index.md"],
      notes=["workspace is not yet fully operable"],
    ),
  ]
  let portfolio = civic_service_portfolio(
    services, ".moonsuite/products/moontown/civic/status.json",
  )
  assert_eq(portfolio.total, 2)
  assert_eq(portfolio.operable_count, 1)
  assert_eq(portfolio.proven_count, 1)
  assert_eq(portfolio.review_count, 1)
  assert_eq(portfolio.missing_count, 1)
  assert_eq(
    portfolio.markdown_path,
    ".moonsuite/products/moontown/civic/status.md",
  )
  let json_text = portfolio.to_json().stringify()
  assert_true(json_text.contains("protocol_history"))
  assert_true(json_text.contains("protocol_history_state"))
}
