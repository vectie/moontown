///|
async test "raw HTTP framing rejects invalid lengths encoding types methods and ranges without consuming body" {
  let f = fixture(limits={
    ..@town_portable_transfer.default_limits(),
    max_package_bytes: 16,
    chunk_bytes: 3,
  })
  defer @fs.rmdir(f.root, recursive=true)
  let binding = f.listing(synthetic_source(b"0123456789abcdef"))
  for
    (name, value, expected) in [
      ("content-length", "", 411),
      ("content-length", "0", 411),
      ("content-length", "-1", 411),
      ("content-length", "16,16", 411),
      ("content-length", "9999999999999999999999", 413),
      ("content-length", "17", 413),
      ("content-length", "15", 422),
      ("content-type", "application/json", 415),
      ("content-encoding", "gzip", 415),
      ("transfer-encoding", "chunked", 415),
    ] {
    let request = upload_request(binding)
    request.headers[name] = value
    let consumed = Ref(0)
    let reader = observed_reader(b"0123456789abcdef", consumed)
    let record = recording()
    assert_true(f.service.handle(request, reader, record.sink()))
    assert_eq(record.code, expected)
    assert_true(record.closed)
    assert_eq(consumed.val, 0)
  }
  let request = { ..upload_request(binding), meth: @http.Post, }
  assert_eq(call(f.service, request).code, 405)
  assert_eq(call(f.service, upload_request(binding), bytes=b"short").code, 422)
  assert_eq(
    call(f.service, upload_request(binding), bytes=b"0123456789abcdefEXTRA").code,
    422,
  )
  assert_eq(
    call(f.service, upload_request(binding), bytes=b"fedcba9876543210").code,
    422,
  )
  assert_eq(
    call(f.service, upload_request(binding), bytes=b"0123456789abcdef").code,
    200,
  )
  let range = download_request(binding, session=token("publisher-a"))
  range.headers["range"] = "bytes=0-2"
  assert_eq(call(f.service, range).code, 400)
  let download = call(
    f.service,
    download_request(binding, session=token("publisher-a")),
  )
  assert_eq(download.code, 200)
  assert_eq(download.bytes(), b"0123456789abcdef")
  assert_eq(download.headers["content-length"], "16")
  assert_eq(
    download.headers["cache-control"],
    "private, no-store, no-transform",
  )
  assert_eq(download.headers["x-content-type-options"], "nosniff")
  assert_false(download.headers.contains("content-encoding"))
}

///|
async test "started binary response failure closes without appending error JSON" {
  let f = fixture(limits={
    ..@town_portable_transfer.default_limits(),
    chunk_bytes: 3,
  })
  defer @fs.rmdir(f.root, recursive=true)
  let bytes = b"original-package"
  let binding = f.listing(synthetic_source(bytes))
  assert_eq(call(f.service, upload_request(binding), bytes~).code, 200)
  let record = recording()
  let writes = Ref(0)
  let sink = response_sink(
    (code, headers) => {
      record.code = code
      record.headers = headers
    },
    chunk => {
      writes.val = writes.val + 1
      if writes.val == 2 {
        fail("synthetic sink interruption")
      }
      record.chunks.push(chunk)
    },
    () => record.finished = true,
    () => record.closed = true,
  )
  let body = observed_reader(b"", Ref(0))
  assert_true(
    f.service.handle(
      download_request(binding, session=token("publisher-a")),
      body,
      sink,
    ),
  )
  assert_eq(record.code, 200)
  assert_eq(record.headers["content-type"], "application/octet-stream")
  assert_eq(record.bytes(), b"ori")
  assert_true(record.closed)
  assert_false(record.finished)
}

///|
async test "oversized metadata fails explicitly before response start without truncation" {
  let record = recording()
  let sink = record.sink()
  try sink.json(200, "x".repeat(8 * 1024 * 1024).to_json()) catch {
    @town_portable_transfer.TransferError(code, reason) => {
      assert_eq(code, 503)
      assert_eq(reason, "package_metadata_capacity")
    }
    _ => fail("expected explicit metadata capacity error")
  } noraise {
    _ => fail("oversized metadata must not be truncated")
  }
  assert_eq(record.code, 0)
  assert_true(record.chunks.is_empty())
}

///|
struct StalledReader {
  buffer : @io.ReaderBuffer
  gate : @async.Semaphore
  mut read_calls : Int
  mut cancelled : Bool
}

///|
impl @io.Reader for StalledReader with fn _get_internal_buffer(self) {
  self.buffer
}

///|
impl @io.Reader for StalledReader with fn _direct_read(
  self,
  target,
  offset~,
  max_len~,
) {
  ignore((target, offset, max_len))
  self.read_calls += 1
  self.gate.acquire() catch {
    error => {
      self.cancelled = @async.is_cancellation_error(error)
      raise error
    }
  }
  fail("stalled reader must only finish by cancellation")
}

///|
async test "binary chunks idle timeout and strict control field checks" {
  let f = fixture(limits={
    ..@town_portable_transfer.default_limits(),
    chunk_bytes: 1,
  })
  defer @fs.rmdir(f.root, recursive=true)
  let bytes : Bytes = [0, 255, 128, 13, 10, 0, 42]
  let binding = f.listing(synthetic_source(bytes))
  // Stall at the actual body read, after authorization and durable reservation.
  // A producer sleep can expire during that preflight and never exercise idle.
  let slow : StalledReader = {
    buffer: @io.ReaderBuffer::new(),
    gate: @async.Semaphore(1, initial_value=0),
    read_calls: 0,
    cancelled: false,
  }
  let timeout_limits = { ..f.service.limits, idle_timeout_ms: 20, }
  let timeout_service = {
    ..f.service,
    limits: timeout_limits,
    store: @town_portable_transfer.portable_store(
      f.root + "/packages",
      limits=timeout_limits,
    ),
  }
  let record = recording()
  assert_true(
    timeout_service.handle(upload_request(binding), slow, record.sink()),
  )
  assert_eq(slow.read_calls, 1)
  assert_true(slow.cancelled)
  assert_eq(record.code, 408)
  assert_eq(@json.parse(@utf8.decode(record.bytes())), {
    "ok": false,
    "error": "package_transfer_timeout",
  })
  assert_true(record.closed)
  // Reuse the same store to verify timeout cleanup. Normal successful I/O and
  // strict-control assertions use the normal budgets rather than racing 100 ms.
  assert_eq(call(f.service, upload_request(binding), bytes~).code, 200)
  assert_eq(
    call(f.service, download_request(binding, session=token("publisher-a"))).bytes(),
    bytes,
  )
  guard draft(binding).to_json() is Object(fields) else { fail("draft object") }
  fields["actor"] = "publisher-a".to_json()
  assert_eq(
    post(
      f.service,
      @town_contract.portable_package_grants_path(),
      Json::object(fields),
    ).code,
    400,
  )
  assert_eq(
    post(
      f.service,
      @town_contract.portable_package_grants_path(),
      draft(binding).to_json(),
    ).code,
    200,
  )
}
