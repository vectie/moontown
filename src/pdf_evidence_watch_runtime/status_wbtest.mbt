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
async test "pdf evidence watch status helper reports required path gaps" {
  let root = "/tmp/moontown-pdf-evidence-watch-wbtest/status-helper"
  ignore_checked_command("rm", ["-rf", root])
  let missing_before = workspace_missing_relative_paths(
    root,
    @pdf_evidence_watch.pdf_evidence_watch_required_paths(),
  )
  assert_eq(
    missing_before.length(),
    @pdf_evidence_watch.pdf_evidence_watch_required_paths().length(),
  )
  write_text_file("\{root}/book.json", "{}")
  write_text_file("\{root}/raw/pdfs/.keep", "")
  let missing_after = workspace_missing_relative_paths(
    root,
    @pdf_evidence_watch.pdf_evidence_watch_required_paths(),
  )
  assert_true(missing_after.length() < missing_before.length())
  assert_true(!missing_after.contains("book.json"))
  assert_true(!missing_after.contains("raw/pdfs/.keep"))
  assert_true(missing_after.contains("wiki/index.md"))
}
