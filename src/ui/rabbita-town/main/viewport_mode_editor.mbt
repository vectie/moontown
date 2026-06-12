///|
fn module_projection_count_for_configured_modules(model : Model) -> Int {
  let mut count = 0
  for civic in wenyu_modules() {
    match find_module_book_projection(model, civic) {
      Some(_) => count += 1
      None => ()
    }
  }
  count
}

///|
fn render_editor_module_row(
  dispatch : Dispatch[Msg],
  model : Model,
  civic : WenyuTownModule,
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let view = editor_module_row_view(model, civic, executions)
  button(
    class="editor-module-row \{view.runtime_class}",
    on_click=dispatch(SelectNode(civic.id)),
    [
      span(class="editor-module-title", view.title),
      span(class="editor-module-meta", view.identity),
      span(class="editor-module-meta", view.placement),
      span(class="editor-module-meta", view.style),
      span(class="editor-module-runtime", view.runtime_label),
      span(class="editor-module-meta", view.projection_status),
      span(class="editor-module-issues", view.issue_text),
    ],
  )
}

///|
fn render_viewport_editor_panel(
  dispatch : Dispatch[Msg],
  model : Model,
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let module_rows = wenyu_modules().map(civic => {
    render_editor_module_row(dispatch, model, civic, executions)
  })
  aside(class="viewport-editor-panel", [
    div(class="viewport-panel-heading", [
      p(class="eyebrow", "Editor Mode"),
      h2("Module Registry"),
      p(viewport_mode_summary(ViewportMode::EditorMode)),
    ]),
    div(class="viewport-editor-stats", [
      render_module_detail("Modules", "\{wenyu_module_count()} enabled"),
      render_module_detail("Placement", "\{wenyu_clean_module_count()} clean"),
      render_module_detail(
        "Book Outputs",
        "\{module_projection_count_for_configured_modules(model)} bound",
      ),
      render_module_detail("Config Version", "v\{wenyu_modules_version()}"),
    ]),
    render_editor_pipeline_panel(model),
    render_town_editor_boundary_panel(model),
    render_moondesk_handoff_panel(model),
    render_moondesk_bridge_panel(model),
    div(class="editor-module-list", module_rows),
  ])
}

///|
fn render_viewport_editor_body(
  dispatch : Dispatch[Msg],
  model : Model,
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
  selected_node_key : String?,
  selected_worker_id : String?,
) -> @rabbita.Html {
  section(class="viewport-editor-layout", [
    render_standalone_viewport_map(
      dispatch, model, scene, workers, executions, selected_node_key, selected_worker_id,
    ),
    render_viewport_editor_panel(dispatch, model, executions),
  ])
}
