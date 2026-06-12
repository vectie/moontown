///|
priv struct CivicServiceStatusRule {
  bucket : String
  statuses : Array[String]
}

///|
pub fn civic_service_status_is_seeded(status : String) -> Bool {
  civic_service_status_bucket(status) == "seeded"
}

///|
pub fn civic_service_status_is_missing_or_incomplete(status : String) -> Bool {
  civic_service_status_bucket(status) == "missing-or-incomplete"
}

///|
pub fn civic_service_status_is_review(status : String) -> Bool {
  civic_service_status_bucket(status) == "review"
}

///|
pub fn civic_service_status_is_blocked(status : String) -> Bool {
  civic_service_status_bucket(status) == "blocked"
}

///|
pub fn civic_service_status_is_changed(status : String) -> Bool {
  civic_service_status_bucket(status) == "changed"
}

///|
pub fn civic_service_status_is_no_change(status : String) -> Bool {
  civic_service_status_bucket(status) == "no-change"
}

///|
pub fn civic_service_status_bucket(status : String) -> String {
  for rule in civic_service_status_rules() {
    if rule.statuses.contains(status) {
      return rule.bucket
    }
  }
  "other"
}

///|
fn civic_service_status_rules() -> Array[CivicServiceStatusRule] {
  [
    { bucket: "seeded", statuses: ["seeded"] },
    {
      bucket: "missing-or-incomplete",
      statuses: ["missing-workspace", "incomplete", "misconfigured"],
    },
    { bucket: "review", statuses: ["needs-review"] },
    { bucket: "blocked", statuses: ["blocked"] },
    { bucket: "changed", statuses: ["changed"] },
    { bucket: "no-change", statuses: ["no-change"] },
  ]
}

///|
pub fn civic_service_status_label(
  workspace_exists~ : Bool,
  missing_required_paths~ : Array[String],
  skill_ready~ : Bool,
  moonclaw_profile_ready~ : Bool,
  latest_result_found~ : Bool,
  latest_decision~ : String,
  latest_review_items~ : Int,
) -> String {
  if !workspace_exists {
    "missing-workspace"
  } else if !skill_ready || !moonclaw_profile_ready {
    "misconfigured"
  } else if !missing_required_paths.is_empty() {
    "incomplete"
  } else if !latest_result_found {
    "seeded"
  } else {
    match latest_decision {
      "update" if latest_review_items > 0 => "needs-review"
      "update" => "changed"
      "no_change" => "no-change"
      "needs_review" => "needs-review"
      "blocked" => "blocked"
      _ => "result-unknown"
    }
  }
}

///|
pub fn civic_service_result_is_proven(decision : String) -> Bool {
  decision == "update" || decision == "no_change" || decision == "needs_review"
}

///|
pub fn civic_health_notes(
  operable~ : Bool,
  status~ : String,
  missing_required_paths~ : Array[String],
  latest_decision~ : String,
  latest_review_items~ : Int,
) -> Array[String] {
  let notes : Array[String] = []
  if operable {
    notes.push("workspace is operable")
  } else {
    notes.push("workspace is not yet fully operable")
  }
  if !missing_required_paths.is_empty() {
    notes.push("\{missing_required_paths.length()} required path(s) missing")
  }
  match civic_status_note(status, latest_decision, latest_review_items) {
    Some(note) => notes.push(note)
    None => ()
  }
  notes
}

///|
pub fn civic_status_note(
  status : String,
  latest_decision : String,
  latest_review_items : Int,
) -> String? {
  match status {
    "seeded" =>
      Some("no civic service result has been accepted into this book yet")
    "needs-review" =>
      Some(
        "\{latest_review_items} review item(s) require keeper/operator judgment",
      )
    "blocked" => Some("latest service run reported a blocker")
    "changed" => Some("latest service run reported an accepted update")
    "no-change" =>
      Some("latest service run checked the module and found no material change")
    _ =>
      if latest_decision != "none" {
        Some("latest decision is `\{latest_decision}`")
      } else {
        None
      }
  }
}

///|
pub fn protocol_status_is_ready(status : String) -> Bool {
  status == "reduced" || status == "review"
}

///|
pub fn protocol_status_label(
  inbox_count~ : Int,
  contribution_count~ : Int,
  reduction_count~ : Int,
  outbox_count~ : Int,
  review_count~ : Int,
) -> String {
  if review_count > 0 {
    "review"
  } else if reduction_count > 0 && outbox_count > 0 {
    "reduced"
  } else if reduction_count > 0 {
    "reducing"
  } else if contribution_count > 0 {
    "aggregating"
  } else if inbox_count > 0 {
    "inbox"
  } else {
    "defined"
  }
}
