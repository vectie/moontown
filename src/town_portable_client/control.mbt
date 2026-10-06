///|
pub async fn PortableClient::list(
  self : PortableClient,
) -> Array[@transfer.PackageView] {
  let payload = self.control(route_root, None)
  guard payload is { "packages": Array(packages), .. } else {
    raise ClientError("invalid_package_list")
  }
  let seen : Map[String, Bool] = {}
  let results = []
  for item in packages {
    let view : @transfer.PackageView = @json.from_json(item) catch {
      _ => raise ClientError("invalid_package_metadata")
    }
    validate_view(view, self.limits, available=false)
    if seen.contains(view.package_id) {
      raise ClientError("duplicate_package_identity")
    }
    seen[view.package_id] = true
    results.push(view)
  }
  results
}

///|
fn validate_draft(draft : @transfer.GrantDraft) -> Unit raise {
  require_id(draft.grant_id)
  require_id(draft.grantee_principal_id)
  if !valid_digest(draft.binding_digest) ||
    draft.package_id != @transfer.package_id(draft.binding_digest) ||
    draft.expires_at_ms == 0 {
    raise ClientError("invalid_grant_draft")
  }
}

///|
pub async fn PortableClient::preview_share(
  self : PortableClient,
  draft : @transfer.GrantDraft,
) -> Json {
  validate_draft(draft)
  self.control(route_root + "/shares/preview", Some(draft.to_json()))
}

///|
pub async fn PortableClient::share(
  self : PortableClient,
  draft : @transfer.GrantDraft,
) -> @transfer.PortablePackageGrant {
  validate_draft(draft)
  let grant : @transfer.PortablePackageGrant = @json.from_json(
    self.control(route_root + "/share-grants", Some(draft.to_json())),
  ) catch {
    _ => raise ClientError("invalid_grant_response")
  }
  if grant.grant_id != draft.grant_id ||
    grant.package_id != draft.package_id ||
    grant.binding_digest != draft.binding_digest ||
    grant.grantee_principal_id != draft.grantee_principal_id ||
    grant.expires_at_ms != draft.expires_at_ms ||
    grant.permission != "download_package" {
    raise ClientError("grant_response_mismatch")
  }
  grant
}

///|
pub async fn PortableClient::revoke(
  self : PortableClient,
  grant_id : String,
) -> @transfer.PortablePackageGrant {
  require_id(grant_id)
  let grant : @transfer.PortablePackageGrant = @json.from_json(
    self.control(
      route_root + "/share-grants/revoke",
      Some({ "grant_id": grant_id }),
    ),
  ) catch {
    _ => raise ClientError("invalid_grant_response")
  }
  if grant.grant_id != grant_id ||
    grant.permission != "download_package" ||
    grant.revoked_at_ms is None {
    raise ClientError("grant_response_mismatch")
  }
  grant
}

///|
pub async fn PortableClient::withdraw(
  self : PortableClient,
  package_id : String,
  binding : @marketplace.PortableListingBinding,
) -> @transfer.PackageView {
  validate_binding(binding, self.limits)
  if package_id != @transfer.package_id(binding.binding_digest) {
    raise ClientError("package_identity_mismatch")
  }
  let view : @transfer.PackageView = @json.from_json(
    self.control(
      route_root + "/withdraw",
      Some({
        "package_id": package_id,
        "binding_digest": binding.binding_digest,
      }),
    ),
  ) catch {
    _ => raise ClientError("invalid_package_metadata")
  }
  validate_view(view, self.limits, available=false)
  if view.package_id != package_id ||
    view.binding != binding ||
    view.status != "withdrawn" {
    raise ClientError("package_identity_mismatch")
  }
  view
}

///|
/// Reads only the explicitly named binding file, with a hard small metadata cap.
pub async fn read_binding_file(
  path : String,
) -> @marketplace.PortableListingBinding {
  if @fs.kind(path, follow_symlink=false) != Regular {
    raise ClientError("binding_not_regular")
  }
  let file = @fs.open(path, mode=ReadOnly)
  defer file.close()
  if file.kind() != Regular {
    raise ClientError("binding_not_regular")
  }
  let bytes = read_bounded(file, 128 * 1024, 30000)
  let binding : @marketplace.PortableListingBinding = @json.from_json(
    @json.parse(@utf8.decode(bytes)),
  ) catch {
    _ => raise ClientError("invalid_binding")
  }
  validate_binding(binding, @transfer.default_limits())
  binding
}

///|
/// For an explicit --session-stdin seam. No environment lookup, persistence or
/// token logging. The caller finishes the input with EOF.
pub async fn read_session(reader : &@io.Reader) -> String {
  let bytes = read_bounded(reader, 4096, 30000)
  let token = @utf8.decode(bytes).trim().to_owned() catch {
      _ => raise ClientError("invalid_session")
    }
  if token.is_empty() || token.iter().any(c => c <= ' ' || c >= '\u007f') {
    raise ClientError("invalid_session")
  }
  token
}
