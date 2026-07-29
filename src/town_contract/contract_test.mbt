///|
test "desktop and miniapp contracts share capabilities without sharing trust" {
  let desktop = @town_contract.desktop_contract().stringify()
  let miniapp = @town_contract.miniapp_contract().stringify()
  assert_true(desktop.contains("\"schema\":\"moontown.api.v1\""))
  assert_true(miniapp.contains("\"schema\":\"moontown.api.v1\""))
  assert_true(desktop.contains("\"audience\":\"trusted-local-operator\""))
  assert_true(miniapp.contains("\"audience\":\"authenticated-miniapp-user\""))
  assert_true(desktop.contains("\"capability\":\"research.watch.submit\""))
  assert_true(miniapp.contains("\"capability\":\"research.watch.submit\""))
  assert_true(!desktop.contains("/miniapp/"))
  assert_true(!miniapp.contains("/api/operator-requests"))
}
