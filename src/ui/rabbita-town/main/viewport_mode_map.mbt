///|
fn render_standalone_viewport_map(
  dispatch : Dispatch[Msg],
  model : Model,
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
  selected_node_key : String?,
  selected_worker_id : String?,
) -> @rabbita.Html {
  render_town_viewport(
    dispatch,
    model,
    scene,
    visible_overworld_workers(workers),
    executions,
    selected_node_key,
    selected_worker_id,
    "scene-frame-shell viewport-frame-shell",
    "scene-frame viewport-frame",
  )
}
