///|
fn raw_digest(bytes : BytesView) -> String {
  "sha256:" + @crypto.bytes_to_hex_string(@crypto.sha256(bytes))
}

///|
fn test_limits() -> TransferLimits {
  {
    max_package_bytes: 256,
    chunk_bytes: 7,
    max_retained_bytes: 768,
    idle_timeout_ms: 100,
    total_timeout_ms: 500,
    lease_ms: 1000UL,
  }
}

///|
fn owner_actor() -> TransferActor {
  { principal_id: "publisher", tenant_id: "team", publisher: true, }
}

///|
fn recipient_actor() -> TransferActor {
  { principal_id: "recipient", tenant_id: "team", publisher: false, }
}

///|
fn test_binding(
  bytes : Bytes,
  listing : String,
) -> @town_marketplace.PortableListingBinding raise {
  let binding : @town_marketplace.PortableListingBinding = {
    contract: "moontown.portable-listing-binding.v1",
    listing_id: listing,
    publisher_principal_id: "publisher",
    tenant_id: "team",
    binding_revision: 1,
    source: {
      contract: "moonbook.portable_source.v1",
      bundle_contract: "moonbook.agent_bundle.v1",
      agent_id: "test-agent",
      agent_version: "1.0.0",
      book_revision: raw_digest(b"revision"),
      bundle_digest: raw_digest(b"bundle"),
      package_filename: "test.moonbook-agent",
      package_size_bytes: bytes.length(),
      package_sha256: raw_digest(bytes),
      file_count: 1,
      total_decoded_bytes: bytes.length(),
      outputs_manifest_path: None,
      outputs_manifest_digest: None,
      included_output_count: 0,
      reference_only_count: 0,
      transport: "local_file",
    },
    reuse_mode: "local_file_import",
    verification_scope: "publisher_declared_expected_source",
    binding_digest: "",
  }
  guard binding.to_json() is Object(fields) else { fail("binding object") }
  fields.remove("binding_digest")
  let binding = {
    ..binding,
    binding_digest: raw_digest(@utf8.encode(Json::object(fields).stringify())),
  }
  @town_marketplace.validate_portable_listing_binding(binding)
  binding
}

///|
async fn test_upload(
  store : PortableStore,
  binding : @town_marketplace.PortableListingBinding,
  bytes : Bytes,
) -> PackageView {
  let body = @io.MemoryReader(writer => writer.write(bytes))
  defer body.close()
  store.upload(owner_actor(), binding, body, () => (), () => 100UL)
}

///|
async fn expect_code(code : Int, action : async () -> Unit) -> Unit {
  try action() catch {
    TransferError(actual, _) => assert_eq(actual, code)
    error => fail("unexpected error: \{error}")
  } noraise {
    _ => fail("expected transfer error \{code}")
  }
}

///|
fn test_draft(view : PackageView, id : String) -> GrantDraft {
  {
    grant_id: id,
    package_id: view.package_id,
    binding_digest: view.binding.binding_digest,
    grantee_principal_id: "recipient",
    expires_at_ms: 500UL,
  }
}

///|
async test "exact raw stream receipt immutable retry and same descriptor download" {
  let root = @fs.realpath(@fs.tmpdir(prefix="town-store-exact-"))
  defer (@fs.rmdir(root, recursive=true) catch { _ => () })
  let store = portable_store(root, limits=test_limits())
  let bytes = Bytes::makei(65, i => i.to_byte())
  let binding = test_binding(bytes, "listing-one")
  let view = test_upload(store, binding, bytes)
  assert_eq(view.status, "available")
  assert_eq(view.receipt.unwrap().package_sha256, raw_digest(bytes))
  assert_eq(test_upload(store, binding, bytes).receipt, view.receipt)
  let grant = store.grant(owner_actor(), test_draft(view, "grant-one"), 110UL)
  assert_eq(
    store.grant(owner_actor(), test_draft(view, "grant-one"), 600UL),
    grant,
  )
  let download = store.download(
    recipient_actor(),
    view.package_id,
    binding.binding_digest,
    120UL,
  )
  defer download.close()
  let old = root + "/retained-old"
  @fs.rename(store.object_path(view.package_id), old)
  @fs.write_file(
    store.object_path(view.package_id),
    b"replacement",
    create_mode=CreateNew,
    permission=0o600,
  )
  let captured = @io.MemoryReader(writer => download.stream(writer))
  defer captured.close()
  assert_eq(captured.read_all().binary(), bytes)
  expect_code(503, () => {
    ignore(
      store.download(
        recipient_actor(),
        view.package_id,
        binding.binding_digest,
        120UL,
      ),
    )
  })
  assert_eq(store.list(recipient_actor(), 120UL)[0].grants.length(), 0)
}

