///|
fn runtime_counts_fixture(
  running? : Int = 0,
  waiting? : Int = 0,
  review? : Int = 0,
  blocked? : Int = 0,
  completed? : Int = 0,
) -> ModuleRuntimeCounts {
  module_runtime_counts(running~, waiting~, review~, blocked~, completed~)
}

///|
fn visual_module_fixture(
  status? : String = "",
  running_count? : Int = 0,
  waiting_count? : Int = 0,
  review_count? : Int = 0,
  blocked_count? : Int = 0,
  completed_count? : Int = 0,
) -> VisualModuleSnapshot {
  {
    module_id: "module",
    book_id: "book",
    status,
    source: "runtime",
    running_count,
    waiting_count,
    review_count,
    blocked_count,
    completed_count,
    active_agent_count: 0,
    message: "test",
  }
}

///|
fn visual_building_fixture(
  running_count? : Int = 0,
  waiting_count? : Int = 0,
  review_count? : Int = 0,
  blocked_count? : Int = 0,
  completed_count? : Int = 0,
) -> VisualBuildingSnapshot {
  {
    book_id: "book",
    title: "Building",
    zone_key: "zone",
    running_count,
    waiting_count,
    review_count,
    blocked_count,
    completed_count,
    effect: "",
    message: "test",
  }
}

///|
test "module runtime status counts preserve priority order" {
  assert_true(
    module_runtime_status_kind_from_counts(
      runtime_counts_fixture(blocked=1, review=1, running=1),
    )
    is Alert,
  )
  assert_true(
    module_runtime_status_kind_from_counts(runtime_counts_fixture(review=1))
    is Review,
  )
  assert_true(
    module_runtime_status_kind_from_counts(runtime_counts_fixture(running=1))
    is Running,
  )
  assert_true(
    module_runtime_status_kind_from_counts(runtime_counts_fixture(waiting=1))
    is Waiting,
  )
  assert_true(
    module_runtime_status_kind_from_counts(runtime_counts_fixture(completed=1))
    is Complete,
  )
  assert_true(
    module_runtime_status_kind_from_counts(runtime_counts_fixture())
    is Projected,
  )
  assert_eq(
    module_runtime_status_class_from_counts(
      runtime_counts_fixture(blocked=1, review=1, running=1),
    ),
    "module-status-alert",
  )
  assert_eq(
    module_runtime_status_label_from_counts(
      runtime_counts_fixture(review=1, running=1, completed=1),
    ),
    "Review",
  )
  assert_eq(
    module_runtime_status_class_from_counts(runtime_counts_fixture(running=1)),
    "module-status-running",
  )
  assert_eq(
    module_runtime_status_label_from_counts(runtime_counts_fixture(waiting=1)),
    "Waiting",
  )
  assert_eq(
    module_runtime_status_class_from_counts(runtime_counts_fixture(completed=1)),
    "module-status-complete",
  )
  assert_eq(
    module_runtime_status_label_from_counts(runtime_counts_fixture()),
    "Projected",
  )
}

///|
test "module runtime status kind owns class label and count rendering" {
  assert_eq(module_runtime_status_class(Alert), "module-status-alert")
  assert_eq(module_runtime_status_label(Review), "Review")
  assert_eq(module_runtime_status_count(Running, Running), 1)
  assert_eq(module_runtime_status_count(Running, Review), 0)
  assert_eq(module_runtime_status_class(Complete), "module-status-complete")
}

///|
test "module runtime counts can be projected from a status kind" {
  let empty = module_runtime_counts()
  assert_eq(empty.running, 0)
  assert_eq(empty.waiting, 0)
  assert_eq(empty.review, 0)
  assert_eq(empty.blocked, 0)
  assert_eq(empty.completed, 0)
  let review = module_runtime_counts(review=3)
  assert_eq(review.running, 0)
  assert_eq(review.review, 3)
  let running = module_runtime_counts_from_status_kind(Running)
  assert_eq(running.running, 1)
  assert_eq(running.waiting, 0)
  assert_eq(running.review, 0)
  assert_eq(running.blocked, 0)
  assert_eq(running.completed, 0)
  let alert = module_runtime_counts_from_status_kind(Alert)
  assert_eq(alert.running, 0)
  assert_eq(alert.blocked, 1)
}

///|
test "module projection status uses explicit status before count fallback" {
  assert_true(
    module_projection_status_kind(visual_module_fixture(status="running"))
    is Running,
  )
  assert_true(
    module_projection_status_kind(
      visual_module_fixture(status="unknown", blocked_count=1),
    )
    is Alert,
  )
  assert_eq(
    module_projection_status_class(visual_module_fixture(status="running")),
    "module-status-running",
  )
  assert_eq(
    module_projection_status_class(
      visual_module_fixture(status="unknown", blocked_count=1),
    ),
    "module-status-alert",
  )
  assert_eq(
    module_projection_status_label(visual_module_fixture(status="review")),
    "Review",
  )
}

///|
test "building status class and label share runtime count priority" {
  let building = visual_building_fixture(review_count=1, running_count=1)
  assert_eq(module_building_status_class(building), "module-status-review")
  assert_eq(module_building_status_label(building), "Review")
}
