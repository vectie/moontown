///|
fn render_civic_context(model : Model) -> @rabbita.Html {
  section(class="civic-context", [
    status_chip("Local time: \{real_time_label()}", "chip-clock"),
    status_chip("Date: \{real_calendar_label()}", "chip-book"),
    status_chip("Phase: \{real_phase_label()}", "chip-clock"),
    status_chip(daemon_cadence_label(model), "chip-neutral"),
    status_chip("Residents: \{resident_count(model)}", "chip-neutral"),
    status_chip(
      "Points flow: \{valley_points_issued(model)} issued / \{valley_points_redeemed(model)} redeemed",
      "chip-book",
    ),
    status_chip(
      "Broadcasts: \{achievement_broadcast_count(model)}",
      "chip-live",
    ),
    status_chip(
      "Response: \{service_response_minutes(model)} min",
      "chip-neutral",
    ),
    status_chip("Agent actions: \{agent_action_count(model)}", "chip-book"),
    status_chip("Return: \{retention_signal(model)}%", "chip-neutral"),
    status_chip("Robot calls: \{robot_service_count(model)}", "chip-neutral"),
  ])
}
