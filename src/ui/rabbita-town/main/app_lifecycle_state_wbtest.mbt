///|
test "viewport mode helper resets selection to overview" {
  let model = { ..init_model(), selection: Selection::Node("policy-hall") }
  let next = set_viewport_mode_model(model, ViewportMode::EditorMode)
  assert_true(next.viewport_mode == ViewportMode::EditorMode)
  assert_true(next.selection is Selection::Overview)
}
