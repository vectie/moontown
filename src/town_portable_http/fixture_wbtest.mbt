///|
struct Recorded {
  mut code : Int
  mut headers : Map[String, String]
  chunks : Array[Bytes]
  mut closed : Bool
  mut finished : Bool
}

///|
fn recording() -> Recorded {
  { code: 0, headers: {}, chunks: [], closed: false, finished: false, }
}

///|
struct ObservedReader {
  bytes : Bytes
  read_calls : Ref[Int]
  buffer : @io.ReaderBuffer
  mut position : Int
}

///|
fn observed_reader(bytes : Bytes, read_calls : Ref[Int]) -> ObservedReader {
  { bytes, read_calls, buffer: @io.ReaderBuffer::new(), position: 0, }
}

///|
impl @io.Reader for ObservedReader with fn _get_internal_buffer(self) {
  self.buffer
}

///|
impl @io.Reader for ObservedReader with fn _direct_read(
  self,
  target,
  offset~,
  max_len~,
) {
  self.read_calls.val = self.read_calls.val + 1
  let count = Int::min(max_len, self.bytes.length() - self.position)
  for i in 0..<count {
    target[offset + i] = self.bytes[self.position + i]
  }
  self.position = self.position + count
  count
}

///|
fn Recorded::sink(self : Recorded) -> ResponseSink {
  response_sink(
    (code, headers) => {
      self.code = code
      self.headers = headers
    },
    bytes => self.chunks.push(bytes),
    () => self.finished = true,
    () => self.closed = true,
  )
}

///|
fn Recorded::bytes(self : Recorded) -> Bytes {
  let out = @buffer.new()
  for chunk in self.chunks {
    out.write_bytes(chunk)
  }
  out.to_bytes()
}

///|
fn Recorded::payload(self : Recorded) -> Json raise {
  guard @json.parse(@utf8.decode(self.bytes())) is Object(fields) else {
    fail("not response JSON")
  }
  fields["payload"]
}

///|
fn test_account(
  id : String,
  tenant? : String = "town-a",
  publisher? : Bool = true,
) -> @account_system.AccountPrincipal {
  {
    user_id: id,
    display_name: id,
    personal_plan: @account_system.PaidPlan,
    platform_roles: [],
    tenant_access: [
      {
        tenant_id: tenant,
        tenant_name: tenant,
        plan: @account_system.EnterprisePlan,
        roles: if publisher {
          [@account_system.AccountMember, @account_system.AccountPublisher]
        } else {
          [@account_system.AccountMember]
        },
        active: true,
        version: 1,
      },
    ],
    active: true,
    version: 1,
  }
}

///|
fn test_market_principal(
  id : String,
  tenant? : String = "town-a",
) -> @town_marketplace.MarketplacePrincipal {
  {
    principal_id: id,
    tenant_id: tenant,
    display_name: id,
    workspace_ids: [],
    roles: ["publisher"],
    interest_tags: [],
    active: true,
    version: 1,
  }
}

///|
fn token(id : String) -> String {
  "synthetic-transfer-session-" + id
}

///|
struct Fixture {
  root : String
  service : TransferService
  now : Ref[UInt64]
}

///|
async fn fixture(
  limits? : @town_portable_transfer.TransferLimits = @town_portable_transfer.default_limits(),
) -> Fixture {
  let root = @fs.realpath(@fs.tmpdir(prefix="moontown-package-http-"))
  let clock = Ref(500UL)
  let mut state = @account_system.empty_account_state()
  for
    id in [
      "publisher-a", "reader-a", "unrelated-a", "wrong-tenant", "expired-a", "revoked-a",
      "no-publish",
    ] {
    let tenant = if id == "wrong-tenant" { "town-b" } else { "town-a" }
    state = @account_system.account_register_session(
      state,
      test_account(id, tenant~, publisher=id != "no-publish"),
      "session:" + id,
      token(id),
      active_tenant_id=tenant,
      expires_at_ms=if id == "expired-a" { 499UL } else { 100000UL },
    )
  }
  state = @account_system.account_revoke_session(
    state,
    token("revoked-a"),
    now_ms=100UL,
  )
  state = @account_system.account_register_session(
    state,
    {
      ..test_account("visitor-a"),
      personal_plan: @account_system.VisitorPlan,
      tenant_access: [],
    },
    "session:visitor-a",
    token("visitor-a"),
    expires_at_ms=100000UL,
  )
  @fs.write_file(
    root + "/accounts.json",
    state.to_json().stringify(),
    create_mode=CreateNew,
    permission=0o600,
  )
  let accounts = @account_system.account_application(
    root + "/accounts.json",
    test_account("bootstrap-a"),
    "session:bootstrap-a",
    token("bootstrap-a"),
  )
  let marketplace = @town_marketplace.marketplace_application(
    root + "/marketplace.json",
    test_market_principal("bootstrap-a"),
    "session:bootstrap-a",
    token("bootstrap-a"),
  )
  for id in ["publisher-a", "reader-a", "unrelated-a", "expired-a"] {
    marketplace.synchronize_account_session(
      test_market_principal(id),
      token(id),
      now_ms=100UL,
      expires_at_ms=100000UL,
    )
  }
  {
    root,
    now: clock,
    service: {
      accounts,
      marketplace,
      store: @town_portable_transfer.portable_store(root + "/packages", limits~),
      limits,
      now: () => clock.val,
    },
  }
}

