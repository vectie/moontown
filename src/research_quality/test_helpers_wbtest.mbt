///|
async fn cleaned_research_quality_test_root(root : String) -> String {
  ignore(@integration.run_checked("rm", ["-rf", root]))
  root
}

///|
fn included_source_screen(source_count : Int) -> String {
  let rows : Array[String] = []
  for index = 1 {
    if index > source_count {
      break
    }
    rows.push("| W\{index} | include |")
    continue index + 1
  }
  [
    "# Source Screen",
    "",
    "| Source ID | Decision |",
    "| --- | --- |",
    rows.join("\n"),
    "",
  ].join("\n")
}

///|
fn opc_research_catalog_entry(root : String) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id="research-opc",
    name="One Person Company",
    purpose="Track OPC",
    workspace_root=root,
  )
}
