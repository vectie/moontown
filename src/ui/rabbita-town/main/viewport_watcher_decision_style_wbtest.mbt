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
test "watcher decision failed predicate only matches failed decision" {
  assert_true(watcher_decision_is_failed("Failed"))
  assert_true(!watcher_decision_is_failed("Update"))
  assert_true(!watcher_decision_is_failed("Unexpected"))
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

///|
test "watcher decision chip class maps known decisions and defaults unknown" {
  assert_eq(watcher_decision_chip_class("Update"), "chip-live")
  assert_eq(watcher_decision_chip_class("NeedsReview"), "chip-book")
  assert_eq(watcher_decision_chip_class("Failed"), "chip-alert")
  assert_eq(watcher_decision_chip_class("Deferred"), "chip-neutral")
  assert_eq(watcher_decision_chip_class("NoChange"), "chip-calm")
  assert_eq(watcher_decision_chip_class("Unexpected"), "chip-neutral")
}

///|
test "watcher decision class composes base class with decision suffix" {
  assert_eq(
    watcher_decision_class("watch-goal-card", "Update"),
    "watch-goal-card watch-decision-Update",
  )
  assert_eq(
    watcher_decision_class("watch-timeline-item", "NoChange"),
    "watch-timeline-item watch-decision-NoChange",
  )
}
