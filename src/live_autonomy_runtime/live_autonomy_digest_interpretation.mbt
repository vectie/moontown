///|
fn live_autonomy_digest_interpretation(spine : LiveAutonomySpine) -> String {
  if spine.blocked_count > 0 || spine.failed_count > 0 {
    "Mayor should recover live blockers before dispatching more work. Historical watcher failures are not counted here unless they remain unresolved."
  } else if spine.failed_book_template_request_count > 0 {
    "The town has failed book-template requests. Mayor should surface the request and config errors before accepting more Moondesk book creation work."
  } else if spine.pending_book_template_request_count > 0 {
    "The town has pending book-template requests from Moondesk or operators. The next daemon tick should process them into real MoonBook workspaces."
  } else if spine.review_count > 0 {
    "The town is healthy and watching with a visible review queue. Review-gated output is not counted as progress until promoted, but it no longer blocks the live loop."
  } else if spine.active_worker_count > 0 {
    "The town is actively working. Buildings and agents should show motion until the running work closes."
  } else if spine.due_goal_count > 0 {
    "The town is ready to dispatch due standing watches on the next daemon tick."
  } else if spine.transient_infrastructure_debt_count > 0 {
    "The town is healthy and watching. Historical transient infrastructure debt is visible for accounting, but it is not counted as domain progress or unresolved failure."
  } else if spine.stable_waiting {
    "The town is in stable waiting: no active work, review debt, due standing goal, PlanBook gap, or template request is blocking autonomous operation."
  } else {
    "The town is healthy and watching. No-change cycles are operational diligence, not domain progress."
  }
}
