///|
async fn read_lane_deep_report(entry : @moonbook.BookCatalogEntry) -> String {
  @support.read_text_or_empty(
    "\{@moonbook.workspace_root(entry)}/raw/bootstrap/deep-report.md",
  )
}
