///|
pub(all) suberror TransferError {
  TransferError(Int, String)
} derive(Debug)

///|
pub(all) struct TransferLimits {
  max_package_bytes : Int
  chunk_bytes : Int
  max_retained_bytes : Int
  idle_timeout_ms : Int
  total_timeout_ms : Int
  lease_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn default_limits() -> TransferLimits {
  {
    max_package_bytes: 67108864,
    chunk_bytes: 65536,
    max_retained_bytes: 536870912,
    idle_timeout_ms: 30000,
    total_timeout_ms: 300000,
    lease_ms: 600000UL,
  }
}

///|
/// Trusted application value. Never decode identity from an HTTP payload.
pub struct TransferActor {
  principal_id : String
  tenant_id : String
  publisher : Bool
} derive(Debug, Eq)

///|
pub fn actor_for_account(
  context : @account_system.AccountContext,
) -> TransferActor raise {
  guard context.has_entitlement(UseMarketplaceActions) else {
    raise TransferError(403, "marketplace_entitlement_required")
  }
  guard !context.user_id.is_empty() else {
    raise TransferError(401, "account_required")
  }
  {
    principal_id: context.user_id,
    tenant_id: context.active_tenant_id.unwrap_or("personal:" + context.user_id),
    publisher: context.has_entitlement(PublishTownContent),
  }
}

///|
pub(all) struct PackageByteReceipt {
  contract : String
  package_id : String
  listing_id : String
  publisher_principal_id : String
  tenant_id : String
  binding_digest : String
  package_sha256 : String
  package_size_bytes : Int
  stored_at_ms : UInt64
  byte_verification_scope : String
  delivery_transport : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct PortablePackageGrant {
  grant_id : String
  package_id : String
  binding_digest : String
  package_sha256 : String
  grantor_principal_id : String
  grantee_principal_id : String
  tenant_id : String
  permission : String
  created_at_ms : UInt64
  expires_at_ms : UInt64
  revoked_at_ms : UInt64?
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct GrantDraft {
  grant_id : String
  package_id : String
  binding_digest : String
  grantee_principal_id : String
  expires_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct PackageView {
  package_id : String
  binding : @town_marketplace.PortableListingBinding
  receipt : PackageByteReceipt?
  status : String
  access_basis : String
  cleanup_pending : Bool
  grants : Array[PortablePackageGrant]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct PortableStore {
  priv root : String
  priv limits : TransferLimits
  priv before_io : (async (String) -> Unit)?
}

///|
/// The root is a trusted internal child of the product state directory.
pub fn portable_store(
  root : String,
  limits? : TransferLimits = default_limits(),
) -> PortableStore {
  { root, limits, before_io: None, }
}

///|
/// Package-private fault seam exercises the actual lifecycle path.
async fn PortableStore::checkpoint(
  self : PortableStore,
  stage : String,
) -> Unit {
  if self.before_io is Some(check) {
    check(stage)
  }
}

///|
pub struct PackageDownload {
  view : PackageView
  priv file : @fs.File
  priv limits : TransferLimits
  priv mut closed : Bool
}

///|
priv struct StoredPackage {
  package_id : String
  binding : @town_marketplace.PortableListingBinding
  binding_digest : String
  publisher_principal_id : String
  tenant_id : String
  listing_id : String
  package_sha256 : String
  package_size_bytes : Int
  status : String
  receipt : PackageByteReceipt?
  cleanup_pending : Bool
  object_retained : Bool
  revision : UInt64
} derive(ToJson, FromJson)

///|
priv struct Reservation {
  attempt_id : String
  package_id : String
  reserved_bytes : Int
  lease_ends_ms : UInt64
  cleanup_pending : Bool
} derive(Eq, ToJson, FromJson)

///|
priv struct StoreIndex {
  schema : String
  packages : Array[StoredPackage]
  grants : Array[PortablePackageGrant]
  reservations : Array[Reservation]
  revision : UInt64
} derive(ToJson, FromJson)

///|
extend StoreIndex with ToJson::{to_json}

///|
fn empty_index() -> StoreIndex {
  {
    schema: "moontown.portable-package-store.v1",
    packages: [],
    grants: [],
    reservations: [],
    revision: 0UL,
  }
}

///|
/// Stable identity, deliberately not a bearer capability.
pub fn package_id(binding_digest : String) -> String {
  "pkg-" +
  @crypto.bytes_to_hex_string(
    @crypto.sha256(@utf8.encode("moontown.package.v1:" + binding_digest)),
  )
}

///|
fn receipt_for(record : StoredPackage, now_ms : UInt64) -> PackageByteReceipt {
  {
    contract: "moontown.portable-package-byte-receipt.v1",
    package_id: record.package_id,
    listing_id: record.listing_id,
    publisher_principal_id: record.publisher_principal_id,
    tenant_id: record.tenant_id,
    binding_digest: record.binding_digest,
    package_sha256: record.package_sha256,
    package_size_bytes: record.package_size_bytes,
    stored_at_ms: now_ms,
    byte_verification_scope: "received_raw_sha256_and_length",
    delivery_transport: "authenticated_town_download",
  }
}
