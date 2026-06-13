///|
async fn render_town_evidence_and_limits(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("### Lane Matrix\n\n")
  builder.write_string(render_town_lane_matrix(state, plan))
  builder.write_string("\n### Readiness\n\n")
  for lane in plan.lanes {
    let gaps = @research_quality_runtime.research_quality_gaps(lane.entry)
    if gaps.is_empty() {
      builder.write_string(
        "- \{lane.entry.id}: ready for cross-lane synthesis.\n",
      )
    } else {
      let gap_summary = gaps.join("; ")
      builder.write_string("- \{lane.entry.id}: blocked by \{gap_summary}.\n")
    }
  }
  builder.write_string("\n")
  builder.write_string(
    "Limit: this town report relies on the three lane reports produced by MoonBook. If a lane report is shallow, missing, or process-heavy, Moontown should mark the town synthesis as review-queued instead of masking the weakness with generic ecosystem prose.\n\n",
  )
  builder.write_string("Mayor decision: ")
  builder.write_string(town_synthesis_decision(state, plan))
  builder.to_string()
}

///|
async fn render_town_lane_matrix(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string(
    "| Lane | Status | Verified Sources | Domain Evidence | Operational Evidence | Entities | Concepts | Deep Report |\n",
  )
  builder.write_string(
    "| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |\n",
  )
  for lane in plan.lanes {
    let summary = Some(@moonbook.summarize_state(lane.entry)) catch {
      _ => None
    }
    let status = lane_research_status(state, lane.entry.id)
    let root = @moonbook.workspace_root(lane.entry)
    match summary {
      Some(summary) =>
        builder.write_string(
          "| \{lane.entry.id} | \{status} | \{summary.verified_source_count} | \{summary.evidence_count} | \{summary.operational_evidence_count} | \{summary.entity_page_count} | \{summary.concept_page_count} | `\{root}/raw/bootstrap/deep-report.md` |\n",
        )
      None =>
        builder.write_string(
          "| \{lane.entry.id} | \{status} | 0 | 0 | 0 | 0 | 0 | `\{root}/raw/bootstrap/deep-report.md` |\n",
        )
    }
  }
  builder.to_string()
}
