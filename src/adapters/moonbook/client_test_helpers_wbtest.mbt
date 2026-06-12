///|
fn moonbook_adapter_catalog_entry(
  id~ : String,
  name~ : String,
  purpose~ : String,
  workspace_root~ : String,
  tags? : Array[String] = [],
  skills? : Array[String] = [],
) -> BookCatalogEntry {
  BookCatalogEntry::new(id~, name~, purpose~, workspace_root~, tags~, skills~)
}

///|
fn moonbook_adapter_opc_research_entry(
  workspace_root? : String = "/tmp/research-opc",
) -> BookCatalogEntry {
  moonbook_adapter_catalog_entry(
    id="research-opc",
    name="One Person Company",
    purpose="Track OPC research",
    workspace_root~,
  )
}

///|
fn moonbook_adapter_external_research_entry(
  id~ : String,
  name~ : String,
  purpose~ : String,
  workspace_root~ : String,
) -> BookCatalogEntry {
  moonbook_adapter_catalog_entry(id~, name~, purpose~, workspace_root~)
}

///|
fn moonbook_adapter_task(
  id~ : String,
  title~ : String,
  kind~ : String,
  prompt~ : String,
  goal? : String? = None,
  priority? : Int = 80,
  requires_review? : Bool = true,
  target_pages? : Array[String] = [],
) -> BookTask {
  BookTask::new(
    id~,
    goal~,
    title~,
    kind~,
    prompt~,
    priority~,
    requires_review~,
    target_pages~,
  )
}
