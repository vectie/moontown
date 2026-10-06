///|
async test "overlapping real handlers preserve independent reservations objects and grants through failed upload cleanup" {
  let f = fixture(limits={
    ..@town_portable_transfer.default_limits(),
    max_package_bytes: 64,
    max_retained_bytes: 192,
    chunk_bytes: 4,
  })
  defer @fs.rmdir(f.root, recursive=true)
  let bytes_a = b"failed-incoming-package"
  let bytes_b = b"successful-other-package"
  let bytes_c = b"independent-granted-package"
  let a = f.listing(synthetic_source(bytes_a), id="agent.concurrent-a")
  let b = f.listing(synthetic_source(bytes_b), id="agent.concurrent-b")
  let c = f.listing(synthetic_source(bytes_c), id="agent.concurrent-c")
  let other_service = {
    ..f.service,
    store: @town_portable_transfer.portable_store(
      f.root + "/packages",
      limits=f.service.limits,
    ),
  }
  let a_started = @async.Semaphore(1, initial_value=0)
  let b_started = @async.Semaphore(1, initial_value=0)
  let a_continue = @async.Semaphore(1, initial_value=0)
  let b_continue = @async.Semaphore(1, initial_value=0)
  @async.with_task_group(group => {
    let upload_a = group.spawn(() => {
      let reader = @io.MemoryReader(writer => {
        writer.write(bytes_a[:1])
        a_started.release()
        a_continue.acquire()
        fail("synthetic interrupted upload A")
      })
      defer reader.close()
      let record = recording()
      assert_true(f.service.handle(upload_request(a), reader, record.sink()))
      record
    })
    a_started.acquire()
    let upload_b = group.spawn(() => {
      let reader = @io.MemoryReader(writer => {
        writer.write(bytes_b[:1])
        b_started.release()
        b_continue.acquire()
        writer.write(bytes_b[1:])
      })
      defer reader.close()
      let record = recording()
      assert_true(
        other_service.handle(upload_request(b), reader, record.sink()),
      )
      record
    })
    b_started.acquire()
    let reads = Ref(0)
    let duplicate = recording()
    assert_true(
      other_service.handle(
        upload_request(a),
        observed_reader(bytes_a, reads),
        duplicate.sink(),
      ),
    )
    assert_eq(duplicate.code, 409)
    assert_eq(reads.val, 0)
    a_continue.release()
    let failed = upload_a.wait()
    assert_true(failed.code >= 400)
    assert_true(failed.closed)
    let owner = @town_portable_transfer.actor_for_account(
      f.service.accounts
      .resolve_portable_transfer(token("publisher-a"), now_ms=f.now.val)
      .unwrap(),
    )
    let still_active = f.service.store.get(
      owner,
      @town_portable_transfer.package_id(b.binding_digest),
      b.binding_digest,
      f.now.val,
    )
    assert_eq(still_active.status, "uploading")
    assert_eq(call(f.service, upload_request(c), bytes=bytes_c).code, 200)
    assert_eq(
      post(
        f.service,
        @town_contract.portable_package_grants_path(),
        draft(c, id="concurrent-grant").to_json(),
      ).code,
      200,
    )
    assert_eq(call(f.service, download_request(c)).bytes(), bytes_c)
    assert_eq(
      post(f.service, @town_contract.portable_package_revoke_path(), {
        "grant_id": "concurrent-grant",
      }).code,
      200,
    )
    assert_eq(call(f.service, download_request(c)).code, 403)
    b_continue.release()
    assert_eq(upload_b.wait().code, 200)
  })
  assert_eq(
    call(f.service, download_request(b, session=token("publisher-a"))).bytes(),
    bytes_b,
  )
  assert_eq(
    call(f.service, download_request(c, session=token("publisher-a"))).bytes(),
    bytes_c,
  )
  assert_false(
    @fs.exists(
      f.root +
      "/packages/objects/" +
      @town_portable_transfer.package_id(a.binding_digest) +
      ".moonbook-agent",
    ),
  )
  guard @json.parse(@fs.read_file(f.root + "/packages/index.json").text())
    is { "reservations": Array(reservations), .. } else {
    fail("index reservations required")
  }
  assert_true(reservations.is_empty())
}

///|
async test "download response idle timeout and total deadline close partial streams" {
  let f = fixture(limits={
    ..@town_portable_transfer.default_limits(),
    chunk_bytes: 3,
    idle_timeout_ms: 150,
    total_timeout_ms: 500,
  })
  defer @fs.rmdir(f.root, recursive=true)
  let bytes = b"exact-package-with-slow-writer"
  let binding = f.listing(synthetic_source(bytes))
  assert_eq(call(f.service, upload_request(binding), bytes~).code, 200)
  let slow_headers = recording()
  let sink = response_sink(
    (code, headers) => {
      slow_headers.code = code
      slow_headers.headers = headers
      @async.sleep(300)
    },
    chunk => slow_headers.chunks.push(chunk),
    () => slow_headers.finished = true,
    () => slow_headers.closed = true,
  )
  assert_true(
    f.service.handle(
      download_request(binding, session=token("publisher-a")),
      observed_reader(b"", Ref(0)),
      sink,
    ),
  )
  assert_true(slow_headers.closed)
  assert_false(slow_headers.finished)
  assert_true(slow_headers.chunks.is_empty())
  let slow_body = recording()
  let writes = Ref(0)
  let sink2 = response_sink(
    (code, headers) => {
      slow_body.code = code
      slow_body.headers = headers
    },
    chunk => {
      @async.sleep(100)
      writes.val = writes.val + 1
      slow_body.chunks.push(chunk)
    },
    () => slow_body.finished = true,
    () => slow_body.closed = true,
  )
  assert_true(
    f.service.handle(
      download_request(binding, session=token("publisher-a")),
      observed_reader(b"", Ref(0)),
      sink2,
    ),
  )
  assert_true(slow_body.closed)
  assert_false(slow_body.finished)
  assert_true(writes.val > 0)
  assert_true(slow_body.bytes().length() < bytes.length())
}
