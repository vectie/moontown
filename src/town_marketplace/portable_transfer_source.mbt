///|
/// Validate the unchanged v1 publisher declaration without granting byte access.
/// The transfer store uses this on its own immutable binding snapshots.
pub fn validate_portable_listing_binding(
  binding : PortableListingBinding,
) -> Unit raise {
  validate_portable_source(binding.source)
  if !valid_symbolic_id(binding.listing_id) ||
    !valid_symbolic_id(binding.publisher_principal_id) ||
    !valid_symbolic_id(binding.tenant_id) ||
    binding.contract != "moontown.portable-listing-binding.v1" ||
    binding.binding_revision != 1 ||
    binding.reuse_mode != "local_file_import" ||
    binding.verification_scope != "publisher_declared_expected_source" ||
    binding.binding_digest !=
    sha256_text(portable_binding_identity(binding).stringify()) {
    fail("invalid portable listing binding")
  }
}

///|
/// Internal service seam: an immutable active source snapshot, never a byte
/// authorization. The HTTP boundary independently resolves the real account
/// and the separate package store independently checks exact byte grants.
pub async fn MarketplaceApplication::portable_transfer_binding(
  self : MarketplaceApplication,
  listing_id : String,
) -> PortableListingBinding? {
  marketplace_store_mutex.acquire()
  defer marketplace_store_mutex.release()
  if !@fs.exists(self.state_path) {
    return None
  }
  // The legacy optional-file helper treats malformed JSON as absent. This
  // new byte boundary must distinguish absence from corruption without
  // changing legacy state migration or marketplace behavior.
  let state : MarketplaceState = @json.from_json(
    migrate_marketplace_state_json(
      @json.parse(@fs.read_file(self.state_path).text()),
    ),
  )
  if state.schema != marketplace_schema() {
    fail("unsupported marketplace state")
  }
  validate_persisted_portable_bindings(state)
  guard state.agent_listings.any(listing => {
    listing.listing_id == listing_id &&
    listing.lifecycle.state != PublicationArchived
  }) else {
    return None
  }
  portable_binding_by_listing(state, listing_id)
}
