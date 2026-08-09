///|
fn moonclaw_guide_test_dispatch() -> Dispatch[Msg] {
  Emit(fn(_message) { @rabbita.none })
}

///|
test "Moonclaw pet remains available before avatar creation" {
  let html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_phone_fab(moonclaw_guide_test_dispatch(), init_model()),
    ),
  )
  assert_true(html.contains("moonclaw-pet"))
  assert_true(html.contains("小爪"))
  assert_true(html.contains("忘了？问我"))
  assert_true(html.contains("aria-controls=\"town-phone-panel\""))
}

///|
test "opening the pet selects the guide inside the existing phone" {
  let (_, model) = moonclaw_guide_open_update({
    ..init_model(),
    phone_contact: "mayor",
    phone_open: false,
    square_open: true,
    energy_intro_open: true,
  })
  assert_true(model.phone_open)
  assert_eq(model.phone_contact, moonclaw_guide_contact_id)
  assert_false(model.square_open)
  assert_false(model.energy_intro_open)
  assert_eq(phone_contacts(model)[0].id, moonclaw_guide_contact_id)
}

///|
test "guide replies accept only the typed response contract" {
  assert_eq(
    moonclaw_guide_reply_result(
      "{\"ok\":true,\"reply\":\"先完成左侧的新手任务。\",\"agent\":\"moonclaw\"}",
    ),
    Ok("先完成左侧的新手任务。"),
  )
  assert_true(
    moonclaw_guide_reply_result("{\"ok\":false,\"error\":\"gateway offline\"}")
    is Err("gateway offline"),
  )
  assert_true(moonclaw_guide_reply_result("not-json") is Err(_))
  assert_eq(
    moonclaw_guide_reply_result(
      "{\"ok\":false,\"error\":\"<!DOCTYPE html>\\n<html>proxy error</html>\"}",
    ),
    Err("Moonclaw 目前无法连接，请确认本地网关正在运行。"),
  )
}

///|
test "guide phone renders quick questions and announced async states" {
  let dispatch = moonclaw_guide_test_dispatch()
  let ready = {
    ..init_model(),
    phone_open: true,
    phone_contact: moonclaw_guide_contact_id,
  }
  let ready_html = @rabbita.render_to_string(
    @rabbita.static_cell(render_phone_panel(dispatch, ready)),
  )
  assert_true(ready_html.contains("Moonclaw Guide · 真实本地 Agent"))
  assert_true(ready_html.contains("我现在应该先做什么？"))
  assert_true(ready_html.contains("问小爪关于 MoonTown 的问题"))
  assert_true(ready_html.contains("aria-busy=\"false\""))
  let busy_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_phone_panel(dispatch, { ..ready, moonclaw_guide_pending: true }),
    ),
  )
  assert_true(busy_html.contains("Moonclaw 正在查看你的问题"))
  assert_true(busy_html.contains("aria-live=\"polite\""))
  assert_true(busy_html.contains("aria-busy=\"true\""))
  let error_html = @rabbita.render_to_string(
    @rabbita.static_cell(
      render_phone_panel(dispatch, {
        ..ready,
        moonclaw_guide_error: "gateway offline",
      }),
    ),
  )
  assert_true(error_html.contains("role=\"alert\""))
  assert_true(error_html.contains("gateway offline"))
}
