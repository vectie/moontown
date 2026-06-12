///|
fn town_report_integration_table_header() -> String {
  [
    "| Layer | Project | Primary Responsibility | Town-Level Interpretation |", "| --- | --- | --- | --- |",
    "",
  ].join("\n")
}

///|
fn town_report_integration_table_row(
  topic : String,
  entry_id : String,
) -> String {
  "| \{display_topic_title(topic)} | \{entry_id} | \{project_responsibility(topic)} | \{project_town_interpretation(topic)} |\n"
}

///|
fn town_report_technical_resource_table_header() -> String {
  [
    "| Lane | Deep Report | Evidence Matrix | Generated Site |", "| --- | --- | --- | --- |",
    "",
  ].join("\n")
}

///|
fn town_report_technical_resource_row(
  entry : @moonbook.BookCatalogEntry,
) -> String {
  let root = @moonbook.workspace_root(entry)
  let site = @moonbook.generated_site_index_path(entry)
  "| \{entry.id} | `\{root}/raw/bootstrap/deep-report.md` | `\{root}/raw/bootstrap/evidence-matrix.md` | `\{site}` |\n"
}

///|
fn town_report_technical_quality_standard() -> String {
  "The town report should be judged against the `research-report` skill standard: at least ten sections for a multi-project report, thesis-first prose, tables, relationship diagrams, maturity assessment, and an evidence/limits section."
}

///|
fn town_report_technical_evidence_policy() -> String {
  [
    "The strongest technical evidence in the current run comes from repository-controlled READMEs, local source files, Moon module metadata, architecture docs, and the generated deep reports.",
    "The town synthesis treats these as lane-owned evidence rather than copying raw logs directly into the main article.",
  ].join(" ") +
  "\n\n"
}
