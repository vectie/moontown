///|
/// A reserved source-bound task whose dispatch acknowledgement is unknown must
/// reconcile its original receipt before the ordinary retry lifecycle can run.
/// This is an execution-state marker, not a permission or review decision.
///
/// ```mbt check
/// test {
///   assert_eq(
///     unconfirmed_standing_watch_decision(),
///     "standing-watch-dispatch-unconfirmed",
///   )
/// }
/// ```
pub fn unconfirmed_standing_watch_decision() -> String {
  "standing-watch-dispatch-unconfirmed"
}

///|
pub fn unconfirmed_standing_watch_dispatch(
  execution : TaskExecutionRecord,
) -> Bool {
  execution.run_id is None &&
  execution.result_decision == unconfirmed_standing_watch_decision()
}
