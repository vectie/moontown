///|
priv enum CivicHealthStatusKind {
  Complete
  Review
  Waiting
  Alert
  Projected
}

///|
fn civic_health_status_kind(status : String) -> CivicHealthStatusKind {
  match status {
    "changed" | "no-change" => Complete
    "needs-review" => Review
    "seeded" => Waiting
    "blocked" | "missing-workspace" | "incomplete" | "misconfigured" =>
      Alert
    _ => Projected
  }
}

///|
fn civic_health_status_class_for_kind(kind : CivicHealthStatusKind) -> String {
  match kind {
    Complete => "module-status-complete"
    Review => "module-status-review"
    Waiting => "module-status-waiting"
    Alert => "module-status-alert"
    Projected => "module-status-projected"
  }
}

///|
fn civic_health_status_class(status : String) -> String {
  civic_health_status_class_for_kind(civic_health_status_kind(status))
}

///|
fn civic_health_status_label(status : String) -> String {
  match status {
    "missing-workspace" => "Missing workspace"
    "needs-review" => "Needs review"
    "no-change" => "No change"
    "result-unknown" => "Result unknown"
    "misconfigured" => "Misconfigured"
    _ => status
  }
}

///|
fn civic_health_status_kind_is_blocked(kind : CivicHealthStatusKind) -> Bool {
  kind is Alert
}

///|
fn civic_health_detail(health : CivicServiceHealthSnapshot) -> String {
  [
    civic_health_identity_detail(health),
    civic_health_protocol_detail(health),
    civic_health_protocol_flow_detail(health),
    civic_health_decision_detail(health),
    "Latest protocol summary: \{civic_health_protocol_summary(health)}.",
    civic_health_notes_detail(health),
  ].join(" ")
}

///|
fn civic_health_identity_detail(health : CivicServiceHealthSnapshot) -> String {
  "\{health.title} (`\{health.service_id}`) is a \{health.service_kind} service backed by `\{health.book_id}`. Civic status: \{health.status}."
}

///|
fn civic_health_protocol_detail(health : CivicServiceHealthSnapshot) -> String {
  "Protocol: \{health.protocol_status}; mode: \{health.module_mode}; skill: \{health.skill_mode}; MoonBook role: \{health.book_role}."
}

///|
fn civic_health_protocol_flow_detail(
  health : CivicServiceHealthSnapshot,
) -> String {
  [
    "Protocol flow: in \{health.protocol_inbox_count},",
    "contributions \{health.protocol_contribution_count},",
    "reductions \{health.protocol_reduction_count},",
    "out \{health.protocol_outbox_count}.",
  ].join(" ")
}

///|
fn civic_health_decision_detail(health : CivicServiceHealthSnapshot) -> String {
  [
    "Decision: \{health.latest_decision};",
    "pages changed: \{health.latest_pages_changed};",
    "accepted facts: \{health.latest_accepted_facts};",
    "review items: \{health.latest_review_items}.",
  ].join(" ")
}

///|
fn civic_health_protocol_summary(health : CivicServiceHealthSnapshot) -> String {
  if health.latest_protocol_summary.is_empty() {
    "no protocol summary yet"
  } else {
    health.latest_protocol_summary
  }
}

///|
fn civic_health_notes_detail(health : CivicServiceHealthSnapshot) -> String {
  if health.notes.is_empty() {
    "no detailed notes"
  } else {
    health.notes.join("; ")
  }
}

///|
fn civic_status_summary(model : Model) -> String {
  match model.civic_status {
    Some(status) =>
      civic_status_summary_from_portfolio(model.civic_status_version, status)
    None => "not loaded"
  }
}

///|
fn civic_status_summary_from_portfolio(
  version : Int,
  status : CivicServicePortfolioSnapshot,
) -> String {
  let protocol_counts = civic_protocol_summary_counts(status.services)
  [
    civic_status_operability_summary(version, status, protocol_counts),
    civic_status_portfolio_summary(status),
  ].join(" ")
}

///|
priv struct CivicProtocolSummaryCounts {
  ready_count : Int
  review_count : Int
}

///|
fn civic_protocol_summary_counts(
  services : Array[CivicServiceHealthSnapshot],
) -> CivicProtocolSummaryCounts {
  let mut ready_count = 0
  let mut review_count = 0
  for service in services {
    if service.protocol_ready {
      ready_count += 1
    }
    review_count += service.protocol_review_count
  }
  { ready_count, review_count }
}

///|
fn civic_status_operability_summary(
  version : Int,
  status : CivicServicePortfolioSnapshot,
  protocol_counts : CivicProtocolSummaryCounts,
) -> String {
  [
    "v\{version}: \{status.operable_count}/\{status.total} operable,",
    "\{status.proven_count} service-result proof,",
    "\{protocol_counts.ready_count} protocol-active,",
    "\{protocol_counts.review_count} review gates.",
  ].join(" ")
}

///|
fn civic_status_portfolio_summary(
  status : CivicServicePortfolioSnapshot,
) -> String {
  [
    "Portfolio:",
    "seeded \{status.seeded_count},",
    "missing \{status.missing_count},",
    "review \{status.review_count},",
    "blocked \{status.blocked_count},",
    "changed \{status.changed_count},",
    "no-change \{status.no_change_count}.",
  ].join(" ")
}
