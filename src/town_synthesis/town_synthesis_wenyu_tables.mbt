///|
fn render_wenyu_artifact_matrix(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> String {
  ignore(state)
  let builder = StringBuilder::new()
  builder.write_string(wenyu_artifact_matrix_header())
  for lane in plan.lanes {
    builder.write_string(wenyu_artifact_matrix_row(lane.entry))
  }
  builder.to_string()
}

///|
fn wenyu_artifact_matrix_header() -> String {
  [
    "| Lane | Deep Report | Marketing Brief | Evidence Matrix | Wiki Home |", "| --- | --- | --- | --- | --- |",
  ].join("\n") +
  "\n"
}

///|
fn wenyu_artifact_matrix_row(entry : @moonbook.BookCatalogEntry) -> String {
  let root = @moonbook.workspace_root(entry)
  let deep_report = "`\{root}/raw/bootstrap/deep-report.md`"
  let marketing = "`\{root}/raw/bootstrap/marketing-brief.md`"
  let evidence = "`\{root}/raw/bootstrap/evidence-matrix.md`"
  let home = "`\{root}/wiki/Home.md`"
  "| \{entry.id} | \{deep_report} | \{marketing} | \{evidence} | \{home} |\n"
}

///|
async fn render_wenyu_readiness(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string(wenyu_readiness_header())
  for lane in plan.lanes {
    let summary = Some(@moonbook.summarize_state(lane.entry)) catch {
      _ => None
    }
    let status = lane_research_status(state, lane.entry.id)
    let gaps = @research_quality_runtime.research_quality_gaps(lane.entry)
    let gate = if gaps.is_empty() { "ready" } else { gaps.join("; ") }
    match summary {
      Some(summary) =>
        builder.write_string(
          wenyu_readiness_row(lane.entry.id, status, gate, summary),
        )
      None =>
        builder.write_string(
          wenyu_unavailable_readiness_row(lane.entry.id, status),
        )
    }
  }
  builder.to_string()
}

///|
fn wenyu_readiness_header() -> String {
  [
    "| Lane | Status | Verified Sources | Domain Evidence | Operational Evidence | Entities | Concepts | Quality Gate |",
    "| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |",
  ].join("\n") +
  "\n"
}

///|
fn wenyu_readiness_row(
  entry_id : String,
  status : String,
  gate : String,
  summary : @moonbook.BookStateSummary,
) -> String {
  [
    "| \{entry_id}",
    status,
    summary.verified_source_count.to_string(),
    summary.evidence_count.to_string(),
    summary.operational_evidence_count.to_string(),
    summary.entity_page_count.to_string(),
    summary.concept_page_count.to_string(),
    gate,
  ].join(" | ") +
  " |\n"
}

///|
fn wenyu_unavailable_readiness_row(
  entry_id : String,
  status : String,
) -> String {
  "| \{entry_id} | \{status} | 0 | 0 | 0 | 0 | 0 | summary unavailable |\n"
}
