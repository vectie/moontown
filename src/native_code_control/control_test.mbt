///|
test "public native route selection uses exact live membership" {
  let route : Json = {
    "contract": "moonclaw.moongate-route.v1",
    "ready": true,
    "default_model": "moongate/catalog-id",
    "models": [{ "name": "moongate/catalog-id" }],
  }
  assert_eq(
    @native_code_control.select_model(route, "").unwrap(),
    "moongate/catalog-id",
  )
  assert_true(@native_code_control.select_model(route, "default") is Err(_))
  assert_eq(
    @native_code_control.url_component("/source/my book"),
    "%2Fsource%2Fmy%20book",
  )
}
