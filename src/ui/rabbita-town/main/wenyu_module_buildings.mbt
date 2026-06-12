///|
fn render_wenyu_module_building(
  _dispatch : Dispatch[Msg],
  model : Model,
  civic : WenyuTownModule,
  executions : Array[@core.TaskExecutionRecord],
  selected_node_key : String?,
) -> @rabbita.Html {
  let runtime = wenyu_module_runtime_state(model, civic, executions)
  let width = civic.display_w
  let height = civic.display_h
  let style = [
    "left: \{iso_tile_left(civic.grid_x, civic.grid_y)}px",
    "top: \{iso_tile_top(civic.grid_x, civic.grid_y)}px",
    "z-index: \{260 + civic.grid_x + civic.grid_y}",
    "--module-width: \{width}px",
    "--module-height: \{height}px",
    "--module-footprint-w: \{civic.footprint_w}",
    "--module-footprint-h: \{civic.footprint_h}",
    "--module-image: url('\{civic.asset_base}')",
    "--module-roof-image: url('\{civic.asset_roof}')",
  ]
  let children : Array[@rabbita.Html] = [
    span(class="wenyu-module-footprint", no_children()),
    span(class="wenyu-module-shadow", no_children()),
    span(class="wenyu-module-sprite", no_children()),
    span(class="wenyu-module-light", no_children()),
  ]
  if runtime.visible_agent_count > 0 {
    children.push(
      span(class="wenyu-module-agent-count", "\{runtime.visible_agent_count}"),
    )
  }
  if runtime.issue_count > 0 {
    children.push(
      span(class="wenyu-module-issue-count", "\{runtime.issue_count}"),
    )
  }
  children.push(
    span(class="wenyu-module-label", [
      span(class="wenyu-module-title", civic.title),
      span(class="wenyu-module-district", civic.district),
      span(class="wenyu-module-state", runtime.status_label),
      span(class="wenyu-module-state-source", runtime.source_label),
    ]),
  )
  a(
    href="./viewport.html?assets=generated&mode=view&module=\{civic.id}&v=module-\{civic.id}",
    class=wenyu_module_building_class(civic, runtime, selected_node_key),
    style~,
    title="\{civic.title}: \{runtime.status_label}. \{runtime.detail}",
    children,
  )
}

///|
fn wenyu_module_building_selected(
  civic : WenyuTownModule,
  selected_node_key : String?,
) -> Bool {
  selected_node_key == Some(civic.id)
}

///|
fn wenyu_module_building_has_issues(runtime : WenyuModuleRuntimeState) -> Bool {
  runtime.issue_count > 0
}

///|
fn wenyu_module_building_class(
  civic : WenyuTownModule,
  runtime : WenyuModuleRuntimeState,
  selected_node_key : String?,
) -> String {
  "wenyu-module-building wenyu-module-\{civic.building_kind} style-\{civic.style_family} \{runtime.status_class}" +
  class_suffix_when(
    wenyu_module_building_selected(civic, selected_node_key),
    " selected",
  ) +
  class_suffix_when(wenyu_module_building_has_issues(runtime), " has-issues")
}

///|
fn render_wenyu_module_building_layer(
  dispatch : Dispatch[Msg],
  model : Model,
  executions : Array[@core.TaskExecutionRecord],
  selected_node_key : String?,
) -> @rabbita.Html {
  if !standalone_viewport_requested() {
    return div(
      class="wenyu-module-layer wenyu-module-layer-empty",
      no_children(),
    )
  }
  let children : Array[@rabbita.Html] = []
  for civic in wenyu_modules() {
    children.push(
      render_wenyu_module_building(
        dispatch, model, civic, executions, selected_node_key,
      ),
    )
  }
  div(class="wenyu-module-layer", children)
}
