///|
priv struct ReceiptSource {
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
} derive(FromJson)

///|
priv struct Receipt {
  contract : String
  source : ReceiptSource
  listing_id : String
  publisher_principal_id : String
  tenant_id : String
  binding_digest : String
  installation_receipt_id : String
  local_target_root : String
  local_book_id : String
  imported_at : Int64
  member_bytes_verified : Bool
  status : String
} derive(FromJson)

///|
priv struct Manifest {
  contract : String
  outputs : Array[@contract.Output]
} derive(FromJson)

///|
fn validate_receipt(
  receipt : Receipt,
  root : String,
  book_id : String,
) -> Unit raise {
  let source = receipt.source
  guard receipt.contract == "moonbook.portable_import_receipt.v1" &&
    receipt.status == "complete" &&
    receipt.member_bytes_verified &&
    receipt.local_target_root == root &&
    receipt.local_book_id == book_id &&
    !receipt.listing_id.trim().is_empty() &&
    !receipt.publisher_principal_id.trim().is_empty() &&
    !receipt.tenant_id.trim().is_empty() &&
    !receipt.installation_receipt_id.trim().is_empty() &&
    @contract.digest_valid(receipt.binding_digest) &&
    receipt.imported_at >= 0L &&
    source.contract == "moonbook.portable_source.v1" &&
    source.bundle_contract == "moonbook.agent_bundle.v1" &&
    source.transport == "local_file" &&
    !source.agent_id.trim().is_empty() &&
    !source.agent_version.trim().is_empty() &&
    @contract.relative_path_valid(source.package_filename) &&
    !source.package_filename.contains("/") &&
    source.package_size_bytes > 0 &&
    source.package_size_bytes <= 64 * 1024 * 1024 &&
    source.file_count >= 0 &&
    source.file_count <= 100000 &&
    source.total_decoded_bytes >= 0 &&
    source.included_output_count >= 0 &&
    source.reference_only_count >= 0 &&
    @contract.digest_valid(source.package_sha256) &&
    @contract.digest_valid(source.book_revision) &&
    @contract.digest_valid(source.bundle_digest) else {
    fail("Exact-import receipt or local Book identity is invalid or changed")
  }
  match (source.outputs_manifest_path, source.outputs_manifest_digest) {
    (None, None) if source.included_output_count == 0 &&
      source.reference_only_count == 0 => ()
    (Some("portable/outputs.manifest.v1.json"), Some(digest)) if @contract.digest_valid(
        digest,
      ) => ()
    _ => fail("Exact-import manifest identity is invalid")
  }
}

///|
fn validate_manifest(manifest : Manifest, source : ReceiptSource) -> Unit raise {
  guard manifest.contract == "moonbook.portable_outputs.v1" &&
    manifest.outputs.length() <= 4096 else {
    fail("Unsupported or excessive output manifest")
  }
  let mut previous_id = ""
  let mut total_members = 0
  for output in manifest.outputs {
    guard @contract.relative_path_valid(output.artifact_id) &&
      !output.artifact_id.contains("/") &&
      previous_id.compare(output.artifact_id) < 0 &&
      !output.label.trim().is_empty() &&
      output.mime_type.contains("/") &&
      output.mime_type.trim() == output.mime_type else {
      fail("Invalid output identity, ordering, label or MIME type")
    }
    previous_id = output.artifact_id
    if !output.included {
      guard output.files.is_empty() &&
        output.preview_path is None &&
        output.app_entrypoint is None &&
        output.reference is Some(reference) &&
        !reference.trim().is_empty() else {
        fail("Reference-only output must contain a reference and no members")
      }
      if output.declared_digest is Some(digest) &&
        !@contract.digest_valid(digest) {
        fail("Invalid reference digest")
      }
      continue
    }
    guard !output.files.is_empty() &&
      output.reference is None &&
      output.declared_digest is None else {
      fail("Included output must contain members only")
    }
    let mut previous_path = ""
    for member in output.files {
      total_members += 1
      guard total_members <= 8192 &&
        @contract.relative_path_valid(member.path) &&
        member.path.has_prefix("portable/outputs/" + output.artifact_id + "/") &&
        previous_path.compare(member.path) < 0 &&
        @contract.digest_valid(member.digest) &&
        member.size_bytes >= 0 &&
        member.size_bytes <= MemberLimit else {
        fail("Invalid output member path, size, digest or ordering")
      }
      previous_path = member.path
    }
    for link in [output.preview_path, output.app_entrypoint] {
      if link is Some(path) && !output.files.any(file => file.path == path) {
        fail("Preview or app entrypoint is not an included member")
      }
    }
  }
  guard manifest.outputs.filter(output => output.included).length() ==
    source.included_output_count &&
    manifest.outputs.filter(output => !output.included).length() ==
    source.reference_only_count else {
    fail("Manifest output counts changed")
  }
}

///|
async fn exact_outputs(
  root : String,
  book_id : String,
) -> (@contract.Source, Array[@contract.Output]) {
  let receipt : Receipt = @json.from_json(
    @json.parse(
      @utf8.decode(
        bounded_bytes(root, "state/portable-source-binding.json", 65536),
      ),
    ),
  )
  validate_receipt(receipt, root, book_id)
  let source : @contract.Source = {
    agent_id: receipt.source.agent_id,
    agent_version: receipt.source.agent_version,
    package_sha256: receipt.source.package_sha256,
    outputs_manifest_digest: receipt.source.outputs_manifest_digest,
  }
  guard receipt.source.outputs_manifest_digest is Some(digest) else {
    return (source, [])
  }
  let bytes = bounded_bytes(
    root,
    "portable/outputs.manifest.v1.json",
    MemberLimit,
  )
  guard hash(bytes) == digest else {
    fail("Output manifest changed since exact import")
  }
  let manifest : Manifest = @json.from_json(@json.parse(@utf8.decode(bytes)))
  validate_manifest(manifest, receipt.source)
  (source, manifest.outputs)
}
