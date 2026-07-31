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
  assert_true(
    desktop.contains("\"capability\":\"civic.communication.handoff.inspect\""),
  )
  assert_true(desktop.contains("/api/research-handoffs/inspect"))
  assert_true(desktop.contains("/api/research-handoffs/start"))
  assert_true(desktop.contains("/api/research-handoffs/reconcile"))
  assert_true(desktop.contains("/api/research-handoffs/moonflow/start"))
  assert_true(desktop.contains("/api/research-handoffs/moonflow/reconcile"))
  assert_true(
    desktop.contains("\"capability\":\"civic.communication.handoff.execute\""),
  )
  assert_true(
    desktop.contains("\"capability\":\"civic.communication.handoff.reconcile\""),
  )
  assert_true(
    desktop.contains("\"capability\":\"civic.communication.moonflow.execute\""),
  )
  assert_true(!desktop.contains("/miniapp/"))
  assert_true(!miniapp.contains("/api/operator-requests"))
  assert_true(desktop.contains("/api/standing-goals"))
  assert_true(desktop.contains("/api/book-registrations"))
}
