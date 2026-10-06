///|
fn validate_download_headers(
  view : @transfer.PackageView,
  response : @http.Response,
  limits : @transfer.TransferLimits,
) -> Unit raise {
  response_identity(response)
  if response.code != 200 {
    raise ClientError("download_http_status_\{response.code}")
  }
  let source = view.binding.source
  let headers = response.headers
  if headers.get("content-type") != Some("application/octet-stream") ||
    headers.get("x-town-package-id") != Some(view.package_id) ||
    headers.get("x-town-binding-digest") != Some(view.binding.binding_digest) ||
    headers.get("x-town-package-sha256") != Some(source.package_sha256) ||
    response_length(response, limits.max_package_bytes) !=
    source.package_size_bytes ||
    headers.contains("content-range") ||
    headers.get("x-content-type-options") != Some("nosniff") ||
    headers.get("content-disposition") !=
    Some("attachment; filename=\"\{view.package_id}.moonbook-agent\"") {
    raise ClientError("download_header_mismatch")
  }
  let cache = headers
    .get("cache-control")
    .unwrap_or("")
    .split(",")
    .map(s => s.trim().to_owned())
    .collect()
  if !cache.contains("private") ||
    !cache.contains("no-store") ||
    !cache.contains("no-transform") {
    raise ClientError("unsafe_download_cache_policy")
  }
}

///|
async fn require_new_output(path : String) -> Unit {
  // lstat catches even a dangling symlink; exists() alone follows it.
  let exists = try @fs.kind(path, follow_symlink=false) catch {
    _ => false
  } noraise {
    _ => true
  }
  if exists {
    raise ClientError("output_already_exists")
  }
}

///|
async fn remove_owned(paths : Array[String]) -> Unit {
  let failed = Ref(false)
  @async.protect_from_cancel(() => {
    for path in paths {
      @fs.remove(path) catch {
        _ => failed.val = true
      }
    }
  })
  if failed.val {
    raise ClientError("incomplete_download_cleanup_failed")
  }
}

///|
/// Real streaming receive seam shared by the native client and socket-free
/// handler acceptance tests. The chosen output is exposed only after exact
/// bytes and private binding/receipt sidecars are fully written and synced.
/// All three destinations must be new; a racing existing file is never replaced.
pub async fn receive_download(
  view : @transfer.PackageView,
  response : @http.Response,
  reader : &@io.Reader,
  output_path : String,
  limits? : @transfer.TransferLimits = @transfer.default_limits(),
) -> DownloadedPackage {
  receive_download_impl(view, response, reader, output_path, limits, _ => ())
}

