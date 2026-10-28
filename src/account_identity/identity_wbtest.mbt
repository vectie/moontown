///|
fn identity_fixture(state~ : String = "Active") -> Json {
  {
    "account_id": "account-a",
    "subject_ref": "subject-a",
    "identity_issuer": "https://identity.example",
    "display_name": "Alice",
    "state": state,
    "roles": ["PlatformOperator", "EnterpriseUser"],
  }
}

///|
fn test_identity_session(value : Json) -> Session? {
  parse_session(
    {
      endpoint: "http://127.0.0.1:1",
      host: "identity.example",
      origin: "https://identity.example",
      prefix: "/user",
    },
    "private-cookie",
    "lnxs_private-bearer",
    value,
  )
}

///|
test "canonical identity is stable, private and does not inherit paid or admin grants" {
  let session = test_identity_session(identity_fixture()).unwrap()
  let context = session.context()
  assert_eq(context.account_kind, @account_system.SignedInAccount)
  assert_false(context.visitor)
  assert_true(context.has_entitlement(ViewOwnCompute))
  assert_false(context.has_entitlement(AccessAdminConsole))
  assert_true(session.is_platform_operator())
  assert_false(context.has_entitlement(ManagePersonalBilling))
  assert_eq(
    context.user_id,
    test_identity_session(identity_fixture()).unwrap().context().user_id,
  )
  let text = @account_system.account_context_projection(context).stringify()
  assert_false(text.contains("private-cookie"))
  assert_false(text.contains("private-bearer"))
  assert_false(text.contains("subject-a"))
  assert_true(session.owns_subject("subject-a"))
  assert_false(session.owns_subject("subject-b"))
}

///|
async test "display name and organization roles cannot grant fleet reads" {
  guard identity_fixture() is Object(fields) else { abort("fixture") }
  fields["display_name"] = "PlatformOperator".to_json()
  fields["roles"] = ["OrganizationAdmin", "EnterpriseUser"]
  let ordinary = test_identity_session(Json::object(fields)).unwrap()
  assert_false(ordinary.is_platform_operator())
  assert_eq(ordinary.read_platform_nodes("http://127.0.0.1:1", "").0, 403)
}

///|
test "inactive, incomplete, and alternate issuer identities cannot alias the active account" {
  assert_true(test_identity_session(identity_fixture(state="Disabled")) is None)
  assert_true(
    test_identity_session({ "account_id": "account-a", "state": "Active" })
    is None,
  )
  guard identity_fixture() is Object(fields) else { abort("fixture") }
  fields["identity_issuer"] = "https://another.example".to_json()
  assert_false(
    test_identity_session(Json::object(fields)).unwrap().context().user_id ==
    test_identity_session(identity_fixture()).unwrap().context().user_id,
  )
}

///|
test "identity transport rejects nonlocal cleartext endpoints" {
  assert_true(endpoint_allowed("https://identity.example"))
  assert_true(endpoint_allowed("http://127.0.0.1:8443"))
  assert_false(endpoint_allowed("http://identity.example"))
  assert_false(endpoint_allowed("file:///identity"))
  assert_false(endpoint_allowed("http://localhost:1234@evil.example"))
  assert_false(endpoint_allowed("http://localhost:1234.evil.example"))
  assert_true(
    Client::new(
      endpoint="https://identity.example",
      host="other.example",
      origin="https://other.example",
      prefix="/user",
    )
    is None,
  )
  assert_true(
    Client::new(
      endpoint="https://identity.example",
      host="identity.example",
      origin="https://identity.example",
      prefix="/user",
    )
    is Some(_),
  )
}

///|
async test "expired and failed sessions cannot fall back to a local identity" {
  let fixture = test_identity_session(identity_fixture()).unwrap()
  for status in [401, 403, 502] {
    let mut calls = 0
    let result = resolve_using(fixture.config, "cookie-a", (path, bearer) => {
      calls += 1
      assert_eq(path, "/auth/session")
      assert_eq(bearer, "")
      (status, Json::null())
    })
    assert_eq(calls, 1)
    if status == 502 {
      assert_true(result is Unavailable)
    } else {
      assert_true(result is SignedOut)
    }
  }
}

///|
async test "session bearer is revalidated and only self routes can be read" {
  let fixture = test_identity_session(identity_fixture()).unwrap()
  let mut calls = 0
  let result = resolve_using(fixture.config, "cookie-a", (path, bearer) => {
    calls += 1
    if calls == 1 {
      assert_eq(path, "/auth/session")
      assert_eq(bearer, "")
      (200, { "session_token": "lnxs_temporary" })
    } else {
      assert_eq(path, "/v1/auth/self")
      assert_eq(bearer, "lnxs_temporary")
      (200, identity_fixture())
    }
  })
  guard result is Authenticated(session) else {
    abort("expected authenticated identity")
  }
  assert_eq(calls, 2)
  assert_eq(session.context().user_id, fixture.context().user_id)
  assert_eq(session.read_self("/v1/nodes", "").0, 400)
  assert_eq(
    session.read_self("/v1/machine-access/self", "org\r\nforged").0,
    400,
  )
  let rejected = resolve_using(fixture.config, "cookie-a", (path, _) => {
    if path == "/auth/session" {
      (200, { "session_token": "lnxs_revoked" })
    } else {
      (401, Json::null())
    }
  })
  assert_true(rejected is SignedOut)
}
