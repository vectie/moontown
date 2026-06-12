///|
fn render_viewport_view_body(
  dispatch : Dispatch[Msg],
  model : Model,
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
  selected_node_key : String?,
  selected_worker_id : String?,
) -> @rabbita.Html {
  match model.selection {
    Node(node_key) =>
      match find_wenyu_module(node_key) {
        Some(civic) =>
          render_wenyu_module_interior(
            dispatch, model, civic, workers, executions,
          )
        None => render_building_interior(dispatch, scene, workers, node_key)
      }
    _ =>
      section(class="viewport-view-mode", [
        p(
          class="viewport-mode-note",
          viewport_mode_summary(ViewportMode::ViewMode),
        ),
        render_standalone_viewport_map(
          dispatch, model, scene, workers, executions, selected_node_key, selected_worker_id,
        ),
      ])
  }
}
