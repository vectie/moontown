///|
async test "strict index corruption fails closed without replacing durable metadata" {
  let root = @fs.tmpdir(prefix="town-store-index-")
  defer (@fs.rmdir(root, recursive=true) catch { _ => () })
  let store = portable_store(root, limits=test_limits())
  let bytes = b"durable exact bytes"
  let binding = test_binding(bytes, "listing-index")
  let view = test_upload(store, binding, bytes)
  ignore(store.grant(owner_actor(), test_draft(view, "index-grant"), 110UL))
  let original = store.load_index()
  let p = original.packages[0]
  let g = original.grants[0]
  let invalid : Array[Json] = [
    { ..original, schema: "unsupported.v2", }.to_json(),
    { ..original, packages: [p, p], }.to_json(),
    { ..original, grants: [g, g], }.to_json(),
    { ..original, packages: [{ ..p, publisher_principal_id: "other", }], }.to_json(),
    { ..original, packages: [{ ..p, tenant_id: "other", }], }.to_json(),
    { ..original, packages: [{ ..p, binding_digest: raw_digest(b"wrong"), }], }.to_json(),
    { ..original, packages: [{ ..p, package_id: "../outside", }], }.to_json(),
    { ..original, packages: [{ ..p, package_sha256: raw_digest(b"wrong"), }], }.to_json(),
    {
      ..original,
      packages: [{ ..p, package_size_bytes: p.package_size_bytes + 1, }],
    }.to_json(),
    {
      ..original,
      packages: [
        {
          ..p,
          receipt: Some({ ..p.receipt.unwrap(), delivery_transport: "public", }),
        },
      ],
    }.to_json(),
    { ..original, packages: [{ ..p, status: "withdrawn", }], }.to_json(),
    { ..original, grants: [{ ..g, permission: "collaborate", }], }.to_json(),
    { ..original, grants: [{ ..g, package_id: "missing", }], }.to_json(),
    { ..original, grants: [{ ..g, tenant_id: "other", }], }.to_json(),
    { ..original, grants: [{ ..g, revoked_at_ms: Some(1UL), }], }.to_json(),
  ]
  guard original.to_json() is Object(extra) else { fail("index") }
  extra["unexpected"] = true.to_json()
  invalid.push(Json::object(extra))
  guard original.to_json() is Object(missing) else { fail("index") }
  missing.remove("reservations")
  invalid.push(Json::object(missing))
  for corrupt in invalid {
    let text = corrupt.stringify()
    @fs.write_file(
      root + "/index.json",
      text,
      create_mode=TruncateExisting,
      sync=Full,
    )
    expect_code(503, () => ignore(store.list(owner_actor(), 120UL)))
    assert_eq(@fs.read_file(root + "/index.json").text(), text)
  }
  @fs.write_file(
    root + "/index.json",
    "{truncated",
    create_mode=TruncateExisting,
  )
  expect_code(503, () => ignore(test_upload(store, binding, bytes)))
  assert_eq(@fs.read_file(root + "/index.json").text(), "{truncated")
  @fs.write_file(
    root + "/index.json",
    original.to_json().stringify(),
    create_mode=TruncateExisting,
  )
  assert_eq(
    store.get(owner_actor(), view.package_id, binding.binding_digest, 120UL).grants,
    [g],
  )
}

///|
async test "managed namespace rejects symlinks directories and unsafe object names" {
  let root = @fs.tmpdir(prefix="town-store-paths-")
  defer (@fs.rmdir(root, recursive=true) catch { _ => () })
  let store = portable_store(root + "/private", limits=test_limits())
  let bytes = b"safe exact bytes"
  let binding = test_binding(bytes, "listing-paths")
  let view = test_upload(store, binding, bytes)
  let object = store.object_path(view.package_id)
  let outside = root + "/outside"
  @fs.write_file(outside, bytes, create_mode=CreateNew, permission=0o600)
  @fs.remove(object)
  @fs.symlink(target=outside, object)
  expect_code(503, () => {
    ignore(
      store.download(
        owner_actor(),
        view.package_id,
        binding.binding_digest,
        120UL,
      ),
    )
  })
  expect_code(503, () => ignore(test_upload(store, binding, bytes)))
  assert_eq(@fs.read_file(outside).binary(), bytes)
  @fs.remove(object)
  @fs.mkdir(object, permission=0o700)
  expect_code(503, () => {
    ignore(
      store.download(
        owner_actor(),
        view.package_id,
        binding.binding_digest,
        120UL,
      ),
    )
  })
  @fs.rmdir(object)
  @fs.write_file(
    store.root + "/objects/unexpected",
    bytes,
    create_mode=CreateNew,
    permission=0o600,
  )
  expect_code(503, () => store.recover(2000UL))
  @fs.remove(store.root + "/objects/unexpected")
  let original_index = @fs.read_file(store.root + "/index.json").binary()
  @fs.remove(store.root + "/index.json")
  @fs.symlink(target=outside, store.root + "/index.json")
  expect_code(503, () => ignore(store.list(owner_actor(), 120UL)))
  @fs.remove(store.root + "/index.json")
  @fs.write_file(
    store.root + "/index.json",
    original_index,
    create_mode=CreateNew,
    permission=0o600,
  )
  @fs.symlink(target=root + "/private", root + "/linked")
  expect_code(503, () => {
    ignore(
      portable_store(root + "/linked", limits=test_limits()).list(
        owner_actor(),
        120UL,
      ),
    )
  })
}

