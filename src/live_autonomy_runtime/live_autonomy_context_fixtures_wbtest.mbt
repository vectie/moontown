///|
fn live_autonomy_action_context_fixture(
  active_workers~ : Int32 = 0,
  review~ : Int32 = 0,
  blocked~ : Int32 = 0,
  due_goals~ : Int32 = 0,
  watcher_records~ : Array[@core.WatcherRunRecord] = [],
  planbook_open~ : Int32 = 0,
  planbook_repair_active~ : Int32 = 0,
  pending_book_template_requests~ : Int32 = 0,
  failed_book_template_requests~ : Int32 = 0,
  transient_infrastructure_debt~ : Int32 = 0,
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
    latest_watcher_decision: live_autonomy_latest_watcher_decision(
      watcher_records,
    ),
    transient_infrastructure_debt,
  }
}

///|
fn live_autonomy_blocker_context_fixture(
  active_workers~ : Int32 = 0,
  review~ : Int32 = 0,
  blocked~ : Int32 = 0,
  failed~ : Int32 = 0,
  due_goals~ : Int32 = 0,
  planbook_open~ : Int32 = 0,
  planbook_repair_active~ : Int32 = 0,
  pending_book_template_requests~ : Int32 = 0,
  failed_book_template_requests~ : Int32 = 0,
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
