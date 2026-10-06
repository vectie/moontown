///| A publisher-declared description of a file carried outside Town. Town

///|
/// validates metadata only; the recipient verifies the actual local file.
pub(all) struct PortableSource {
  contract : String
  bundle_contract : String
  agent_id : String
  agent_version : String
  book_revision : String
  bundle_digest : String
  package_filename : String
  package_size_bytes : Int
  package_sha256 : String
  file_count : Int
  total_decoded_bytes : Int
  outputs_manifest_path : String?
  outputs_manifest_digest : String?
  included_output_count : Int
  reference_only_count : Int
  transport : String
} derive(Debug, Eq)

///|
pub impl ToJson for PortableSource with fn to_json(self) {
  canonical_portable_source(self)
}

///|
pub impl @json.FromJson for PortableSource with fn from_json(value, path) {
  parse_portable_source(value) catch {
    error =>
      raise @json.JsonDecodeError((path, "invalid portable source: \{error}"))
  }
}

///|
/// Independent from the legacy listing/card digest and runtime authority.
pub(all) struct PortableListingBinding {
  contract : String
  listing_id : String
  publisher_principal_id : String
  tenant_id : String
  binding_revision : Int
  source : PortableSource
  reuse_mode : String
  verification_scope : String
  binding_digest : String
} derive(Debug, Eq, ToJson, FromJson)

///|
fn canonical_portable_source(source : PortableSource) -> Json {
  {
    "contract": source.contract,
    "bundle_contract": source.bundle_contract,
    "agent_id": source.agent_id,
    "agent_version": source.agent_version,
    "book_revision": source.book_revision,
    "bundle_digest": source.bundle_digest,
    "package_filename": source.package_filename,
    "package_size_bytes": source.package_size_bytes,
    "package_sha256": source.package_sha256,
    "file_count": source.file_count,
    "total_decoded_bytes": source.total_decoded_bytes,
    "outputs_manifest_path": optional_string_wire(source.outputs_manifest_path),
    "outputs_manifest_digest": optional_string_wire(
      source.outputs_manifest_digest,
    ),
    "included_output_count": source.included_output_count,
    "reference_only_count": source.reference_only_count,
    "transport": source.transport,
  }
}

///|
fn portable_binding_identity(binding : PortableListingBinding) -> Json {
  {
    "contract": binding.contract,
    "listing_id": binding.listing_id,
    "publisher_principal_id": binding.publisher_principal_id,
    "tenant_id": binding.tenant_id,
    "binding_revision": binding.binding_revision,
    "source": canonical_portable_source(binding.source),
    "reuse_mode": binding.reuse_mode,
    "verification_scope": binding.verification_scope,
  }
}

///|
fn valid_portable_digest(value : String) -> Bool {
  if !value.has_prefix("sha256:") || value.length() != 71 {
    return false
  }
  for char in value[7:] {
    if !((char >= '0' && char <= '9') || (char >= 'a' && char <= 'f')) {
      return false
    }
  }
  true
}

///|
/// Only package-relative member names, never host paths or URLs.
fn valid_portable_member_path(value : String) -> Bool {
  if value.is_empty() ||
    value.length() > 512 ||
    value.contains("\\") ||
    value.contains(":") ||
    value.contains("\u0000") {
    return false
  }
  for part in value.split("/") {
    if part.is_empty() || part == "." || part == ".." {
      return false
    }
  }
  true
}

