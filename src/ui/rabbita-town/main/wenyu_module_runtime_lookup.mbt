///|
fn find_module_execution(
  civic : WenyuTownModule,
  executions : Array[@core.TaskExecutionRecord],
) -> @core.TaskExecutionRecord? {
  let mut matched : @core.TaskExecutionRecord? = None
  for execution in executions {
    if module_book_matches(civic, execution.book_id) {
      matched = Some(execution)
    }
  }
  matched
}

///|
fn find_module_visual_building(
  model : Model,
  civic : WenyuTownModule,
) -> VisualBuildingSnapshot? {
  match model.visual_projection {
    Some(projection) => {
      for building in projection.buildings {
        if module_book_matches(civic, building.book_id) {
          return Some(building)
        }
      }
      None
    }
    None => None
  }
}

///|
fn find_module_visual_module(
  model : Model,
  civic : WenyuTownModule,
) -> VisualModuleSnapshot? {
  match model.visual_projection {
    Some(projection) =>
      match projection.modules {
        Some(modules) => {
          for module_status in modules {
            if module_status.module_id == civic.id ||
              module_book_matches(civic, module_status.book_id) {
              return Some(module_status)
            }
          }
          None
        }
        None => None
      }
    None => None
  }
}

///|
fn module_visual_agents(
  model : Model,
  civic : WenyuTownModule,
) -> Array[VisualAgentSnapshot] {
  match model.visual_projection {
    Some(projection) =>
      projection.agents.filter(agent => {
        module_book_matches(civic, agent.book_id)
      })
    None => []
  }
}

///|
fn module_active_visual_agents(
  model : Model,
  civic : WenyuTownModule,
) -> Array[VisualAgentSnapshot] {
  module_visual_agents(model, civic).filter(agent => {
    agent.visible_on_overworld ||
    viewport_visual_phase_is_active_for_module(agent.phase)
  })
}
