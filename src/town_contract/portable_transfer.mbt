///|
pub fn portable_packages_path() -> String {
  "/miniapp/marketplace/portable-packages"
}

///|
pub fn portable_package_content_path() -> String {
  portable_packages_path() + "/content"
}

///|
pub fn portable_package_preview_path() -> String {
  portable_packages_path() + "/shares/preview"
}

///|
pub fn portable_package_grants_path() -> String {
  portable_packages_path() + "/share-grants"
}

///|
pub fn portable_package_revoke_path() -> String {
  portable_package_grants_path() + "/revoke"
}

///|
pub fn portable_package_withdraw_path() -> String {
  portable_packages_path() + "/withdraw"
}

///|
pub fn portable_transfer_contract() -> Json {
  {
    "contract": "moontown.portable-package-transfer.v1",
    "binding_contract": "moontown.portable-listing-binding.v1",
    "receipt_contract": "moontown.portable-package-byte-receipt.v1",
    "byte_verification_scope": "received_raw_sha256_and_length",
    "session_header": "x-miniapp-session",
    "binding_header": "x-town-binding-digest",
    "max_raw_package_bytes": 64 * 1024 * 1024,
    "chunk_bytes": 64 * 1024,
    "max_retained_reserved_bytes_per_publisher_tenant": 512 * 1024 * 1024,
    "idle_timeout_ms": 30000,
    "total_timeout_ms": 300000,
    "recovery_lease_ms": 600000,
    "ordinary_json_limit_bytes": 128 * 1024,
    "max_metadata_response_bytes": 8 * 1024 * 1024,
    "timestamp_encoding": "decimal_uint64_strings",
    "permission": "download_package",
    "metadata_grants_authorize_bytes": false,
    "automatic_install_or_execution": false,
    "endpoints": [
      endpoint(
        "portable-package-upload",
        "PUT",
        portable_package_content_path(),
        "marketplace.package.upload",
      ),
      endpoint(
        "portable-package-download",
        "GET",
        portable_package_content_path(),
        "marketplace.package.download",
      ),
      endpoint(
        "portable-package-list",
        "GET",
        portable_packages_path(),
        "marketplace.package.list",
      ),
      endpoint(
        "portable-package-preview",
        "POST",
        portable_package_preview_path(),
        "marketplace.package.preview",
      ),
      endpoint(
        "portable-package-grant",
        "POST",
        portable_package_grants_path(),
        "marketplace.package.share",
      ),
      endpoint(
        "portable-package-revoke",
        "POST",
        portable_package_revoke_path(),
        "marketplace.package.revoke",
      ),
      endpoint(
        "portable-package-withdraw",
        "POST",
        portable_package_withdraw_path(),
        "marketplace.package.withdraw",
      ),
    ],
  }
}
