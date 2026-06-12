///|
fn write_live_autonomy_digest_tail(
  builder : StringBuilder,
  state : @core.TownState,
  spine : LiveAutonomySpine,
) -> Unit {
  builder.write_string("## Latest Watcher Signal\n\n")
  builder.write_string("\{spine.latest_watcher_summary}\n\n")
  builder.write_string("## Latest PlanBook Change\n\n")
  builder.write_string("\{spine.latest_change_summary}\n\n")
  builder.write_string("## Next Actions\n\n")
  if spine.next_actions.is_empty() {
    builder.write_string("- none\n")
  } else {
    for action in spine.next_actions {
      builder.write_string("- \{action}\n")
    }
  }
  builder.write_string("\n## Recent Town Events\n\n")
  let recent_events = recent_live_events(state, 6)
  if recent_events.is_empty() {
    builder.write_string("- no recent events\n")
  } else {
    for event in recent_events {
      builder.write_string(
        "- `\{event.kind}`: \{@civic_runtime.normalize_civic_pending_summary(event.detail)}\n",
      )
    }
  }
}