///|
fn validate_portable_source(source : PortableSource) -> Unit raise {
  if source.contract != "moonbook.portable_source.v1" ||
    source.bundle_contract != "moonbook.agent_bundle.v1" ||
    source.transport != "local_file" {
    fail("unsupported portable source contract or transport")
  }
  for value in [source.agent_id, source.agent_version, source.book_revision] {
    if value.is_empty() ||
      value.length() > 256 ||
      value != value.trim().to_owned() {
      fail("portable source identity fields must be nonempty canonical strings")
    }
    for char in value {
      if char < ' ' || char == '\u007f' {
        fail("portable source identity contains a control character")
      }
    }
  }
  if !valid_portable_digest(source.book_revision) ||
    !valid_portable_digest(source.bundle_digest) ||
    !valid_portable_digest(source.package_sha256) {
    fail("portable source requires canonical sha256 digests")
  }
  if !valid_portable_member_path(source.package_filename) ||
    source.package_filename.contains("/") ||
    !source.package_filename.has_suffix(".moonbook-agent") {
    fail("portable package filename must be a .moonbook-agent basename")
  }
  if source.package_size_bytes <= 0 ||
    source.file_count <= 0 ||
    source.total_decoded_bytes < 0 ||
    source.included_output_count < 0 ||
    source.reference_only_count < 0 ||
    source.included_output_count > source.file_count {
    fail("portable source has invalid sizes or counts")
  }
  match (source.outputs_manifest_path, source.outputs_manifest_digest) {
    (None, None) =>
      if source.included_output_count != 0 || source.reference_only_count != 0 {
        fail("portable output counts require an outputs manifest")
      }
    (Some(path), Some(digest)) =>
      if path != "portable/outputs.manifest.v1.json" ||
        !valid_portable_digest(digest) {
        fail("portable outputs manifest path or digest is invalid")
      }
    _ => fail("portable outputs manifest path and digest must be paired")
  }
}

///| All v1 descriptor keys are required, including explicit null manifest

///|
/// keys. Reject extra keys rather than persisting arbitrary private material.
fn parse_portable_source(value : Json) -> PortableSource raise {
  guard value is Object(fields) else {
    fail("portable_source must be an object")
  }
  let keys = [
    "contract", "bundle_contract", "agent_id", "agent_version", "book_revision",
    "bundle_digest", "package_filename", "package_size_bytes", "package_sha256",
    "file_count", "total_decoded_bytes", "outputs_manifest_path", "outputs_manifest_digest",
    "included_output_count", "reference_only_count", "transport",
  ]
  if fields.length() != keys.length() ||
    keys.any(key => fields.get(key) is None) {
    fail("portable_source must contain exactly the required v1 fields")
  }
  let source : PortableSource = {
    contract: @json.from_json(fields["contract"]),
    bundle_contract: @json.from_json(fields["bundle_contract"]),
    agent_id: @json.from_json(fields["agent_id"]),
    agent_version: @json.from_json(fields["agent_version"]),
    book_revision: @json.from_json(fields["book_revision"]),
    bundle_digest: @json.from_json(fields["bundle_digest"]),
    package_filename: @json.from_json(fields["package_filename"]),
    package_size_bytes: portable_source_int(fields["package_size_bytes"]),
    package_sha256: @json.from_json(fields["package_sha256"]),
    file_count: portable_source_int(fields["file_count"]),
    total_decoded_bytes: portable_source_int(fields["total_decoded_bytes"]),
    outputs_manifest_path: portable_source_nullable_string(
      fields["outputs_manifest_path"],
    ),
    outputs_manifest_digest: portable_source_nullable_string(
      fields["outputs_manifest_digest"],
    ),
    included_output_count: portable_source_int(fields["included_output_count"]),
    reference_only_count: portable_source_int(fields["reference_only_count"]),
    transport: @json.from_json(fields["transport"]),
  }
  validate_portable_source(source)
  source
}

///|
fn portable_source_int(value : Json) -> Int raise {
  let number : Int = @json.from_json(value)
  guard value is Number(raw, ..) && raw == number.to_double() else {
    fail("portable source counts and sizes must be exact integers")
  }
  number
}

///|
fn portable_source_nullable_string(value : Json) -> String? raise {
  match value {
    Null => None
    String(value) => Some(value)
    _ => fail("portable source manifest fields must be null or string")
  }
}

///| The additive intake lives outside AgentListingDraft so legacy canonical

