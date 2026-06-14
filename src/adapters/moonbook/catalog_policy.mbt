///|
fn catalog_entry_is_research(entry : BookCatalogEntry) -> Bool {
  @policy.catalog_entry_runs_research_evidence(entry.id, entry.name, entry.tags)
}

///|
fn catalog_entry_is_civic(entry : BookCatalogEntry) -> Bool {
  @policy.catalog_entry_runs_civic_protocol(entry.id, entry.name, entry.tags)
}
