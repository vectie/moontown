///|
async fn cleaned_research_quality_test_root(root : String) -> String {
  ignore_checked_command("rm", ["-rf", root])
  root
}

///|
fn research_quality_test_state() -> @core.TownState {
  @core.empty_state(@core.TownConfig::new(id="test", name="Test Town"))
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

///|
fn llm_research_book_ref(id : String, root : String) -> @core.BookRef {
  @core.BookRef::new(
    id~,
    name="LLM Training Research",
    purpose="research",
    workspace_root=root,
  )
}

///|
fn llm_research_catalog_entry(
  id : String,
  root : String,
) -> @moonbook.BookCatalogEntry {
  @moonbook.BookCatalogEntry::new(
    id~,
    name="LLM Training Research",
    purpose="research",
    workspace_root=root,
  )
}

///|
fn research_quality_execution(
  task_id : String,
  book_id : String,
  status : @core.TaskExecutionStatus,
  summary : String,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id~,
    packet_id="packet",
    packet_path="packet.json",
    status~,
    summary~,
    output_contract="research",
    attempt=1,
  )
}
