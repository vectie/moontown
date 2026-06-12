///|
pub async fn cleaned_research_quality_test_root(root : String) -> String {
  @support.ignore_checked_command("rm", ["-rf", root])
  root
}

///|
pub fn research_quality_test_state() -> @core.TownState {
  @core.empty_state(@core.TownConfig::new(id="test", name="Test Town"))
}

///|
pub fn llm_research_book_ref(id : String, root : String) -> @core.BookRef {
  @core.BookRef::new(
    id~,
    name="LLM Training Research",
    purpose="research",
    workspace_root=root,
  )
}

///|
pub fn llm_research_catalog_entry(
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
pub fn research_quality_execution(
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
