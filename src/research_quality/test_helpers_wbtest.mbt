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
fn research_quality_observation_fixture(
  root? : String = "/tmp/research-quality-observation",
  missing_required_paths? : Array[String] = [],
  has_research_source_marker? : Bool = true,
  readiness? : ResearchReadiness? = Some({
    book_id: "research-opc",
    root,
    source_page_count: 1,
    verified_source_count: 1,
    entity_page_count: 1,
    concept_page_count: 1,
    query_note_count: 0,
    evidence_count: 1,
    pending_review_count: 0,
    substantive_coverage_ready: true,
    gaps: [],
  }),
  brief? : String? = None,
  overview? : String? = None,
  search_log? : String? = None,
  source_screen? : String? = None,
  tool_blockers? : String? = None,
  deep_report? : String? = None,
  reference_output? : String? = None,
  has_runtime_entity_contamination? : Bool = false,
  has_topic_entity_page? : Bool = true,
  has_topic_concept_page? : Bool = true,
  has_topic_source_page? : Bool = true,
  generated_site? : String? = None,
  generated_site_read_error? : Bool = false,
  site_entry? : String? = None,
  site_entry_read_error? : Bool = false,
) -> ResearchQualityObservation {
  {
    root,
    missing_required_paths,
    has_research_source_marker,
    readiness,
    brief,
    overview,
    search_log,
    source_screen,
    tool_blockers,
    deep_report,
    reference_output,
    has_runtime_entity_contamination,
    has_topic_entity_page,
    has_topic_concept_page,
    has_topic_source_page,
    generated_site,
    generated_site_read_error,
    site_entry,
    site_entry_read_error,
  }
}
