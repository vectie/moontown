///|
pub fn render_state_dashboard(state : @core.TownState) -> String {
  let mayor = demo_mayor()
  let report = @health.inspect_town(state)
  let model = @ui.build_dashboard(state, report)
  let tick = @scheduler.next_tick(1, @scheduler.plan_tick(state, report))
  let snapshot = @storage.snapshot_of(state)
  let runtime = mayor.runtime()
  let mayor_block = "## Mayor\n- role: \{runtime.role_id}\n- mode: \{runtime.runtime_mode.to_string()}\n- tools: \{runtime.tool_access.to_string()}\n- scope: \{runtime.authority_scope}\n- proposal lifecycle records: \{state.executions.length()}\n\n"
  let recent_events = if state.events.is_empty() {
    "## Events\n- none\n\n"
  } else {
    let builder = StringBuilder::new()
    builder.write_string("## Events\n")
    for event in state.events {
      builder.write_string("- [\{event.kind}] \{event.detail}\n")
    }
    builder.write_string("\n")
    builder.to_string()
  }
  @ui.render_dashboard(model) +
  "\n" +
  mayor_block +
  recent_events +
  "Town Tick\n- \{tick.summary}\n\nSnapshot\n- \{@storage.describe_snapshot(snapshot)}\n"
}
