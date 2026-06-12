///|
fn wenyu_module_runtime_state(
  model : Model,
  civic : WenyuTownModule,
  executions : Array[@core.TaskExecutionRecord],
) -> WenyuModuleRuntimeState {
  let issue_count = module_validation_issues(civic).length()
  let active_agent_count = module_active_visual_agents(model, civic).length()
  match find_module_visual_module(model, civic) {
    Some(module_status) =>
      return runtime_state_from_visual_module(module_status, issue_count)
    None => ()
  }
  match find_module_visual_building(model, civic) {
    Some(building) =>
      return runtime_state_from_visual_building(
        building, active_agent_count, issue_count,
      )
    None => ()
  }
  match find_module_execution(civic, executions) {
    Some(execution) =>
      return runtime_state_from_execution(
        execution, active_agent_count, issue_count,
      )
    None => ()
  }
  match find_module_civic_health(model, civic) {
    Some(health) =>
      return runtime_state_from_civic_health(
        health, active_agent_count, issue_count,
      )
    None => runtime_state_from_config(civic, active_agent_count, issue_count)
  }
}
