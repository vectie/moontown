///|
test "shared identity cannot be combined with an unrelated local billing or admin token" {
  for
    path in [
      @town_contract.miniapp_account_billing_path(),
      @town_contract.miniapp_account_tenant_switch_path(),
      @town_contract.miniapp_admin_management_path(),
      @town_contract.miniapp_enterprise_management_path(),
      @town_contract.miniapp_account_logout_path(),
    ] {
    assert_true(requires_federated_account_adapter(path))
  }
  assert_false(
    requires_federated_account_adapter(
      @town_contract.miniapp_account_context_path(),
    ),
  )
  assert_false(
    requires_federated_account_adapter(@town_contract.miniapp_health_path()),
  )
}
