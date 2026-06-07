///|
test "default operational UI state renders valid projection JSON" {
  let entry = operational_projection_test_entry()
  let text = default_operational_ui_state(
    entry, "Ops <Book>", "Keeps review memory & operating boundaries.",
  )
  let parsed = @json.parse(text) catch {
    _ => abort("default operational UI state should be valid JSON")
  }
  assert_eq(json_string_field(parsed, "book_id").unwrap(), "ops-book")
  assert_eq(json_string_field(parsed, "title").unwrap(), "Ops <Book>")
  assert_true(text.contains("\"status_chips\""))
  assert_true(text.contains("\"operational-book\""))
  assert_true(text.contains("OPERATIONAL_BOOK_CONTRACT.md"))
  assert_true(text.contains("wiki/operations/review-policy.md"))
  assert_true(text.contains("\"Operational bootstrap\""))
}

///|
test "default operational site escapes title summary and workspace path" {
  let entry = operational_projection_test_entry(
    workspace_root="/tmp/moontown/<ops>",
  )
  let html = default_operational_site(
    entry, "Ops <Book>", "Keeps review memory & operating boundaries.",
  )
  assert_true(html.has_prefix("<!doctype html><html><head>"))
  assert_true(html.contains("<style>"))
  assert_true(html.contains("MoonBook operational workspace"))
  assert_true(html.contains("<h1>Ops &lt;Book&gt;</h1>"))
  assert_true(html.contains("Keeps review memory &amp; operating boundaries."))
  assert_true(html.contains("/tmp/moontown/&lt;ops&gt;"))
  assert_true(html.has_suffix("</main></body></html>"))
}

///|
fn operational_projection_test_entry(
  workspace_root? : String = "/tmp/moontown/ops-book",
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id="ops-book",
    name="Ops Book",
    purpose="Operational memory.",
    workspace_root~,
    tags=["operational"],
  )
}
