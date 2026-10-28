///|
test "desktop neighborhood routing and mutation allowlists stay narrow" {
  for
    path in [
      "/api/neighborhood/public", "/api/neighborhood/mine", "/api/neighborhood/actions",
    ] {
    assert_true(neighborhood_http_path(path))
  }
  for
    path in [
      "/api/neighborhood", "/api/neighborhood/public/", "/api/neighborhood/state.json",
      "/api/neighborhood/mine/other", "/api/collaboration", "/miniapp/account/admin",
    ] {
    assert_false(neighborhood_http_path(path))
  }
  for
    action in [
      "save-story", "publish-story", "register", "check-in", "request-follow-up",
      "resolve-follow-up",
    ] {
    assert_true(neighborhood_http_action(action))
  }
  for action in ["public", "mine", "set-role", "set-owner", "execute"] {
    assert_false(neighborhood_http_action(action))
  }
}

///|
test "desktop neighborhood errors preserve status without leaking internal data" {
  assert_eq(
    neighborhood_http_error(@neighborhood.NeighborhoodError::Unauthenticated).0,
    401,
  )
  assert_eq(
    neighborhood_http_error(@neighborhood.NeighborhoodError::Forbidden).0,
    403,
  )
  assert_eq(
    neighborhood_http_error(@neighborhood.NeighborhoodError::NotFound).0,
    404,
  )
  assert_eq(
    neighborhood_http_error(
      @neighborhood.NeighborhoodError::InvalidRequest("sensitive field"),
    ).0,
    400,
  )
  assert_eq(
    neighborhood_http_error(
      @neighborhood.NeighborhoodError::Conflict("private revision"),
    ).0,
    409,
  )
  let result = neighborhood_http_error(Failure("/private/workspace/token"))
  assert_eq(result.0, 503)
  assert_false(result.1.stringify().contains("/private"))
}

///|
test "desktop neighborhood account stamp is required and cannot select identity" {
  assert_true(neighborhood_actor_matches({ "expected_actor_id": "a" }, "a"))
  assert_false(neighborhood_actor_matches({ "expected_actor_id": "a" }, "b"))
  assert_false(
    neighborhood_actor_matches({ "actor_id": "a", "can_host": true }, "a"),
  )
  assert_false(neighborhood_actor_matches({ "expected_actor_id": 1 }, "a"))
  assert_false(neighborhood_actor_matches({ "expected_actor_id": "" }, ""))
}
