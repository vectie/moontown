///|
test "dashboard section helper changes only the ecosystem focus" {
  let model = { ..init_model(), selection: Selection::Node("policy-hall") }
  let next = set_dashboard_section_model(
    model,
    DashboardSection::SocialCapitalSection,
  )
  assert_true(next.dashboard_section is Some(SocialCapitalSection))
  assert_true(next.selection is Selection::Node(_))
}

///|
test "dashboard section helper closes an active ecosystem focus" {
  let model = {
    ..init_model(),
    dashboard_section: Some(DashboardSection::SocialCapitalSection),
  }
  let next = set_dashboard_section_model(
    model,
    DashboardSection::SocialCapitalSection,
  )
  assert_true(next.dashboard_section is None)
}

///|
test "request composer helper changes only the request focus" {
  let model = { ..init_model(), selection: Selection::Worker("worker-1") }
  let next = set_request_composer_model(
    model,
    RequestComposerFocus::EvidenceBookComposer,
  )
  assert_true(
    next.request_composer == RequestComposerFocus::EvidenceBookComposer,
  )
  assert_true(next.selection is Selection::Worker(_))
}

///|
test "reset navigation requires a verified durable shard" {
  let navigations : Array[Bool] = []
  let navigate = fn(regenerate : Bool) { navigations.push(regenerate) }
  let model = { ..init_model(), tick: 37, energy_toast: "" }
  let (_, failed_reset) = energy_reset_after_persistence(
    model, false, false, navigate,
  )
  let (_, failed_regenerate) = energy_reset_after_persistence(
    model, false, true, navigate,
  )
  assert_true(navigations.is_empty())
  assert_eq(failed_reset.tick, 37)
  assert_eq(failed_regenerate.tick, 37)
  assert_true(failed_reset.energy_toast.contains("保存失败"))
  assert_true(failed_regenerate.energy_toast.contains("保存失败"))
  ignore(energy_reset_after_persistence(model, true, false, navigate))
  ignore(energy_reset_after_persistence(model, true, true, navigate))
  assert_eq(navigations, [false, true])
}
