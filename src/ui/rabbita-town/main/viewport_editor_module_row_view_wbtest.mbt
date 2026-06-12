///|
test "editor module issue text summarizes clean and invalid modules" {
  assert_eq(editor_module_issue_text([]), "placement clean")
  assert_eq(
    editor_module_issue_text(["missing book_id", "invalid footprint"]),
    "missing book_id, invalid footprint",
  )
}

///|
test "editor module projection status separates bound and missing outputs" {
  assert_eq(editor_module_projection_status(None), "Missing MoonBook output")
}

///|
fn editor_module_row_test_module() -> WenyuTownModule {
  {
    id: "test-module",
    enabled: true,
    title: "Test Module",
    book_id: "test-book",
    district: "test district",
    building_kind: "test-building",
    grid_x: 20,
    grid_y: 20,
    footprint_w: 2,
    footprint_h: 2,
    display_w: 160,
    display_h: 120,
    entrance_x: 21,
    entrance_y: 22,
    interior_kind: "office",
    style_family: "white-tech",
    asset_base: "test-base",
    asset_roof: "test-roof",
    protocol_pattern: "research-salon",
    use_case: "Test use case",
    agent_flow: "Agents visit, exchange, and return.",
    summary: "A deterministic test module.",
  }
}

///|
test "editor module row view exposes render-ready module fields" {
  let model = init_model()
  let civic = editor_module_row_test_module()
  let view = editor_module_row_view(model, civic, [])
  assert_eq(view.title, civic.title)
  assert_eq(view.identity, "\{civic.id} / \{civic.book_id}")
  assert_true(view.placement.contains("->"))
  assert_true(view.style.contains("/"))
  assert_true(!view.runtime_label.is_empty())
  assert_true(!view.runtime_class.is_empty())
  assert_true(!view.projection_status.is_empty())
  assert_true(!view.issue_text.is_empty())
}
