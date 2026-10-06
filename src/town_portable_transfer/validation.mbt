///|
fn valid_key(value : String) -> Bool {
  if value.is_empty() || value.length() > 128 {
    return false
  }
  for c in value {
    if !((c >= 'a' && c <= 'z') ||
      (c >= 'A' && c <= 'Z') ||
      (c >= '0' && c <= '9') ||
      c == '-' ||
      c == '_' ||
      c == '.' ||
      c == ':') {
      return false
    }
  }
  true
}

///|
fn valid_attempt(value : String) -> Bool {
  if value.length() != 68 || !value.has_prefix("att-") {
    return false
  }
  for c in value[4:] {
    if !((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')) {
      return false
    }
  }
  true
}

///|
fn checked_limits(limits : TransferLimits) -> Unit raise {
  guard limits.max_package_bytes > 0 &&
    limits.max_package_bytes <= 67108864 &&
    limits.chunk_bytes > 0 &&
    limits.chunk_bytes <= 65536 &&
    limits.max_retained_bytes >= limits.max_package_bytes &&
    limits.idle_timeout_ms > 0 &&
    limits.total_timeout_ms > 0 &&
    limits.lease_ms > limits.total_timeout_ms.to_uint64() else {
    raise TransferError(503, "invalid_transfer_limits")
  }
}

///|
fn find_package(index : StoreIndex, id : String) -> StoredPackage? {
  index.packages.iter().find_first(p => p.package_id == id)
}

///|
fn validate_index(index : StoreIndex) -> Unit raise {
  guard index.schema == "moontown.portable-package-store.v1" else {
    raise TransferError(503, "package_state_unavailable")
  }
  let seen : Map[String, Bool] = Map([])
  for p in index.packages {
    @town_marketplace.validate_portable_listing_binding(p.binding)
    guard !seen.contains(p.package_id) &&
      p.package_id == package_id(p.binding.binding_digest) &&
      p.binding_digest == p.binding.binding_digest &&
      p.publisher_principal_id == p.binding.publisher_principal_id &&
      p.tenant_id == p.binding.tenant_id &&
      p.listing_id == p.binding.listing_id &&
      p.package_sha256 == p.binding.source.package_sha256 &&
      p.package_size_bytes == p.binding.source.package_size_bytes &&
      p.revision > 0UL &&
      p.revision <= index.revision &&
      (
        p.status == "uploading" ||
        p.status == "available" ||
        p.status == "withdrawn"
      ) else {
      raise TransferError(503, "package_state_unavailable")
    }
    seen[p.package_id] = true
    match p.receipt {
      Some(receipt) => {
        guard receipt == receipt_for(p, receipt.stored_at_ms) &&
          p.status != "uploading" else {
          raise TransferError(503, "package_state_unavailable")
        }
      }
      None =>
        if p.status == "available" {
          raise TransferError(503, "package_state_unavailable")
        }
    }
    if p.status == "available" && (!p.object_retained || p.cleanup_pending) {
      raise TransferError(503, "package_state_unavailable")
    }
    if p.status == "uploading" && p.object_retained {
      raise TransferError(503, "package_state_unavailable")
    }
  }
  let grants : Map[String, Bool] = Map([])
  for grant in index.grants {
    guard find_package(index, grant.package_id) is Some(p) else {
      raise TransferError(503, "package_state_unavailable")
    }
    guard !grants.contains(grant.grant_id) &&
      valid_key(grant.grant_id) &&
      valid_key(grant.grantee_principal_id) &&
      grant.binding_digest == p.binding_digest &&
      grant.package_sha256 == p.package_sha256 &&
      grant.grantor_principal_id == p.publisher_principal_id &&
      grant.tenant_id == p.tenant_id &&
      grant.permission == "download_package" &&
      grant.expires_at_ms > grant.created_at_ms &&
      grant.version > 0 &&
      p.receipt is Some(_) &&
      (p.status != "withdrawn" || grant.revoked_at_ms is Some(_)) else {
      raise TransferError(503, "package_state_unavailable")
    }
    if grant.revoked_at_ms is Some(at) && at < grant.created_at_ms {
      raise TransferError(503, "package_state_unavailable")
    }
    grants[grant.grant_id] = true
  }
  let attempts : Map[String, Bool] = Map([])
  let reserved : Map[String, Bool] = Map([])
  for r in index.reservations {
    guard find_package(index, r.package_id) is Some(p) else {
      raise TransferError(503, "package_state_unavailable")
    }
    guard valid_attempt(r.attempt_id) &&
      !attempts.contains(r.attempt_id) &&
      !reserved.contains(r.package_id) &&
      r.reserved_bytes == p.package_size_bytes &&
      r.lease_ends_ms > 0UL else {
      raise TransferError(503, "package_state_unavailable")
    }
    attempts[r.attempt_id] = true
    reserved[r.package_id] = true
  }
}

///|
fn is_owner(actor : TransferActor, p : StoredPackage) -> Bool {
  actor.principal_id == p.publisher_principal_id &&
  actor.tenant_id == p.tenant_id
}

///|
fn require_owner(actor : TransferActor, p : StoredPackage) -> Unit raise {
  guard actor.publisher && is_owner(actor, p) else {
    raise TransferError(403, "package_access_denied")
  }
}

///|
fn access_basis(
  index : StoreIndex,
  actor : TransferActor,
  p : StoredPackage,
  now_ms : UInt64,
) -> String? {
  if is_owner(actor, p) {
    return Some("owner")
  }
  if p.status != "available" || actor.tenant_id != p.tenant_id {
    return None
  }
  if index.grants.any(g => {
      g.package_id == p.package_id &&
      g.binding_digest == p.binding_digest &&
      g.package_sha256 == p.package_sha256 &&
      g.tenant_id == actor.tenant_id &&
      g.grantee_principal_id == actor.principal_id &&
      g.permission == "download_package" &&
      g.revoked_at_ms is None &&
      g.created_at_ms <= now_ms &&
      g.expires_at_ms > now_ms
    }) {
    Some("download_package")
  } else {
    None
  }
}

///|
fn view_for(
  index : StoreIndex,
  p : StoredPackage,
  basis : String,
) -> PackageView {
  {
    package_id: p.package_id,
    binding: p.binding,
    receipt: p.receipt,
    status: p.status,
    access_basis: basis,
    cleanup_pending: p.cleanup_pending ||
    index.reservations.any(r => {
      r.package_id == p.package_id && r.cleanup_pending
    }),
    grants: if basis == "owner" {
      index.grants.filter(g => g.package_id == p.package_id)
    } else {
      []
    },
  }
}

///|
fn authorized(
  index : StoreIndex,
  actor : TransferActor,
  id : String,
  digest : String,
  now_ms : UInt64,
) -> (StoredPackage, String) raise {
  guard find_package(index, id) is Some(p) else {
    raise TransferError(403, "package_access_denied")
  }
  guard access_basis(index, actor, p, now_ms) is Some(basis) else {
    raise TransferError(403, "package_access_denied")
  }
  guard digest == p.binding_digest else {
    raise TransferError(409, "package_binding_conflict")
  }
  (p, basis)
}
