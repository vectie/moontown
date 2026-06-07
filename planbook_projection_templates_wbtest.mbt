///|
test "planbook generated site keeps plan execute review identity" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="moontown-planbook",
    name="Moontown Quality Planbook",
    purpose="planbook",
    workspace_root="/tmp/planbook",
  )
  let html = planbook_generated_site_html(entry)
  assert_true(html.contains("<title>Moontown Quality Planbook</title>"))
  assert_true(
    html.contains("MoonBook managed / Mayor routed / MoonClaw executed"),
  )
  assert_true(html.contains("<h2>Plan</h2>"))
  assert_true(html.contains("<h2>Execute</h2>"))
  assert_true(html.contains("<h2>Review</h2>"))
  assert_true(!html.contains("Deep Research Analysis"))
}

///|
test "planbook generated site escapes workspace root in hero" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="moontown-planbook",
    name="Moontown Quality Planbook",
    purpose="planbook",
    workspace_root="/tmp/planbook/<unsafe>",
  )
  let html = planbook_generated_site_html(entry)
  assert_true(html.contains("/tmp/planbook/&lt;unsafe&gt;"))
  assert_true(!html.contains("/tmp/planbook/<unsafe>"))
}
