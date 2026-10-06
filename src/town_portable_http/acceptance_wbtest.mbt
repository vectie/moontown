///|
/// Opt-in actual exported-byte fixture. The explicitly injected path contains
/// only the retained synthetic Book export/source, never configured user data.
async test "actual exported package crosses production handler private store and real client sink" {
  guard @env.get_env_var("MOONTOWN_PACKAGE_ACCEPTANCE_DIR") is Some(input) else {
    return
  }
  let f = fixture()
  let bytes = @fs.read_file(input + "/sender-v1.moonbook-agent").binary()
  let source : @town_marketplace.PortableSource = @json.from_json(
    @json.parse(@fs.read_file(input + "/source.json").text()),
  )
  assert_eq(bytes.length(), 495683)
  assert_eq(raw_sha(bytes), source.package_sha256)
  let binding = f.listing(source)
  let original_binding : @town_marketplace.PortableListingBinding = @json.from_json(
    @json.parse(@fs.read_file(input + "/town-binding.json").text()),
  )
  assert_eq(binding, original_binding)
  let sender_path = f.root + "/sender-original.moonbook-agent"
  @fs.write_file(sender_path, bytes, create_mode=CreateNew, permission=0o600)
  let transcript : Array[Json] = []
  let sender = @town_portable_client.PortableClient::new(
    () => token("publisher-a"),
    fixture_exchange(f.service, audit=transcript),
  )
  let recipient = @town_portable_client.PortableClient::new(
    () => token("reader-a"),
    fixture_exchange(f.service, audit=transcript),
  )
  assert_true(recipient.list().is_empty())
  let uploaded = sender.upload(sender_path, binding.listing_id, binding)
  assert_eq(uploaded.binding, binding)
  assert_true(uploaded.receipt is Some(_))
  assert_true(recipient.list().is_empty())
  let preview = sender.preview_share(draft(binding))
  assert_true(preview.stringify().contains("entire exact package"))
  assert_true(recipient.list().is_empty())
  ignore(sender.share(draft(binding)))
  let listed = recipient.list()
  assert_eq(listed.length(), 1)
  assert_eq(listed[0].binding, binding)
  @fs.mkdir(f.root + "/recipient-inbox", permission=0o700)
  let received = recipient.download(
    uploaded.package_id,
    binding,
    f.root + "/recipient-inbox/received-v1.moonbook-agent",
  )
  let downloaded = @fs.read_file(received.package_path).binary()
  assert_eq(downloaded, bytes)
  assert_eq(
    @json.parse(@fs.read_file(received.binding_path).text()),
    binding.to_json(),
  )
  assert_eq(
    @json.parse(@fs.read_file(received.receipt_path).text()),
    uploaded.receipt.unwrap().to_json(),
  )
  // A changed sender is a different immutable listing and has no old grants.
  let v2_bytes = @fs.read_file(input + "/sender-v2.moonbook-agent").binary()
  let v2_source : @town_marketplace.PortableSource = @json.from_json(
    @json.parse(@fs.read_file(input + "/source-v2.json").text()),
  )
  let v2_binding = f.listing(v2_source, id="agent.robot-guide-v2")
  let v2_path = f.root + "/sender-v2.moonbook-agent"
  @fs.write_file(v2_path, v2_bytes, create_mode=CreateNew, permission=0o600)
  ignore(sender.upload(v2_path, v2_binding.listing_id, v2_binding))
  assert_eq(recipient.list().length(), 1)
  assert_eq(call(f.service, download_request(v2_binding)).code, 403)
  let retained = recipient.download(
    uploaded.package_id,
    binding,
    f.root + "/recipient-inbox/retained-v1.moonbook-agent",
  )
  assert_eq(@fs.read_file(retained.package_path).binary(), bytes)
  let restarted_service = {
    ..f.service,
    store: @town_portable_transfer.portable_store(
      f.root + "/packages",
      limits=f.service.limits,
    ),
  }
  let restarted_recipient = @town_portable_client.PortableClient::new(
    () => token("reader-a"),
    fixture_exchange(restarted_service),
  )
  assert_eq(restarted_recipient.list().length(), 1)
  assert_eq(call(restarted_service, download_request(binding)).bytes(), bytes)
  @fs.write_file(
    f.root + "/transport-transcript.json",
    transcript.to_json().stringify(indent=2),
    create_mode=CreateNew,
    permission=0o600,
  )
  @fs.write_file(
    input + "/acceptance-proof.json",
    (
      {
        "contract": "moontown.portable-transfer-acceptance.v1",
        "fixture_root": f.root,
        "sender_package": sender_path,
        "received_package": received.package_path,
        "received_binding": received.binding_path,
        "received_receipt": received.receipt_path,
        "v2_package": v2_path,
        "package_size_bytes": bytes.length(),
        "package_sha256": raw_sha(downloaded),
        "binding_digest": binding.binding_digest,
        "package_id": uploaded.package_id,
        "unchanged_binding": true,
        "production_handler_core": true,
        "private_store_bytes": true,
        "real_client_sink": true,
        "explicit_exact_recipient_grant": true,
        "preview_did_not_grant": true,
        "retained_v1_after_v2": true,
        "v2_old_recipient_denied": true,
        "restart_grant_preserved": true,
        "sockets": 0,
        "live_sessions": 0,
        "transport_transcript_sha256": raw_sha(
          @fs.read_file(f.root + "/transport-transcript.json").binary(),
        ),
        "account_state_sha256": raw_sha(
          @fs.read_file(f.root + "/accounts.json").binary(),
        ),
        "marketplace_state_sha256": raw_sha(
          @fs.read_file(f.root + "/marketplace.json").binary(),
        ),
        "package_index_sha256": raw_sha(
          @fs.read_file(f.root + "/packages/index.json").binary(),
        ),
        "book_semantic_import_pending": true,
      } : Json).stringify(indent=2) +
    "\n",
    create_mode=CreateOrTruncate,
    permission=0o600,
  )
}
