///|
fn live_autonomy_action_context_fixture(
  active_workers? : Int = 0,
  review? : Int = 0,
  blocked? : Int = 0,
  due_goals? : Int = 0,
  watcher_records? : Array[@core.WatcherRunRecord] = [],
  planbook_open? : Int = 0,
  planbook_repair_active? : Int = 0,
  pending_book_template_requests? : Int = 0,
  failed_book_template_requests? : Int = 0,
  transient_infrastructure_debt? : Int = 0,
) -> LiveAutonomyActionContext {
  {
    blockers: live_autonomy_blocker_context_fixture(
      active_workers~,
      review~,
      blocked~,
      due_goals~,
      planbook_open~,
      planbook_repair_active~,
      pending_book_template_requests~,
      failed_book_template_requests~,
    ),
    watcher_records,
    transient_infrastructure_debt,
  }
}

///|
fn live_autonomy_blocker_context_fixture(
  active_workers? : Int = 0,
  review? : Int = 0,
  blocked? : Int = 0,
  failed? : Int = 0,
  due_goals? : Int = 0,
  planbook_open? : Int = 0,
  planbook_repair_active? : Int = 0,
  pending_book_template_requests? : Int = 0,
  failed_book_template_requests? : Int = 0,
) -> LiveAutonomyBlockerContext {
  {
    active_workers,
    review,
    blocked,
    failed,
    due_goals,
    planbook_open,
    planbook_repair_active,
    pending_book_template_requests,
    failed_book_template_requests,
  }
}
