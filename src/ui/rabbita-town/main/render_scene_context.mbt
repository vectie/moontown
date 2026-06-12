///|
priv struct RenderSceneContext {
  state : @core.TownState
  scene : @ui.SceneRenderModel
  workers : Array[WorkerSim]
  executions : Array[@core.TaskExecutionRecord]
  alerts : Array[String]
  selected_node_key : String?
  selected_worker_id : String?
}

///|
fn render_scene_context(model : Model) -> RenderSceneContext {
  let state = state_for_model(model)
  let scene = town_scene(model)
  let workers = workers_for_model(model)
  let executions = state.executions
  {
    state,
    scene,
    workers,
    executions,
    alerts: all_alerts(scene, model),
    selected_node_key: selected_node_key(model),
    selected_worker_id: selected_worker_id(model),
  }
}

///|
fn selected_node_key(model : Model) -> String? {
  match model.selection {
    Node(node_key) => Some(node_key)
    _ => None
  }
}

///|
fn selected_worker_id(model : Model) -> String? {
  match model.selection {
    Worker(worker_id) => Some(worker_id)
    _ => None
  }
}
