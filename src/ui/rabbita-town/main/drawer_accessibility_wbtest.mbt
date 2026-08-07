///|
test "resident and town-today drawers expose stable non-modal relationships" {
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  let resident_model = resident_explorer_test_model()
  let directory_html = @rabbita.render_to_string(
    @rabbita.static_cell(render_resident_explorer(dispatch, resident_model)),
  )
  assert_true(directory_html.contains("id=\"resident-explorer-panel\""))
  assert_true(directory_html.contains("aria-modal=\"false\""))
  assert_true(
    directory_html.contains("aria-controls=\"resident-profile-panel\""),
  )

  let profile_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_selected_resident_profile(dispatch, {
        ..resident_model,
        selection: Agent("agent-moon"),
      }),
    ),
  )
  assert_true(profile_html.contains("id=\"resident-profile-panel\""))
  assert_true(profile_html.contains("role=\"dialog\""))
  assert_true(profile_html.contains("aria-modal=\"false\""))
  assert_true(
    profile_html.contains("aria-labelledby=\"resident-profile-title\""),
  )

  let chronicle_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_town_chronicle(dispatch, {
        ..init_model(),
        town_chronicle_open: true,
      }),
    ),
  )
  assert_true(chronicle_html.contains("id=\"town-chronicle-panel\""))
  assert_true(chronicle_html.contains("aria-modal=\"false\""))

  let rail_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_town_action_rail(dispatch, init_model(), false, 7),
    ),
  )
  assert_true(rail_html.contains("aria-controls=\"resident-explorer-panel\""))
  assert_true(rail_html.contains("aria-controls=\"town-chronicle-panel\""))
}

///|
test "real-work request uses the viewport-bounded accessible dialog contract" {
  let dispatch : Dispatch[Msg] = Emit(fn(_message) { @rabbita.none })
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_energy_valley_request_dialog(dispatch, init_model()),
    ),
  )
  assert_true(html.contains("class=\"energy-request-dialog "))
  assert_true(html.contains("class=\"energy-request-dialog-close "))
  assert_true(html.contains("role=\"dialog\""))
  assert_true(html.contains("aria-modal=\"true\""))
  assert_true(html.contains("aria-labelledby=\"energy-request-title\""))
}
