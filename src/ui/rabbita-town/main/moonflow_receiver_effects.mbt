///|
fn load_moonflow_receiver_cmd(
  dispatch : Dispatch[Msg],
  request : MoonFlowReceiverRequest,
) -> Cmd {
  @rabbita.perform(fn(raw) { dispatch(MoonFlowReceiverInspected(raw)) }, async fn() noraise {
    wait_moonflow_receiver_inspection(
      inspect_moonflow_receiver_json(request.run_id, request.handoff_token),
    )
  })
}

///|
fn execute_moonflow_receiver_cmd(
  dispatch : Dispatch[Msg],
  request : MoonFlowReceiverRequest,
  intake : MoonFlowReceiverIntake,
  action : String,
) -> Cmd {
  @rabbita.perform(fn(raw) { dispatch(MoonFlowReceiverSettled(raw)) }, async fn() noraise {
    wait_moonflow_receiver_settlement(
      execute_moonflow_receiver_json(
        moontown_product_api_path("api/research-handoffs/moonflow/" + action),
        action,
        request.run_id,
        request.handoff_token,
        intake.to_json().stringify(),
      ),
    )
  })
}