///|
/// card hashes remain byte-for-byte unchanged.
fn parse_portable_source_intake(payload : Json) -> PortableSource? raise {
  guard payload is Object(fields) else { fail("agent draft must be an object") }
  match fields.get("portable_source") {
    None | Some(Null) => None
    Some(value) => Some(parse_portable_source(value))
  }
}

///|
fn portable_binding_by_listing(
  state : MarketplaceState,
  listing_id : String,
) -> PortableListingBinding? {
  for binding in state.portable_bindings {
    if binding.listing_id == listing_id {
      return Some(binding)
    }
  }
  None
}

///|
fn portable_binding_wire(state : MarketplaceState, listing_id : String) -> Json {
  match portable_binding_by_listing(state, listing_id) {
    None => Json::null()
    Some(binding) => binding.to_json()
  }
}

///| Called only after existing listing-owner authorization. Omission after

///|
/// first attachment is a removal attempt; a new file needs a new listing ID.
fn bind_portable_source(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  listing_id : String,
  source : PortableSource?,
) -> Array[PortableListingBinding] raise {
  let prior = portable_binding_by_listing(state, listing_id)
  match (prior, source) {
    (None, None) => state.portable_bindings
    (Some(_), None) =>
      fail("portable source binding cannot be removed; use a new listing ID")
    (Some(binding), Some(source)) => {
      validate_portable_source(source)
      if binding.source != source ||
        binding.publisher_principal_id != principal.principal_id ||
        binding.tenant_id != principal.tenant_id {
        fail("portable source binding is immutable; use a new listing ID")
      }
      state.portable_bindings
    }
    (None, Some(source)) => {
      validate_portable_source(source)
      let unsigned : PortableListingBinding = {
        contract: "moontown.portable-listing-binding.v1",
        listing_id,
        publisher_principal_id: principal.principal_id,
        tenant_id: principal.tenant_id,
        binding_revision: 1,
        source,
        reuse_mode: "local_file_import",
        verification_scope: "publisher_declared_expected_source",
        binding_digest: "",
      }
      let bindings = state.portable_bindings.copy()
      bindings.push({
        ..unsigned,
        binding_digest: sha256_text(
          portable_binding_identity(unsigned).stringify(),
        ),
      })
      bindings
    }
  }
}

///|
/// Fail closed for corrupt or conflicting on-disk bindings on restart.
fn validate_persisted_portable_bindings(state : MarketplaceState) -> Unit raise {
  let seen : Array[String] = []
  for binding in state.portable_bindings {
    validate_portable_source(binding.source)
    if seen.contains(binding.listing_id) ||
      binding.contract != "moontown.portable-listing-binding.v1" ||
      binding.binding_revision != 1 ||
      binding.reuse_mode != "local_file_import" ||
      binding.verification_scope != "publisher_declared_expected_source" ||
      binding.binding_digest !=
      sha256_text(portable_binding_identity(binding).stringify()) ||
      !state.agent_listings.any(listing => {
        listing.listing_id == binding.listing_id &&
        listing.publisher_id == binding.publisher_principal_id &&
        listing.tenant_id == binding.tenant_id
      }) {
      fail("invalid persisted portable listing binding")
    }
    seen.push(binding.listing_id)
  }
}

///| Only private, owner/grant-authorized detail is extended. Public card and

///|
/// hosted action contracts are unchanged; no payload bytes are hosted here.
fn attach_private_portable_binding(
  state : MarketplaceState,
  listing_id : String,
  projection : Json,
) -> Json {
  guard portable_binding_by_listing(state, listing_id) is Some(binding) else {
    return projection
  }
  guard projection is Object(fields) else { return projection }
  fields["contract_id"] = "moontown.private-listing-share-preview.v2".to_json()
  fields["portable_binding"] = binding.to_json()
  fields["portable_import_instruction"] = "Choose the matching package file, supplied separately, and verify it locally before importing into a new Book.".to_json()
  Json::object(fields)
}