///|
async test "one active reservation quota and recovery never age deletes active upload" {
  let root = @fs.realpath(@fs.tmpdir(prefix="town-store-concurrent-"))
  defer (@fs.rmdir(root, recursive=true) catch { _ => () })
  let limits = {
    ..test_limits(),
    max_package_bytes: 64,
    max_retained_bytes: 128,
  }
  let store = portable_store(root, limits~)
  let bytes = Bytes::make(64, b'x')
  let one = test_binding(bytes, "listing-one")
  let two = test_binding(bytes, "listing-two")
  let three = test_binding(bytes, "listing-three")
  let gate = @async.Mutex()
  gate.acquire()
  let started = Ref(false)
  @async.with_task_group(group => {
    let active = group.spawn(() => {
      let body = @io.MemoryReader(writer => {
        writer.write(bytes[:1])
        started.val = true
        gate.acquire()
        defer gate.release()
        writer.write(bytes[1:])
      })
      defer body.close()
      store.upload(owner_actor(), one, body, () => (), () => 100UL)
    })
    while !started.val {
      @async.sleep(1)
    }
    expect_code(409, () => ignore(test_upload(store, one, bytes)))
    store.recover(2000UL)
    assert_eq(store.load_index().reservations.length(), 1)
    ignore(test_upload(store, two, bytes))
    expect_code(413, () => ignore(test_upload(store, three, bytes)))
    gate.release()
    assert_eq(active.wait().status, "available")
  })
  assert_eq(store.load_index().reservations.length(), 0)
  assert_eq(store.list(owner_actor(), 100UL).length(), 2)
}

///|
async test "abandoned reservation partial file and rename before commit recover only expired unlocked bytes" {
  let root = @fs.realpath(@fs.tmpdir(prefix="town-store-restart-"))
  defer (@fs.rmdir(root, recursive=true) catch { _ => () })
  let store = portable_store(root, limits=test_limits())
  let bytes = b"restart exact bytes"
  let binding = test_binding(bytes, "listing-restart")
  let (reservation, file) = store.reserve(owner_actor(), binding, 100UL)
  file.write(bytes[:3])
  file.close()
  let restarted = portable_store(root, limits=test_limits())
  restarted.recover(101UL)
  assert_eq(restarted.load_index().reservations.length(), 1)
  restarted.recover(1100UL)
  assert_eq(restarted.load_index().reservations.length(), 0)
  assert_false(@fs.exists(store.part_path(reservation.attempt_id)))
  let (next, ready) = store.reserve(owner_actor(), binding, 1200UL)
  ready.write(bytes)
  ready.sync()
  @fs.rename(
    store.part_path(next.attempt_id),
    store.object_path(next.package_id),
  )
  ready.close()
  expect_code(409, () => {
    ignore(
      store.download(
        owner_actor(),
        next.package_id,
        binding.binding_digest,
        1201UL,
      ),
    )
  })
  restarted.recover(2200UL)
  assert_false(@fs.exists(store.object_path(next.package_id)))
  assert_eq(restarted.load_index().reservations.length(), 0)
}

///|
async test "actual lifecycle fault checkpoints deny availability and release reservations" {
  for
    stage in [
      "part_create", "part_write", "part_sync", "object_rename", "after_object_rename",
      "index_write", "index_rename",
    ] {
    let root = @fs.realpath(@fs.tmpdir(prefix="town-store-fault-"))
    defer (@fs.rmdir(root, recursive=true) catch { _ => () })
    let fail_once = Ref(true)
    let store : PortableStore = {
      root,
      limits: test_limits(),
      before_io: Some(current => {
        if current == stage && fail_once.val {
          fail_once.val = false
          fail("injected storage failure")
        }
      }),
    }
    let bytes = b"fault bytes"
    let binding = test_binding(bytes, "listing-fault")
    expect_code(503, () => ignore(test_upload(store, binding, bytes)))
    let index = store.with_index(index => index)
    assert_eq(index.reservations.length(), 0)
    assert_false(
      index.packages.any(p => p.status == "available" || p.receipt is Some(_)),
    )
    assert_eq(@fs.readdir(root + "/objects").length(), 0)
    assert_eq(@fs.readdir(root + "/incoming").length(), 0)
  }
}

///|
async test "failed repair retains original receipts and grants then exact repair restores bytes" {
  let root = @fs.realpath(@fs.tmpdir(prefix="town-store-repair-"))
  defer (@fs.rmdir(root, recursive=true) catch { _ => () })
  let clean = portable_store(root, limits=test_limits())
  let bytes = b"old immutable bytes"
  let binding = test_binding(bytes, "listing-repair")
  let view = test_upload(clean, binding, bytes)
  let grant = clean.grant(
    owner_actor(),
    test_draft(view, "repair-grant"),
    110UL,
  )
  @fs.remove(clean.object_path(view.package_id))
  for
    stage in ["part_write", "part_sync", "object_rename", "after_object_rename"] {
    let store : PortableStore = {
      root,
      limits: test_limits(),
      before_io: Some(current => if current == stage { fail("repair failed") }),
    }
    expect_code(503, () => ignore(test_upload(store, binding, bytes)))
    let recovered = clean.get(
      owner_actor(),
      view.package_id,
      binding.binding_digest,
      120UL,
    )
    assert_eq(recovered.receipt, view.receipt)
    assert_eq(recovered.grants, [grant])
    assert_eq(clean.load_index().reservations.length(), 0)
  }
  assert_eq(test_upload(clean, binding, bytes).receipt, view.receipt)
  let download = clean.download(
    recipient_actor(),
    view.package_id,
    binding.binding_digest,
    120UL,
  )
  download.close()
}

