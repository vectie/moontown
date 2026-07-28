///|
fn render_standalone_viewport_page(
  dispatch : Dispatch[Msg],
  model : Model,
  context : RenderSceneContext,
) -> @rabbita.Html {
  ignore(context)
  let children : Array[@rabbita.Html] = [
    render_golden_valley_canvas(dispatch, model),
    div(
      class="town-badge-wrap pointer-events-none absolute left-4 top-4",
      render_energy_valley_town_badge(dispatch, model),
    ),
    div(
      class="town-metric-wrap pointer-events-none absolute right-4 top-4 flex flex-col items-end gap-2",
      [
        render_energy_valley_metric_chips(dispatch, model),
        render_energy_valley_dashboard(dispatch, model),
      ],
    ),
    div(
      class="town-runtime-wrap",
      render_energy_valley_runtime_summary(dispatch, model),
    ),
    div(
      class="town-event-wrap pointer-events-none absolute bottom-24 left-4",
      render_energy_valley_event_feed(model),
    ),
    div(
      class="town-inspector-wrap pointer-events-none absolute right-4 top-24",
      render_energy_valley_inspector(dispatch, model),
    ),
    div(
      class="town-tool-wrap pointer-events-none absolute bottom-4 left-1/2 -translate-x-1/2",
      render_energy_valley_tool_dock(dispatch, model),
    ),
    div(class="town-actions", [
      button(
        class="town-action",
        on_click=dispatch(OpenEnergyGuide),
        "? 指南",
      ),
      button(
        class="town-action",
        title="重置小镇",
        on_click=dispatch(OpenEnergyReset),
        "↺ 重置",
      ),
    ]),
    if model.energy_toast.is_empty() {
      @html.nothing
    } else {
      div(
        class="absolute left-1/2 top-20 -translate-x-1/2 rounded-xl bg-rose-500/85 px-4 py-2 text-[13px] text-white shadow-xl backdrop-blur-sm",
        attrs=@html.Attrs::build().aria_live("polite"),
        model.energy_toast,
      )
    },
  ]
  for overlay in render_energy_valley_overlays(dispatch, model) {
    children.push(overlay)
  }
  div(
    class="energy-valley-golden relative h-screen w-screen overflow-hidden bg-slate-950 select-none",
    children,
  )
}

///|
fn viewport_detail_class(model : Model) -> String {
  match model.selection {
    Overview => ""
    _ => " viewport-detail-open"
  }
}

///|
fn render_standalone_viewport_actions(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  render_viewport_command_bar(dispatch, model)
}
