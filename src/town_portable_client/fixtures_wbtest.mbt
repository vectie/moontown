///|
let fixture_bytes : Bytes = b"\x00\xff\x01a\r\n\x80\x00moon"

///|
fn fixture_limits() -> @transfer.TransferLimits {
  { ..@transfer.default_limits(), max_package_bytes: 1024, chunk_bytes: 3, }
}

///|
fn fixture_binding(
  bytes? : Bytes = fixture_bytes,
) -> @marketplace.PortableListingBinding {
  let source : @marketplace.PortableSource = {
    contract: "moonbook.portable_source.v1",
    bundle_contract: "moonbook.agent_bundle.v1",
    agent_id: "synthetic",
    agent_version: "1",
    book_revision: hash_bytes(b"book"),
    bundle_digest: hash_bytes(b"bundle"),
    package_filename: "fixture.moonbook-agent",
    package_size_bytes: bytes.length(),
    package_sha256: hash_bytes(bytes),
    file_count: 1,
    total_decoded_bytes: bytes.length(),
    outputs_manifest_path: None,
    outputs_manifest_digest: None,
    included_output_count: 0,
    reference_only_count: 0,
    transport: "local_file",
  }
  let binding : @marketplace.PortableListingBinding = {
    contract: "moontown.portable-listing-binding.v1",
    listing_id: "listing-v1",
    publisher_principal_id: "sender",
    tenant_id: "tenant",
    binding_revision: 1,
    source,
    reuse_mode: "local_file_import",
    verification_scope: "publisher_declared_expected_source",
    binding_digest: "",
  }
  let identity : Json = {
    "contract": binding.contract,
    "listing_id": binding.listing_id,
    "publisher_principal_id": binding.publisher_principal_id,
    "tenant_id": binding.tenant_id,
    "binding_revision": binding.binding_revision,
    "source": source.to_json(),
    "reuse_mode": binding.reuse_mode,
    "verification_scope": binding.verification_scope,
  }
  { ..binding, binding_digest: hash_bytes(@utf8.encode(identity.stringify())), }
}

///|
fn fixture_view(bytes? : Bytes = fixture_bytes) -> @transfer.PackageView {
  let binding = fixture_binding(bytes~)
  let package_id = @transfer.package_id(binding.binding_digest)
  let receipt : @transfer.PackageByteReceipt = {
    contract: "moontown.portable-package-byte-receipt.v1",
    package_id,
    listing_id: binding.listing_id,
    publisher_principal_id: binding.publisher_principal_id,
    tenant_id: binding.tenant_id,
    binding_digest: binding.binding_digest,
    package_sha256: binding.source.package_sha256,
    package_size_bytes: bytes.length(),
    stored_at_ms: 123UL,
    byte_verification_scope: "received_raw_sha256_and_length",
    delivery_transport: "authenticated_town_download",
  }
  {
    package_id,
    binding,
    receipt: Some(receipt),
    status: "available",
    access_basis: "owner",
    cleanup_pending: false,
    grants: [],
  }
}

///|
fn fixture_headers(view : @transfer.PackageView) -> Map[String, String] {
  {
    "content-type": "application/octet-stream",
    "content-length": view.binding.source.package_size_bytes.to_string(),
    "x-town-package-id": view.package_id,
    "x-town-binding-digest": view.binding.binding_digest,
    "x-town-package-sha256": view.binding.source.package_sha256,
    "cache-control": "private, no-store, no-transform",
    "x-content-type-options": "nosniff",
    "content-disposition": "attachment; filename=\"\{view.package_id}.moonbook-agent\"",
  }
}

///|
fn fixture_response(view : @transfer.PackageView) -> @http.Response {
  { code: 200, reason: "OK", headers: fixture_headers(view), cookies: [], }
}

///|
async fn with_temp(body : async (String) -> Unit) -> Unit {
  @async.with_task_group(group => {
    let root = @fs.tmpdir(prefix="town-portable-client")
    group.add_defer(() => {
      @async.protect_from_cancel(() => @fs.rmdir(root, recursive=true))
    })
    body(root)
  })
}

///|
struct RecordingWriter {
  buffer : Buffer
  writes : Array[Int]
}

///|
impl @io.Writer for RecordingWriter with fn write_once(
  self,
  bytes,
  offset~,
  len~,
) {
  self.writes.push(len)
  self.buffer.write_bytes(bytes[offset:offset + len])
  len
}

///|
struct ObservedReader {
  bytes : Bytes
  buffer : @io.ReaderBuffer
  mut offset : Int
  max_chunk : Int
  reads : Ref[Int]
  hidden_path : String?
  fail_after : Int?
  delay_ms : Int
}

///|
fn observed_reader(
  bytes : Bytes,
  hidden_path? : String,
  fail_after? : Int,
  delay_ms? : Int = 0,
) -> ObservedReader {
  {
    bytes,
    buffer: @io.ReaderBuffer::new(),
    offset: 0,
    max_chunk: 2,
    reads: Ref(0),
    hidden_path,
    fail_after,
    delay_ms,
  }
}

///|
impl @io.Reader for ObservedReader with fn _get_internal_buffer(self) {
  self.buffer
}

///|
impl @io.Reader for ObservedReader with fn _direct_read(
  self,
  output,
  offset~,
  max_len~,
) {
  self.reads.val += 1
  if self.hidden_path is Some(path) {
    assert_false(@fs.exists(path))
  }
  if self.fail_after is Some(bound) && self.offset >= bound {
    raise ClientError("synthetic_interruption")
  }
  if self.delay_ms > 0 {
    @async.sleep(self.delay_ms)
  }
  let n = Int::min(
    max_len,
    Int::min(self.max_chunk, self.bytes.length() - self.offset),
  )
  for i in 0..<n {
    output[offset + i] = self.bytes[self.offset + i]
  }
  self.offset += n
  n
}

///|
async fn respond_json(
  payload : Json,
  receive : async (@http.Response, &@io.Reader) -> Unit,
) -> Unit {
  let body = @utf8.encode(
    ({ "ok": true, "payload": payload } : Json).stringify(),
  )
  let reader = observed_reader(body)
  receive(
    {
      code: 200,
      reason: "OK",
      headers: {
        "content-type": "application/json",
        "content-length": body.length().to_string(),
      },
      cookies: [],
    },
    reader,
  )
}
