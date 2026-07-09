///|
test "watcher decision kind classifies known and unknown decisions" {
  assert_true(watcher_decision_kind("Update") is Update)
  assert_true(watcher_decision_kind("NeedsReview") is NeedsReview)
  assert_true(watcher_decision_kind("Failed") is Failed)
  assert_true(watcher_decision_kind("Deferred") is Deferred)
  assert_true(watcher_decision_kind("NoChange") is NoChange)
  assert_true(watcher_decision_kind("Unexpected") is Other)
}

///|
test "watcher decision text helpers detect embedded decision words" {
  assert_true(watcher_decision_text_mentions_failed("Watcher Failed at tick 4"))
  assert_true(
    watcher_decision_text_mentions_failed("worker failed with timeout"),
  )
  assert_true(!watcher_decision_text_mentions_failed("NoChange at tick 4"))
  assert_true(watcher_decision_text_mentions_no_change("NoChange at tick 4"))
  assert_true(!watcher_decision_text_mentions_no_change("Update at tick 4"))
}
