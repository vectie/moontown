///|
fn route_fixture(ready : Bool, default_model : String) -> Json {
  {
    "contract": "moonclaw.moongate-route.v1",
    "ready": ready,
    "default_model": default_model,
    "models": [
      { "name": "moongate/configured" },
      { "name": "moongate/explicit" },
    ],
  }
}

///|
fn route_override(route : Json, key : String, value : Json) -> Json {
  guard route is Object(fields) else { abort("fixture") }
  let next = fields.copy()
  next[key] = value
  Json::object(next)
}

///|
fn route_without(route : Json, key : String) -> Json {
  guard route is Object(fields) else { abort("fixture") }
  let next = fields.copy()
  next.remove(key)
  Json::object(next)
}

///|
test "native explicit selection needs a live catalog without a configured default" {
  let route = route_override(route_fixture(false, ""), "catalog_ready", true)
  assert_eq(
    @native_code_control.select_model(route, "moongate/explicit"),
    Ok("moongate/explicit"),
  )
  assert_true(@native_code_control.select_model(route, "") is Err(_))
  let unavailable_default = route_override(
    route, "default_model", "moongate/absent",
  )
  assert_eq(
    @native_code_control.select_model(unavailable_default, "moongate/explicit"),
    Ok("moongate/explicit"),
  )
  assert_true(
    @native_code_control.select_model(unavailable_default, "") is Err(_),
  )
  for
    projection in [
      route_without(route, "default_model"),
      route_override(route, "default_model", Json::null()),
      route_override(route, "default_model", 1),
      route_without(route, "ready"),
    ] {
    assert_eq(
      @native_code_control.select_model(projection, "moongate/explicit"),
      Ok("moongate/explicit"),
    )
    assert_true(@native_code_control.select_model(projection, "") is Err(_))
  }
}

///|
test "native automatic selection requires ready exact configured default" {
  let route = route_override(
    route_fixture(true, "moongate/configured"),
    "catalog_ready",
    true,
  )
  assert_eq(
    @native_code_control.select_model(route, ""),
    Ok("moongate/configured"),
  )
  for
    default_model in [
      "", "moongate/absent", "default", "codex/configured", "moongate/",
    ] {
    assert_true(
      @native_code_control.select_model(
        route_override(route, "default_model", default_model.to_json()),
        "",
      )
      is Err(_),
    )
  }
  for ready in [(false : Json), Json::null(), "true", 1] {
    assert_true(
      @native_code_control.select_model(
        route_override(route, "ready", ready),
        "",
      )
      is Err(_),
    )
  }
  assert_true(
    @native_code_control.select_model(route_without(route, "ready"), "")
    is Err(_),
  )
}

///|
test "native unavailable stale and malformed catalogs never fall back" {
  let route = route_fixture(true, "moongate/configured")
  for
    unavailable in [
      Json::null(),
      route_override(route, "contract", "unknown.v1"),
      route_override(route, "catalog_ready", false),
      route_override(route, "catalog_ready", Json::null()),
      route_override(route, "catalog_ready", "true"),
      route_override(route, "catalog_ready", 1),
      route_override(route, "catalog_ready", {}),
      route_override(route, "models", []),
      route_override(route, "models", Json::null()),
    ] {
    for requested in ["", "moongate/explicit"] {
      assert_true(
        @native_code_control.select_model(unavailable, requested) is Err(_),
      )
    }
  }
}

///|
test "native legacy payloads remain compatible but selectors stay exact" {
  let route = route_fixture(true, "moongate/configured")
  assert_eq(
    @native_code_control.select_model(route, ""),
    Ok("moongate/configured"),
  )
  assert_eq(
    @native_code_control.select_model(route, "moongate/explicit"),
    Ok("moongate/explicit"),
  )
  assert_true(
    @native_code_control.select_model(
      route_fixture(false, ""),
      "moongate/explicit",
    )
    is Err(_),
  )
  let route = route_override(route, "models", [
    { "name": "moongate/configured" },
    { "name": "codex/legacy" },
    { "name": "default" },
    { "name": "moongate/" },
  ])
  for
    requested in [
      "moongate/absent", "codex/legacy", "default", "moongate/", " moongate/configured",
      "moongate/configured ",
    ] {
    assert_true(@native_code_control.select_model(route, requested) is Err(_))
  }
}

///|
test "native explicit identity survives default changes without route mutation" {
  let route = route_override(route_fixture(false, ""), "catalog_ready", true)
  let before = route.stringify()
  guard @native_code_control.select_model(route, "moongate/explicit")
    is Ok(selected) else {
    fail("exact live selection should succeed without a default")
  }
  assert_eq(route.stringify(), before)
  assert_eq(selected, "moongate/explicit")
  assert_eq(
    @native_code_control.select_model(
      route_fixture(true, "moongate/configured"),
      selected,
    ),
    Ok(selected),
  )
}
