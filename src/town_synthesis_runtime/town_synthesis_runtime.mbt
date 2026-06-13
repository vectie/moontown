///|
pub async fn write_town_goal_synthesis(
  state : @core.TownState,
  goal : String,
  plan : @roles.MayorGoalPlan,
  snapshot_path : String,
) -> Unit {
  if plan.lanes.length() < 2 {
    return
  }
  let path = @town_synthesis.town_synthesis_path(snapshot_path, goal)
  let latest_path = @town_synthesis.town_synthesis_latest_path(snapshot_path)
  let lane_reports = load_town_synthesis_lane_reports(plan)
  let content = @town_synthesis.render_town_goal_synthesis(
    state, goal, plan, lane_reports,
  )
  @support.write_text_file(path, content)
  @support.write_text_file(latest_path, content)
  @town_synthesis.register_town_synthesis_execution(state, goal, plan, path)
  state.record_event(
    @core.TownEvent::new(
      id="event-town-synthesis-\{state.events.length()}",
      kind="synthesis",
      detail="Mayor wrote town-level synthesis for \{plan.lanes.length()} lanes: \{path}",
      related_task_id=Some(@town_synthesis.town_synthesis_task_id(goal)),
      related_book_id=Some("town"),
    ),
  )
}

///|
async fn load_town_synthesis_lane_reports(
  plan : @roles.MayorGoalPlan,
) -> Array[@town_synthesis.TownSynthesisLaneReport] {
  let reports : Array[@town_synthesis.TownSynthesisLaneReport] = []
  for lane in plan.lanes {
    reports.push({
      book_id: lane.entry.id,
      report_text: read_lane_deep_report(lane.entry),
    })
  }
  reports
}

///|
async fn read_lane_deep_report(entry : @moonbook.BookCatalogEntry) -> String {
  @support.read_text_or_empty(
    "\{@moonbook.workspace_root(entry)}/raw/bootstrap/deep-report.md",
  )
}
