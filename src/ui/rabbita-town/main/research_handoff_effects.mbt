///|
fn load_research_handoff_cmd(
  dispatch : Dispatch[Msg],
  request : ResearchHandoffRequest,
) -> Cmd {
  @rabbita.perform(fn(raw) { dispatch(ResearchHandoffInspected(raw)) }, async fn() noraise {
    wait_research_handoff_inspection(
      inspect_research_handoff_json(
        moontown_product_api_path("api/research-handoffs/inspect"),
        request.handoff_url,
        request.handoff_contract,
        request.handoff_id,
      ),
    )
  })
}

///|
fn execute_research_handoff_cmd(
  dispatch : Dispatch[Msg],
  request : ResearchHandoffRequest,
  action : String,
) -> Cmd {
  @rabbita.perform(fn(raw) { dispatch(ResearchHandoffExecuted(raw)) }, async fn() noraise {
    wait_research_handoff_execution(
      execute_research_handoff_json(
        moontown_product_api_path("api/research-handoffs/" + action),
        action,
        request.handoff_url,
        request.handoff_contract,
        request.handoff_id,
      ),
    )
  })
}

///|
fn initial_app_cmd(dispatch : Dispatch[Msg], model : Model) -> Cmd {
  let commands : Array[Cmd] = [
    schedule_tick(dispatch),
    install_town_life_storage_bridge(dispatch),
  ]
  match model.research_handoff {
    LoadingResearchHandoff(request) =>
      commands.push(load_research_handoff_cmd(dispatch, request))
    _ => ()
  }
  match model.moonflow_receiver {
    LoadingMoonFlowReceiver(request) =>
      commands.push(load_moonflow_receiver_cmd(dispatch, request))
    _ => ()
  }
  @rabbita.batch(commands)
}
