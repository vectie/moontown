///|
fn render_module_civic_health(
  model : Model,
  civic : WenyuTownModule,
) -> @rabbita.Html {
  match find_module_civic_health(model, civic) {
    Some(health) =>
      article(
        class="module-civic-health \{civic_health_status_class(health.status)}",
        [
          div(class="module-civic-health-head", [
            span(class="module-book-chip projection-tone-info", "Civic Doctor"),
            span(
              class="module-civic-status",
              civic_health_status_label(health.status),
            ),
          ]),
          p(class="module-book-summary", civic_health_detail(health)),
          render_protocol_history_group(health),
          div(class="module-book-metric-grid", [
            render_projection_metric({
              label: "Operable",
              value: if health.operable {
                "yes"
              } else {
                "no"
              },
              note: "\{health.missing_required_paths.length()} missing paths",
              tone: if health.operable {
                "healthy"
              } else {
                "alert"
              },
            }),
            render_projection_metric({
              label: "Result Proof",
              value: if health.proven_by_result {
                "present"
              } else {
                "missing"
              },
              note: health.latest_decision,
              tone: if health.proven_by_result {
                "healthy"
              } else {
                "review"
              },
            }),
            render_projection_metric({
              label: "Mode",
              value: health.module_mode,
              note: health.skill_mode,
              tone: "info",
            }),
            render_projection_metric({
              label: "Protocol",
              value: health.protocol_status,
              note: "in \{health.protocol_inbox_count} / red \{health.protocol_reduction_count} / out \{health.protocol_outbox_count}",
              tone: if health.protocol_ready {
                "healthy"
              } else {
                "review"
              },
            }),
            render_projection_metric({
              label: "Review",
              value: "\{health.latest_review_items}",
              note: "items",
              tone: if health.latest_review_items > 0 {
                "review"
              } else {
                "info"
              },
            }),
          ]),
        ],
      )
    None =>
      article(class="module-civic-health module-status-unbound", [
        div(class="module-civic-health-head", [
          span(class="module-book-chip projection-tone-alert", "Civic Doctor"),
          span(class="module-civic-status", "No status"),
        ]),
        p(
          class="module-book-summary",
          "No civic status file was loaded. Run `moon run src/cmd/main -- civic doctor` to publish \{moontown_product_display_artifact_code("civic/status.json")}.",
        ),
      ])
  }
}

///|
fn render_protocol_history_group(
  health : CivicServiceHealthSnapshot,
) -> @rabbita.Html {
  let children : Array[@rabbita.Html] = [h3("Protocol History")]
  let history = match health.protocol_history {
    Some(entries) => entries
    None => []
  }
  let history_state = health.protocol_history_state.unwrap_or("missing")
  if !history.is_empty() {
    for entry in history {
      children.push(render_protocol_history_entry(entry))
    }
  } else if history_state == "no-events-yet" {
    children.push(
      p(
        class="module-book-empty",
        "No protocol events yet. This building has a durable protocol definition, but no inbox, reduction, review, accepted result, or outbox record has been written yet.",
      ),
    )
  } else {
    children.push(
      p(
        class="module-book-empty",
        "Protocol history is missing or invalid for the current pipeline state. Inspect the building ledger files and rerun `moon run src/cmd/main -- civic doctor`.",
      ),
    )
  }
  div(class="module-book-group", children)
}

///|
fn render_protocol_history_entry(
  entry : ProtocolHistoryEntrySnapshot,
) -> @rabbita.Html {
  article(class="module-book-item module-book-item-protocol-history", [
    h3(entry_label(entry)),
    p(entry.detail),
    span("\{entry.title} / \{entry.evidence_ref}"),
  ])
}

///|
fn entry_label(entry : ProtocolHistoryEntrySnapshot) -> String {
  "\{entry.step} / \{entry.status}"
}
