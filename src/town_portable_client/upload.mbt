///|
async fn verify_original_file(
  file : @fs.File,
  binding : @marketplace.PortableListingBinding,
  limits : @transfer.TransferLimits,
  writer : &@io.Writer?,
) -> Unit {
  let expected = binding.source.package_size_bytes
  if file.kind() != Regular || file.size() != expected.to_int64() {
    raise ClientError("local_package_size_mismatch")
  }
  let hash = @crypto.SHA256::new()
  for offset = 0; offset < expected; {
    let count = Int::min(limits.chunk_bytes, expected - offset)
    let bytes = @async.with_timeout(limits.idle_timeout_ms, () => {
      file.read_exactly_at(count, position=offset.to_int64())
    })
    hash.update(bytes)
    if writer is Some(writer) {
      @async.with_timeout(limits.idle_timeout_ms, () => writer.write(bytes))
    }
    continue offset + count
  }
  if file.size() != expected.to_int64() ||
    finish_digest(hash) != binding.source.package_sha256 {
    raise ClientError("local_package_digest_mismatch")
  }
}

///|
/// Verify and stream the exact original file from the same descriptor. Nothing
/// is unpacked, repacked, imported, installed or executed.
pub async fn PortableClient::upload(
  self : PortableClient,
  file_path : String,
  listing_id : String,
  binding : @marketplace.PortableListingBinding,
) -> @transfer.PackageView {
  validate_binding(binding, self.limits)
  if listing_id != binding.listing_id {
    raise ClientError("listing_identity_mismatch")
  }
  if @fs.kind(file_path, follow_symlink=false) != Regular {
    raise ClientError("local_package_not_regular")
  }
  let file = @fs.open(file_path, mode=ReadOnly)
  defer file.close()
  let result : Ref[@transfer.PackageView?] = Ref(None)
  @async.with_timeout(self.limits.total_timeout_ms, () => {
    // Preflight completes before a session is requested or a transport invoked.
    verify_original_file(file, binding, self.limits, None)
    let headers = self.headers()
    headers["content-type"] = "application/octet-stream"
    headers["content-length"] = binding.source.package_size_bytes.to_string()
    headers["x-town-binding-digest"] = binding.binding_digest
    headers["accept"] = "application/json"
    let sent = Ref(false)
    let request : @http.Request = {
      meth: Put,
      path: route_root + "/content?listing_id=" + listing_id,
      headers,
    }
    (self.exchange)(
      request,
      writer => {
        if sent.val {
          raise ClientError("duplicate_request_body")
        }
        sent.val = true
        verify_original_file(file, binding, self.limits, Some(writer))
      },
      (response, reader) => {
        if result.val is Some(_) || !sent.val {
          raise ClientError("invalid_exchange_order")
        }
        let view : @transfer.PackageView = @json.from_json(
          read_payload(response, reader, self.limits.idle_timeout_ms),
        ) catch {
          ClientError(_) as error => raise error
          _ => raise ClientError("invalid_package_metadata")
        }
        validate_view(view, self.limits, available=true)
        if view.binding != binding {
          raise ClientError("package_identity_mismatch")
        }
        result.val = Some(view)
      },
    )
  }) catch {
    ClientError(_) as error => raise error
    _ => raise ClientError("upload_failed")
  }
  guard result.val is Some(result) else {
    raise ClientError("missing_response")
  }
  result
}
