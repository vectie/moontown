///|
priv struct ProfessionalAttentionSummary {
  failed_count : Int
  review_count : Int
}

///|
fn professional_attention_summary(
  model : Model,
  executions : Array[@core.TaskExecutionRecord],
) -> ProfessionalAttentionSummary {
  let execution_summary = execution_count_summary(executions)
  let decisions = watcher_decision_summary(model)
  let live = live_autonomy_operator_view(model, fallback_active_workers=0)
  {
    failed_count: execution_summary.failed +
      decisions.failed_count +
      live.failed_template_request_count,
    review_count: execution_summary.review_queued + decisions.review_count,
  }
}

///|
fn professional_attention_has_failed(
  summary : ProfessionalAttentionSummary,
) -> Bool {
  summary.failed_count > 0
}

///|
fn professional_attention_has_review(
  summary : ProfessionalAttentionSummary,
) -> Bool {
  summary.review_count > 0
}
