///|
pub fn visual_projection_tick(state : @core.TownState) -> Int32 {
  let mut tick = state.events.length()
  for execution in state.executions {
    if execution.heartbeat_tick > tick {
      tick = execution.heartbeat_tick
    }
  }
  tick
}
