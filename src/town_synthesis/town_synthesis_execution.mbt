///|
pub fn register_town_synthesis_execution(
  state : @core.TownState,
  goal : String,
  plan : @roles.MayorGoalPlan,
  path : String,
) -> Unit {
  register_town_book_if_missing(state)
  let task_id = town_synthesis_task_id(goal)
  state.replace_task(
    @core.TownTask::new(
      id=task_id,
      book_id="town",
      title="Mayor town-level synthesis",
      prompt="Combine \{plan.lanes.length()} isolated research lanes into one town-level synthesis and expose readiness gaps.",
      domain=@core.WorkDomain::Research,
      required_role=Some(@core.WorkerRole::Planner),
      required_capabilities=["synthesis", "supervision", "quality-gate"],
      status=town_synthesis_task_status(state, plan),
    ),
  )
  let status = town_synthesis_execution_status(state, plan)
  state.replace_execution(
    @core.TaskExecutionRecord::new(
      task_id~,
      book_id="town",
      packet_id="mayor-town-synthesis-\{town_goal_slug(goal)}",
      packet_path=path,
      status~,
      summary=town_synthesis_execution_summary(state, plan, path),
      output_contract="mayor.town_synthesis.v1",
      context_pages=plan.lanes.map(fn(lane) { lane.entry.id }),
      skill_paths=[],
      last_command=Some(path),
      assigned_worker_id=None,
      requires_review=false,
      notify_town=true,
    ),
  )
}

///|
fn register_town_book_if_missing(state : @core.TownState) -> Unit {
  for book in state.books {
    if book.id == "town" {
      return
    }
  }
  state.register_book(
    @core.BookRef::new(
      id="town",
      name="Moontown / Mayor",
      purpose="Shared town-level synthesis, supervision, and cross-book readiness.",
      workspace_root=".moontown",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["town", "mayor", "synthesis"],
    ),
  )
}
