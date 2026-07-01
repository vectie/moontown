///|
fn render_moondesk_bridge_record(
  record : MoondeskBridgeRecord,
) -> @rabbita.Html {
  article(
    class="moondesk-bridge-record \{bridge_record_status_class(record.status)}",
    [
      div(class="handoff-artifact-heading", [
        span(class="handoff-kind", record.kind),
        span(class="handoff-status", record.status),
      ]),
      h3(record.title),
      p(record.summary),
      div(class="handoff-path-grid", [
        render_module_detail("Record", record.id),
        render_module_detail("Target", record.target),
        render_module_detail("Path", record.path),
      ]),
      span(class="bridge-record-time", record.created_at),
    ],
  )
}

///|
fn render_moondesk_bridge_panel(model : Model) -> @rabbita.Html {
  let records : Array[@rabbita.Html] = []
  for record in moondesk_bridge_records(model) {
    records.push(render_moondesk_bridge_record(record))
  }
  section(class="moondesk-bridge-panel", [
    div(class="viewport-panel-heading", [
      p(class="eyebrow", "Moondesk Bridge"),
      h2("Recent Portable Records"),
      p(
        "Real bridge records from `.moonsuite/products/moontown/moondesk-*` and `.moonsuite/products/moontown/book-results`. This is the evidence trail for work moving between Moondesk, MoonBook, MoonClaw, and Moontown.",
      ),
    ]),
    div(class="viewport-editor-stats", [
      render_module_detail("Bridge Records", "\{moondesk_record_count(model)}"),
      render_module_detail("Checkout", moondesk_root_status_label(model)),
      render_module_detail("Generated", moondesk_bridge_generated_at(model)),
    ]),
    div(
      class="moondesk-bridge-list",
      if records.is_empty() {
        [
          article(class="viewport-output-empty", [
            h2("No Bridge Records"),
            p(
              "No Moondesk dispatch, request, or book-result records were found yet.",
            ),
          ]),
        ]
      } else {
        records
      },
    ),
  ])
}