///|
async test "commit index failures survive restart with no authorized orphan and preserve old repair receipt" {
  for repair in [false, true] {
    for failure in ["index_write", "index_rename"] {
      let root = @fs.tmpdir(prefix="town-store-commit-")
      defer (@fs.rmdir(root, recursive=true) catch { _ => () })
      let clean = portable_store(root, limits=test_limits())
      let bytes = b"commit durable bytes"
      let binding = test_binding(bytes, "listing-commit")
      let prior = if repair {
        Some(test_upload(clean, binding, bytes))
      } else {
        None
      }
      if prior is Some(view) {
        ignore(
          clean.grant(owner_actor(), test_draft(view, "commit-grant"), 110UL),
        )
      }
      let writes = Ref(0)
      let failing : PortableStore = {
        root,
        limits: test_limits(),
        before_io: Some(stage => {
          if stage == failure {
            writes.val += 1
            // Reservation write succeeds; commit and cleanup index writes fail.
            if writes.val >= 2 {
              fail("persistent index fault")
            }
          }
        }),
      }
      expect_code(503, () => ignore(test_upload(failing, binding, bytes)))
      let durable = clean.load_index()
      assert_eq(durable.reservations.length(), 1)
      if prior is Some(view) {
        assert_eq(durable.packages[0].receipt, view.receipt)
        assert_eq(durable.grants.length(), 1)
      } else {
        assert_true(durable.packages[0].receipt is None)
        expect_code(409, () => {
          ignore(
            clean.download(
              owner_actor(),
              package_id(binding.binding_digest),
              binding.binding_digest,
              120UL,
            ),
          )
        })
      }
      clean.recover(2000UL)
      assert_eq(clean.load_index().reservations.length(), 0)
      if prior is Some(view) {
        let download = clean.download(
          recipient_actor(),
          view.package_id,
          binding.binding_digest,
          120UL,
        )
        download.close()
      } else {
        assert_eq(@fs.readdir(root + "/objects").length(), 0)
      }
    }
  }
}

///|
async test "withdraw during active upload marks cleanup pending and cannot commit" {
  let root = @fs.tmpdir(prefix="town-store-withdraw-active-")
  defer (@fs.rmdir(root, recursive=true) catch { _ => () })
  let store = portable_store(root, limits=test_limits())
  let bytes = b"active withdrawn bytes"
  let binding = test_binding(bytes, "listing-active")
  let started = Ref(false)
  let gate = @async.Mutex()
  gate.acquire()
  @async.with_task_group(group => {
    let task = group.spawn(() => {
      let reader = @io.MemoryReader(writer => {
        writer.write(bytes[:1])
        started.val = true
        gate.acquire()
        defer gate.release()
        writer.write(bytes[1:])
      })
      defer reader.close()
      expect_code(409, () => {
        ignore(
          store.upload(owner_actor(), binding, reader, () => (), () => 100UL),
        )
      })
    })
    while !started.val {
      @async.sleep(1)
    }
    let withdrawn = store.withdraw(
      owner_actor(),
      package_id(binding.binding_digest),
      binding.binding_digest,
      110UL,
    )
    assert_true(withdrawn.cleanup_pending)
    store.recover(5000UL)
    assert_eq(store.load_index().reservations.length(), 1)
    gate.release()
    task.wait()
  })
  let view = store.get(
    owner_actor(),
    package_id(binding.binding_digest),
    binding.binding_digest,
    120UL,
  )
  assert_eq(view.status, "withdrawn")
  assert_false(view.cleanup_pending)
  assert_eq(store.load_index().reservations.length(), 0)
  assert_eq(@fs.readdir(root + "/incoming").length(), 0)
}

///|
async test "cancellation immediately after durable reservation releases accounting before retry" {
  for stop_at in ["index_committed", "part_create"] {
    let root = @fs.tmpdir(prefix="town-store-cancel-reserve-")
    defer (@fs.rmdir(root, recursive=true) catch { _ => () })
    let bytes = b"reservation cancelled"
    let binding = test_binding(bytes, "listing-reserve-cancel")
    let started = Ref(false)
    let gate = @async.Mutex()
    gate.acquire()
    let store : PortableStore = {
      root,
      limits: test_limits(),
      before_io: Some(stage => {
        if stage == stop_at && !started.val {
          started.val = true
          gate.acquire()
          gate.release()
        }
      }),
    }
    @async.with_task_group(group => {
      let task = group.spawn(() => ignore(test_upload(store, binding, bytes)))
      while !started.val {
        @async.sleep(1)
      }
      task.cancel()
      task.wait() catch {
        error => assert_true(@async.is_cancellation_error(error))
      }
    })
    let clean = portable_store(root, limits=test_limits())
    assert_eq(clean.load_index().reservations.length(), 0)
    assert_eq(@fs.readdir(root + "/incoming").length(), 0)
    assert_eq(test_upload(clean, binding, bytes).status, "available")
  }
}
