///|
fn render_civic_context(model : Model) -> @rabbita.Html {
  section(class="civic-context", [
    status_chip("Time \{real_time_label()}", "chip-clock"),
    status_chip("Phase \{real_phase_label()}", "chip-clock"),
    status_chip(daemon_cadence_label(model), "chip-neutral"),
    status_chip("Residents: \{resident_count(model)}", "chip-neutral"),
  ])
}
