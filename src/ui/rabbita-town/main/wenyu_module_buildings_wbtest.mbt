///|
fn wenyu_module_building_test_module() -> WenyuTownModule {
  {
    id: "policy-hall",
    enabled: true,
    title: "Policy Hall",
    book_id: "policy-hall",
    district: "north",
    building_kind: "pavilion",
    grid_x: 10,
    grid_y: 12,
    footprint_w: 3,
    footprint_h: 4,
    display_w: 180,
    display_h: 160,
    entrance_x: 10,
    entrance_y: 13,
    interior_kind: "hall",
    style_family: "white-tech",
    asset_base: "base.png",
    asset_roof: "roof.png",
    protocol_pattern: "research-salon",
    use_case: "policy triage",
    agent_flow: "in / exchange / out",
    summary: "test civic module",
  }
}

///|
fn wenyu_module_building_test_runtime(
  issue_count? : Int = 0,
) -> WenyuModuleRuntimeState {
  {
    status_class: "module-status-running",
    status_label: "Running",
    source_label: "runtime",
    detail: "test runtime",
    running_count: 1,
    waiting_count: 0,
    review_count: 0,
    blocked_count: 0,
    completed_count: 0,
    visible_agent_count: 2,
    issue_count,
  }
}

///|
test "wenyu module building selection policy follows selected node key" {
  let civic = wenyu_module_building_test_module()
  assert_true(wenyu_module_building_selected(civic, Some("policy-hall")))
  assert_true(!wenyu_module_building_selected(civic, Some("ai-garden")))
  assert_true(!wenyu_module_building_selected(civic, None))
}

///|
test "wenyu module building issue policy follows runtime issue count" {
  assert_true(
    !wenyu_module_building_has_issues(wenyu_module_building_test_runtime()),
  )
  assert_true(
    wenyu_module_building_has_issues(
      wenyu_module_building_test_runtime(issue_count=2),
    ),
  )
}

///|
test "wenyu module building class centralizes selected and issue suffixes" {
  let civic = wenyu_module_building_test_module()
  assert_eq(
    wenyu_module_building_class(
      civic,
      wenyu_module_building_test_runtime(),
      None,
    ),
    "wenyu-module-building wenyu-module-pavilion style-white-tech module-status-running",
  )
  assert_eq(
    wenyu_module_building_class(
      civic,
      wenyu_module_building_test_runtime(issue_count=2),
      Some("policy-hall"),
    ),
    "wenyu-module-building wenyu-module-pavilion style-white-tech module-status-running selected has-issues",
  )
}
