///|
fn recent_live_events(
  state : @core.TownState,
  limit : Int,
) -> Array[@core.TownEvent] {
  let events : Array[@core.TownEvent] = []
  let mut index = state.events.length() - 1
  while index >= 0 && events.length() < limit {
    events.push(state.events[index])
    index -= 1
  }
  events
}
