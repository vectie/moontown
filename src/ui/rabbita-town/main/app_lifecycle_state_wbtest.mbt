///|
test "viewport mode helper resets selection to overview" {
  let model = { ..init_model(), selection: Selection::Node("policy-hall") }
  let next = set_viewport_mode_model(model, ViewportMode::EditorMode)
  assert_true(next.viewport_mode == ViewportMode::EditorMode)
  assert_true(next.selection is Selection::Overview)
}

///|
test "dashboard section helper changes only the ecosystem focus" {
  let model = { ..init_model(), selection: Selection::Node("policy-hall") }
  let next = set_dashboard_section_model(
    model,
    DashboardSection::SocialCapitalSection,
  )
  assert_true(next.dashboard_section == DashboardSection::SocialCapitalSection)
  assert_true(next.selection is Selection::Node(_))
}

///|
test "request composer helper changes only the request focus" {
  let model = { ..init_model(), selection: Selection::Worker("worker-1") }
  let next = set_request_composer_model(
    model,
    RequestComposerFocus::EvidenceBookComposer,
  )
  assert_true(next.request_composer == RequestComposerFocus::EvidenceBookComposer)
  assert_true(next.selection is Selection::Worker(_))
}