///|
/// Private stage observer enables deterministic failure/cancellation tests on
/// the same commit code used in production. No filesystem implementation is
/// substituted, and the public path supplies a no-op observer.
async fn receive_download_impl(
  view : @transfer.PackageView,
  response : @http.Response,
  reader : &@io.Reader,
  output_path : String,
  limits : @transfer.TransferLimits,
  after_step : async (String) -> Unit,
) -> DownloadedPackage {
  validate_limits(limits)
  validate_view(view, limits, available=true)
  validate_download_headers(view, response, limits)
  if output_path.is_empty() ||
    output_path.has_suffix("/") ||
    output_path.contains("\u0000") {
    raise ClientError("invalid_output_path")
  }
  let binding_path = output_path + ".binding.json"
  let receipt_path = output_path + ".receipt.json"
  for path in [output_path, binding_path, receipt_path] {
    require_new_output(path)
  }
  // CreateNew and 0600 are the security boundary; randomness avoids ordinary
  // collisions, it is not used as a capability or credential.
  let suffix = "\{@async.now()}-\{@random.Rand::new().uint64()}"
  let temp = output_path + ".part-" + suffix
  let binding_temp = temp + ".binding.json"
  let receipt_temp = temp + ".receipt.json"
  let owned : Array[String] = []
  let opened : Ref[@fs.File?] = Ref(None)
  let committed = Ref(false)
  @async.with_timeout(limits.total_timeout_ms, () => {
    let file = @fs.open(
      temp,
      mode=WriteOnly,
      create_mode=CreateNew,
      permission=0o600,
      sync=Full,
    )
    owned.push(temp)
    opened.val = Some(file)
    let hash = @crypto.SHA256::new()
    let expected = view.binding.source.package_size_bytes
    for count = 0 {
      let part = @async.with_timeout(limits.idle_timeout_ms, () => {
        reader.read_some(
          max_len=Int::min(limits.chunk_bytes, expected - count + 1),
        )
      })
      guard part is Some(bytes) else {
        if count != expected {
          raise ClientError("download_length_mismatch")
        }
        break
      }
      if bytes.length() > expected - count {
        raise ClientError("download_length_mismatch")
      }
      hash.update(bytes)
      @async.with_timeout(limits.idle_timeout_ms, () => file.write(bytes))
      continue count + bytes.length()
    }
    if finish_digest(hash) != view.binding.source.package_sha256 {
      raise ClientError("download_digest_mismatch")
    }
    file.sync()
    after_step("package_synced")
    file.close()
    opened.val = None
    let binding_file = @fs.open(
      binding_temp,
      mode=WriteOnly,
      create_mode=CreateNew,
      permission=0o600,
      sync=Full,
    )
    owned.push(binding_temp)
    opened.val = Some(binding_file)
    binding_file.write(view.binding.to_json().stringify(indent=2))
    binding_file.sync()
    after_step("binding_synced")
    binding_file.close()
    opened.val = None
    let receipt_file = @fs.open(
      receipt_temp,
      mode=WriteOnly,
      create_mode=CreateNew,
      permission=0o600,
      sync=Full,
    )
    owned.push(receipt_temp)
    opened.val = Some(receipt_file)
    guard view.receipt is Some(receipt) else {
      raise ClientError("missing_byte_receipt")
    }
    receipt_file.write(receipt.to_json().stringify(indent=2))
    receipt_file.sync()
    after_step("receipt_synced")
    receipt_file.close()
    opened.val = None
    // No await/cancellation gap may detach a completed rename from ownership
    // tracking. Package filename is the final commit point, after both sidecars.
    @async.protect_from_cancel(() => {
      @fs.rename(binding_temp, binding_path, replace=false)
      owned[1] = binding_path
      after_step("binding_exposed")
      @fs.rename(receipt_temp, receipt_path, replace=false)
      owned[2] = receipt_path
      after_step("receipt_exposed")
      @fs.rename(temp, output_path, replace=false)
      owned[0] = output_path
      committed.val = true
      after_step("committed")
    })
  }) catch {
    error => {
      if opened.val is Some(file) {
        file.close()
      }
      // The final rename is the commit point. A delayed cancellation must not
      // remove an already verified package with both durable sidecars.
      if !committed.val {
        remove_owned(owned)
        match error {
          ClientError(_) as error => raise error
          _ => raise ClientError("download_failed")
        }
      }
    }
  }
  {
    package_path: output_path,
    binding_path,
    receipt_path,
    package_id: view.package_id,
    package_sha256: view.binding.source.package_sha256,
    package_size_bytes: view.binding.source.package_size_bytes,
  }
}

///|
/// Fetch current authorized exact metadata first; never substitute latest,
/// title matches or a caller-invented receipt.
pub async fn PortableClient::download(
  self : PortableClient,
  package_id : String,
  binding : @marketplace.PortableListingBinding,
  output_path : String,
) -> DownloadedPackage {
  validate_binding(binding, self.limits)
  if package_id != @transfer.package_id(binding.binding_digest) {
    raise ClientError("package_identity_mismatch")
  }
  let selected : Ref[@transfer.PackageView?] = Ref(None)
  for view in self.list() {
    if view.package_id == package_id {
      selected.val = Some(view)
    }
  }
  guard selected.val is Some(view) else {
    raise ClientError("package_not_authorized")
  }
  if view.binding != binding {
    raise ClientError("package_identity_mismatch")
  }
  validate_view(view, self.limits, available=true)
  let headers = self.headers()
  headers["x-town-binding-digest"] = binding.binding_digest
  headers["accept"] = "application/octet-stream"
  let result : Ref[DownloadedPackage?] = Ref(None)
  let request : @http.Request = {
    meth: Get,
    path: route_root + "/content?package_id=" + package_id,
    headers,
  }
  @async.with_timeout(self.limits.total_timeout_ms, () => {
    (self.exchange)(request, _ => (), (response, reader) => {
      if result.val is Some(_) {
        raise ClientError("duplicate_response")
      }
      result.val = Some(
        receive_download(
          view,
          response,
          reader,
          output_path,
          limits=self.limits,
        ),
      )
    })
  }) catch {
    ClientError(_) as error => raise error
    _ => raise ClientError("download_failed")
  }
  guard result.val is Some(result) else {
    raise ClientError("missing_response")
  }
  result
}
