///|
fn input_channels_for_service(
  service : CivicServiceDefinition,
) -> Array[String] {
  match service.id {
    "social-square" =>
      ["resident_request", "profile_projection", "event_signal"]
    "policy-hall" =>
      ["resident_question", "official_source", "eligibility_context"]
    "contest-express" => ["contest_call", "team_profile", "submission_draft"]
    "vitality-dashboard" =>
      ["daemon_event", "watcher_record", "worker_status", "projection_signal"]
    "physical-bridge" =>
      ["handoff_request", "venue_constraint", "operator_confirmation"]
    "valley-market" => ["offer", "need", "points_event", "abuse_signal"]
    "broadcast-tower" => ["achievement_signal", "event_record", "approved_fact"]
    _ => ["module_request", "book_signal", "worker_result"]
  }
}

///|
fn output_channels_for_service(
  service : CivicServiceDefinition,
) -> Array[String] {
  match service.id {
    "social-square" =>
      ["consent_request", "match_candidate", "event_plan", "review_item"]
    "policy-hall" =>
      ["cited_checklist", "eligibility_answer", "uncertainty_review"]
    "contest-express" =>
      ["readiness_plan", "mock_judge_feedback", "revision_queue"]
    "vitality-dashboard" =>
      ["health_digest", "recovery_item", "false_progress_note"]
    "physical-bridge" => ["handoff_packet", "confirmation_request", "blocker"]
    "valley-market" => ["ledger_update", "redemption_review", "abuse_review"]
    "broadcast-tower" => ["story_draft", "redaction_task", "public_highlight"]
    _ => ["module_result", "review_item", "projection_update"]
  }
}