///|
async test "cleanup failures stay durable charged and withdrawal never revives" {
  let root = @fs.realpath(@fs.tmpdir(prefix="town-store-cleanup-"))
  defer (@fs.rmdir(root, recursive=true) catch { _ => () })
  let limits = {
    ..test_limits(),
    max_package_bytes: 64,
    max_retained_bytes: 64,
  }
  let clean = portable_store(root, limits~)
  let bytes = Bytes::make(64, b'x')
  let binding = test_binding(bytes, "listing-cleanup")
  let failing : PortableStore = {
    root,
    limits,
    before_io: Some(stage => {
      if stage == "part_sync" || stage == "unlink" {
        fail("disk or unlink failed")
      }
    }),
  }
  expect_code(503, () => ignore(test_upload(failing, binding, bytes)))
  let index = clean.load_index()
  assert_eq(index.reservations.length(), 1)
  assert_true(index.reservations[0].cleanup_pending)
  expect_code(413, () => {
    ignore(clean.reserve(owner_actor(), test_binding(bytes, "other"), 101UL))
  })
  clean.recover(2000UL)
  assert_eq(clean.load_index().reservations.length(), 0)
  let view = test_upload(clean, binding, bytes)
  ignore(clean.grant(owner_actor(), test_draft(view, "withdraw-grant"), 110UL))
  let withdrawing : PortableStore = {
    root,
    limits,
    before_io: Some(stage => if stage == "unlink" { fail("unlink failed") }),
  }
  let withdrawn = withdrawing.withdraw(
    owner_actor(),
    view.package_id,
    binding.binding_digest,
    120UL,
  )
  assert_eq(withdrawn.status, "withdrawn")
  assert_true(withdrawn.cleanup_pending)
  assert_true(withdrawn.grants[0].revoked_at_ms is Some(_))
  expect_code(403, () => {
    ignore(
      clean.download(
        recipient_actor(),
        view.package_id,
        binding.binding_digest,
        130UL,
      ),
    )
  })
  expect_code(413, () => {
    ignore(clean.reserve(owner_actor(), test_binding(bytes, "other"), 130UL))
  })
  clean.recover(2000UL)
  assert_false(
    clean.get(owner_actor(), view.package_id, binding.binding_digest, 130UL).cleanup_pending,
  )
  expect_code(409, () => ignore(test_upload(clean, binding, bytes)))
}

///|
async test "slow read total deadline cancellation truncation and mismatches expose no available record" {
  let root = @fs.realpath(@fs.tmpdir(prefix="town-store-abort-"))
  defer (@fs.rmdir(root, recursive=true) catch { _ => () })
  let limits = { ..test_limits(), idle_timeout_ms: 10, total_timeout_ms: 30, }
  let store = portable_store(root, limits~)
  let bytes = b"expected"
  let binding = test_binding(bytes, "listing-abort")
  for supplied in [b"short", b"expected-extra", b"different"] {
    expect_code(422, () => ignore(test_upload(store, binding, supplied)))
  }
  let broken = @io.MemoryReader(_ => raise @io.ReaderClosed)
  defer broken.close()
  expect_code(422, () => {
    ignore(store.upload(owner_actor(), binding, broken, () => (), () => 100UL))
  })
  let slow = @io.MemoryReader(writer => {
    @async.sleep(100)
    writer.write(bytes)
  })
  defer slow.close()
  expect_code(408, () => {
    ignore(store.upload(owner_actor(), binding, slow, () => (), () => 100UL))
  })
  let busy = @io.MemoryReader(writer => {
    for b in bytes {
      writer.write(Bytes::from_array([b]))
      @async.sleep(7)
    }
  })
  defer busy.close()
  expect_code(408, () => {
    ignore(store.upload(owner_actor(), binding, busy, () => (), () => 100UL))
  })
  @async.with_task_group(group => {
    let started = Ref(false)
    let task = group.spawn(() => {
      let body = @io.MemoryReader(writer => {
        started.val = true
        @async.sleep(100)
        writer.write(bytes)
      })
      defer body.close()
      ignore(store.upload(owner_actor(), binding, body, () => (), () => 100UL))
    })
    while !started.val {
      @async.sleep(1)
    }
    task.cancel()
    task.wait() catch {
      error => assert_true(@async.is_cancellation_error(error))
    }
  })
  let index = store.load_index()
  assert_eq(index.reservations.length(), 0)
  assert_true(
    index.packages.all(p => p.receipt is None && p.status == "uploading"),
  )
}