///|
fn raw_sha(bytes : Bytes) -> String {
  "sha256:" + @crypto.bytes_to_hex_string(@crypto.sha256(bytes))
}

///|
fn synthetic_source(bytes : Bytes) -> @town_marketplace.PortableSource {
  let hash = raw_sha(bytes)
  {
    contract: "moonbook.portable_source.v1",
    bundle_contract: "moonbook.agent_bundle.v1",
    agent_id: "synthetic-book",
    agent_version: "v1",
    book_revision: hash,
    bundle_digest: hash,
    package_filename: "synthetic.moonbook-agent",
    package_size_bytes: bytes.length(),
    package_sha256: hash,
    file_count: 1,
    total_decoded_bytes: bytes.length(),
    outputs_manifest_path: None,
    outputs_manifest_digest: None,
    included_output_count: 0,
    reference_only_count: 0,
    transport: "local_file",
  }
}

///|
async fn Fixture::listing(
  self : Fixture,
  source : @town_marketplace.PortableSource,
  id? : String = "agent.robot-guide",
) -> @town_marketplace.PortableListingBinding {
  let payload : Json = {
    "listing_id": id,
    "title": "Synthetic portable fixture",
    "summary": "Synthetic private package source",
    "image_ref": "asset:fixture",
    "capabilities": ["research"],
    "tags": ["fixture"],
    "action_ids": ["follow", "message"],
    "required_permissions": [],
    "pricing_summary": "Synthetic fixture only",
    "authority_ceiling": "advice-only",
    "license_class": "fixture-only",
    "rights_summary": "Synthetic data",
    "version_label": "v1",
    "portable_source": source.to_json(),
  }
  ignore(
    self.service.marketplace.execute(
      token("publisher-a"),
      "upsert-agent",
      payload.stringify(),
      "",
      now_ms=self.now.val,
    ),
  )
  self.service.marketplace.portable_transfer_binding(id).unwrap()
}

///|
fn upload_request(
  binding : @town_marketplace.PortableListingBinding,
  session? : String = token("publisher-a"),
) -> @http.Request {
  {
    meth: @http.Put,
    path: @town_contract.portable_package_content_path() +
    "?listing_id=" +
    binding.listing_id,
    headers: {
      "x-miniapp-session": session,
      "x-town-binding-digest": binding.binding_digest,
      "content-length": binding.source.package_size_bytes.to_string(),
      "content-type": "application/octet-stream",
    },
  }
}

///|
fn download_request(
  binding : @town_marketplace.PortableListingBinding,
  session? : String = token("reader-a"),
) -> @http.Request {
  {
    meth: @http.Get,
    path: @town_contract.portable_package_content_path() +
    "?package_id=" +
    @town_portable_transfer.package_id(binding.binding_digest),
    headers: {
      "x-miniapp-session": session,
      "x-town-binding-digest": binding.binding_digest,
    },
  }
}

///|
async fn call(
  service : TransferService,
  request : @http.Request,
  bytes? : Bytes = b"",
) -> Recorded {
  let record = recording()
  let reader = @io.MemoryReader(writer => writer.write(bytes))
  defer reader.close()
  assert_true(service.handle(request, reader, record.sink()))
  record
}

///|
async fn post(
  service : TransferService,
  path : String,
  value : Json,
  session? : String = token("publisher-a"),
) -> Recorded {
  let bytes = @utf8.encode(value.stringify())
  call(
    service,
    {
      meth: @http.Post,
      path,
      headers: {
        "x-miniapp-session": session,
        "content-type": "application/json",
        "content-length": bytes.length().to_string(),
      },
    },
    bytes~,
  )
}

///|
fn draft(
  binding : @town_marketplace.PortableListingBinding,
  id? : String = "grant-v1",
  recipient? : String = "reader-a",
  expiry? : UInt64 = 10000UL,
) -> @town_portable_transfer.GrantDraft {
  {
    grant_id: id,
    package_id: @town_portable_transfer.package_id(binding.binding_digest),
    binding_digest: binding.binding_digest,
    grantee_principal_id: recipient,
    expires_at_ms: expiry,
  }
}

///|
fn fixture_exchange(
  service : TransferService,
  audit? : Array[Json],
) -> @town_portable_client.Exchange {
  (request, write_body, read_response) => {
    let body = @io.MemoryReader(write_body)
    defer body.close()
    let record = recording()
    assert_true(service.handle(request, body, record.sink()))
    if audit is Some(entries) {
      let safe_headers : Map[String, String] = Map([])
      for key, value in request.headers {
        if key != "x-miniapp-session" {
          safe_headers[key] = value
        }
      }
      entries.push({
        "request_method": request.meth.to_json(),
        "request_path": request.path,
        "request_headers": safe_headers.to_json(),
        "session_source": "injected_synthetic_supplier",
        "response_status": record.code,
        "response_headers": record.headers.to_json(),
        "response_body_bytes": record.bytes().length(),
        "response_body_sha256": raw_sha(record.bytes()),
        "response_finished": record.finished,
        "connection_closed": record.closed,
      })
    }
    let response : @http.Response = {
      code: record.code,
      reason: "synthetic transport",
      headers: record.headers,
      cookies: [],
    }
    let reader = @io.MemoryReader(writer => {
      for chunk in record.chunks {
        writer.write(chunk)
      }
    })
    defer reader.close()
    read_response(response, reader)
  }
}
