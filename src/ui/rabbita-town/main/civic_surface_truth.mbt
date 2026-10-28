///|
/// Business claims come from retained civic records, never animation ticks or
/// a worker's completion percentage. A protocol record is not a service verdict.
fn civic_surface_health(
  model : Model,
  service_id : String,
) -> CivicServiceHealthSnapshot? {
  guard model.civic_status is Some(portfolio) else { return None }
  portfolio.services
  .iter()
  .find_first(health => {
    normalize_module_binding_key(health.service_id) ==
    normalize_module_binding_key(service_id)
  })
}

///|
fn civic_surface_unbound_label(model : Model) -> String {
  if model.state_source == DemoSimulation {
    "示例"
  } else {
    "未接入"
  }
}

///|
fn civic_surface_record_status(health : CivicServiceHealthSnapshot) -> String {
  if health.latest_review_items > 0 || health.status == "needs-review" {
    "待审核"
  } else if !health.operable || health.status == "blocked" {
    "待处理"
  } else if health.proven_by_result {
    "有结果记录"
  } else {
    "尚无结果"
  }
}

///|
fn civic_surface_status(model : Model, service_id : String) -> String {
  match civic_surface_health(model, service_id) {
    Some(health) =>
      if model.state_source == DemoSimulation {
        "示例 · \{civic_surface_record_status(health)}"
      } else {
        "记录 · \{civic_surface_record_status(health)}"
      }
    None => civic_surface_unbound_label(model)
  }
}

///|
fn civic_surface_evidence(model : Model, service_id : String) -> String {
  if model.state_source == DemoSimulation {
    return "示例资料 · 不代表真实业务证据"
  }
  match civic_surface_health(model, service_id) {
    Some(health) if health.latest_accepted_facts > 0 =>
      "记录中已审核事实 \{health.latest_accepted_facts} 条"
    Some(health) if health.latest_review_items > 0 =>
      "待审核 \{health.latest_review_items} 项"
    _ => "尚无已审核证据"
  }
}

///|
fn civic_surface_diagnostics(
  model : Model,
  service_id : String,
) -> Array[@rabbita.Html] {
  match civic_surface_health(model, service_id) {
    Some(health) =>
      [
        p(
          if model.state_source == DemoSimulation {
            "来源：示例业务记录；以下计数不是实际服务或设备数据。"
          } else {
            "来源：已载入的业务状态记录；不是实时设备或服务成功证明。"
          },
        ),
        render_module_detail_grid([
          render_module_detail(
            "协议输入",
            health.protocol_inbox_count.to_string(),
          ),
          render_module_detail(
            "协议输出",
            health.protocol_outbox_count.to_string(),
          ),
          render_module_detail(
            "待审核",
            health.latest_review_items.to_string(),
          ),
          render_module_detail(
            "已审核事实",
            health.latest_accepted_facts.to_string(),
          ),
        ]),
      ]
    None => []
  }
}

///|
fn render_civic_service_card(
  model : Model,
  service_id : String,
  title : String,
  copy : String,
  next_action : String,
  details~ : Array[@rabbita.Html] = [],
) -> @rabbita.Html {
  render_civic_module_card_shell({
    title,
    copy,
    next_action,
    signal: civic_surface_status(model, service_id),
    details,
    diagnostics: civic_surface_diagnostics(model, service_id),
    card_class: civic_module_card_class(),
  })
}
