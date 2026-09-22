///|
test "public town requires current active operator role" {
  assert_true(
    active_platform_operator({
      "state": "Active",
      "roles": ["PlatformOperator"],
    }),
  )
  assert_false(
    active_platform_operator({
      "state": "Suspended",
      "roles": ["PlatformOperator"],
    }),
  )
  assert_false(
    active_platform_operator({ "state": "Active", "roles": ["EnterpriseUser"] }),
  )
  assert_false(
    active_platform_operator({ "state": "Active", "roles": ["AuditReader"] }),
  )
  assert_false(active_platform_operator({ "roles": ["PlatformOperator"] }))
}

///|
async test "identity body reader rejects oversized bytes before parsing" {
  let exact = @io.MemoryReader(writer => writer.write(b"1234"))
  assert_eq(bounded_identity_text(exact, 4), Some("1234"))
  let oversized = @io.MemoryReader(writer => writer.write(b"12345"))
  assert_eq(bounded_identity_text(oversized, 4), None)
  let empty = @io.MemoryReader(writer => writer.write(b""))
  assert_eq(bounded_identity_text(empty, 4), Some(""))
}
