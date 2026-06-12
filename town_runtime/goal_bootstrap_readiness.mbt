///|
async fn research_goal_needs_bootstrap(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
  summary : @moonbook.BookStateSummary,
  quality_gaps? : Array[String] = [],
) -> Bool {
  if !is_research_goal(goal) {
    return false
  }
  let no_substantive_tree = !has_substantive_research_tree(entry)
  let missing_domain_coverage = summary.entity_count == 0 &&
    summary.concept_count == 0
  let no_durable_sources = summary.verified_source_count == 0
  let no_durable_evidence = summary.evidence_count == 0
  let quality_repair_needed = !quality_gaps.is_empty()
  no_substantive_tree ||
  missing_domain_coverage ||
  no_durable_sources ||
  no_durable_evidence ||
  quality_repair_needed
}

///|
async fn has_substantive_research_tree(
  entry : @moonbook.BookCatalogEntry,
) -> Bool {
  let root = @moonbook.workspace_root(entry)
  let paths = [
    "\{root}/wiki/entities",
    "\{root}/wiki/concepts",
    "\{root}/wiki/sources",
    "\{root}/wiki/queries",
  ]
  for path in paths {
    let listed = @integration.run_checked("find", [path, "-type", "f"]) catch {
      _ => continue
    }
    if !listed.stdout.trim().is_blank() {
      return true
    }
  }
  false
}
