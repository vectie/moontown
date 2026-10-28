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
            span(class="module-book-chip projection-tone-info", "业务记录"),
            span(
              class="module-civic-status",
              civic_surface_status(model, health.service_id),
            ),
          ]),
          p(
            class="module-book-summary",
            civic_surface_evidence(model, health.service_id),
          ),
          if health.latest_review_items > 0 {
            p(
              "有待审核内容，请查看对应任务；协议完成不代表业务结论已通过。",
            )
          } else {
            @html.nothing
          },
          render_advanced_details("业务协议与诊断", [
            p(
              if model.state_source == DemoSimulation {
                "以下为示例协议记录，不代表真实服务。"
              } else {
                "以下为已载入的记录，不是实时服务可用性证明。"
              },
            ),
            p(class="module-book-summary", civic_health_detail(health)),
            render_protocol_history_group(health),
          ]),
        ],
      )
    None =>
      article(class="module-civic-health module-status-unbound", [
        div(class="module-civic-health-head", [
          span(class="module-book-chip projection-tone-info", "业务记录"),
          span(class="module-civic-status", "未接入"),
        ]),
        p(
          class="module-book-summary",
          "尚未连接此业务的结果记录。",
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
