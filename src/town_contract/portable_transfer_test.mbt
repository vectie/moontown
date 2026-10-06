///|
test "portable transfer is additive exact authenticated bounded and separately granted" {
  let value = @town_contract.portable_transfer_contract()
  guard value is Object(fields) else { fail("expected transfer contract") }
  assert_eq(fields["max_raw_package_bytes"], (64 * 1024 * 1024).to_json())
  assert_eq(fields["ordinary_json_limit_bytes"], (128 * 1024).to_json())
  assert_eq(fields["max_metadata_response_bytes"], (8 * 1024 * 1024).to_json())
  assert_eq(fields["permission"], "download_package".to_json())
  assert_eq(fields["metadata_grants_authorize_bytes"], false.to_json())
  assert_eq(fields["automatic_install_or_execution"], false.to_json())
  guard fields["endpoints"] is Array(routes) else { fail("expected routes") }
  assert_eq(routes.length(), 7)
  assert_true(
    @town_contract.miniapp_contract().stringify().contains(value.stringify()),
  )
}
