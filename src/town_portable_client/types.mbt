///|
/// Request-scoped streaming transport. Implementations must call each callback
/// once, finish them before returning, and never retry or redirect a request.
pub type Exchange = async (
  @http.Request,
  async (&@io.Writer) -> Unit,
  async (@http.Response, &@io.Reader) -> Unit,
) -> Unit

///|
/// Errors deliberately contain stable codes only: no sessions, paths or remote
/// error bodies are reflected into diagnostics.
pub(all) suberror ClientError {
  ClientError(String)
} derive(Debug, Eq)

///|
pub struct PortableClient {
  priv session_supplier : async () -> String
  priv exchange : Exchange
  priv limits : @transfer.TransferLimits
}

///|
pub(all) struct DownloadedPackage {
  package_path : String
  binding_path : String
  receipt_path : String
  package_id : String
  package_sha256 : String
  package_size_bytes : Int
} derive(Debug, Eq, ToJson)

///|
pub fn PortableClient::new(
  session_supplier : async () -> String,
  exchange : Exchange,
  limits? : @transfer.TransferLimits = @transfer.default_limits(),
) -> PortableClient raise {
  validate_limits(limits)
  { session_supplier, exchange, limits, }
}

///|
let route_root : String = "/miniapp/marketplace/portable-packages"

///|
fn validate_limits(limits : @transfer.TransferLimits) -> Unit raise {
  if limits.chunk_bytes <= 0 ||
    limits.chunk_bytes > 1024 * 1024 ||
    limits.max_package_bytes <= 0 ||
    limits.idle_timeout_ms <= 0 ||
    limits.total_timeout_ms <= 0 {
    raise ClientError("invalid_client_limits")
  }
}

///|
fn valid_id(value : String) -> Bool {
  !value.is_empty() &&
  value.length() <= 128 &&
  value
  .iter()
  .all(c => {
    (c >= 'a' && c <= 'z') ||
    (c >= 'A' && c <= 'Z') ||
    (c >= '0' && c <= '9') ||
    c == '-' ||
    c == '_' ||
    c == '.' ||
    c == ':'
  })
}

///|
fn require_id(value : String) -> Unit raise {
  if !valid_id(value) {
    raise ClientError("invalid_identifier")
  }
}

///|
fn valid_digest(value : String) -> Bool {
  value.length() == 71 &&
  value.has_prefix("sha256:") &&
  value[7:].iter().all(c => (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'))
}

///|
fn hash_bytes(bytes : BytesView) -> String {
  "sha256:" + @crypto.bytes_to_hex_string(@crypto.sha256(bytes))
}

///|
fn finish_digest(hash : @crypto.SHA256) -> String {
  "sha256:" + @crypto.bytes_to_hex_string(hash.finalize())
}

///|
fn validate_binding(
  binding : @marketplace.PortableListingBinding,
  limits : @transfer.TransferLimits,
) -> Unit raise {
  // Roundtrip through the existing strict source parser, not a second package
  // format parser. This preserves the original v1 semantic authority.
  let _ : @marketplace.PortableSource = @json.from_json(
    binding.source.to_json(),
  ) catch {
    _ => raise ClientError("invalid_binding")
  }
  require_id(binding.listing_id)
  require_id(binding.publisher_principal_id)
  require_id(binding.tenant_id)
  if binding.contract != "moontown.portable-listing-binding.v1" ||
    binding.binding_revision != 1 ||
    binding.reuse_mode != "local_file_import" ||
    binding.verification_scope != "publisher_declared_expected_source" ||
    !valid_digest(binding.binding_digest) {
    raise ClientError("invalid_binding")
  }
  let identity : Json = {
    "contract": binding.contract,
    "listing_id": binding.listing_id,
    "publisher_principal_id": binding.publisher_principal_id,
    "tenant_id": binding.tenant_id,
    "binding_revision": binding.binding_revision,
    "source": binding.source.to_json(),
    "reuse_mode": binding.reuse_mode,
    "verification_scope": binding.verification_scope,
  }
  if hash_bytes(@utf8.encode(identity.stringify())) != binding.binding_digest {
    raise ClientError("invalid_binding_digest")
  }
  if binding.source.package_size_bytes > limits.max_package_bytes {
    raise ClientError("package_too_large")
  }
}

///|
fn validate_view(
  view : @transfer.PackageView,
  limits : @transfer.TransferLimits,
  available~ : Bool,
) -> Unit raise {
  validate_binding(view.binding, limits)
  if view.package_id != @transfer.package_id(view.binding.binding_digest) {
    raise ClientError("package_identity_mismatch")
  }
  if available && view.status != "available" {
    raise ClientError("package_unavailable")
  }
  match view.receipt {
    None => if available { raise ClientError("missing_byte_receipt") }
    Some(receipt) => {
      let binding = view.binding
      if receipt.contract != "moontown.portable-package-byte-receipt.v1" ||
        receipt.package_id != view.package_id ||
        receipt.listing_id != binding.listing_id ||
        receipt.publisher_principal_id != binding.publisher_principal_id ||
        receipt.tenant_id != binding.tenant_id ||
        receipt.binding_digest != binding.binding_digest ||
        receipt.package_sha256 != binding.source.package_sha256 ||
        receipt.package_size_bytes != binding.source.package_size_bytes ||
        receipt.byte_verification_scope != "received_raw_sha256_and_length" ||
        receipt.delivery_transport != "authenticated_town_download" {
        raise ClientError("byte_receipt_mismatch")
      }
    }
  }
}
