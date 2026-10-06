///|
pub(all) struct TransferService {
  accounts : @account_system.AccountApplication
  marketplace : @town_marketplace.MarketplaceApplication
  store : @town_portable_transfer.PortableStore
  limits : @town_portable_transfer.TransferLimits
  now : () -> UInt64
}

///|
async fn TransferService::resolve(
  self : TransferService,
  request : @http.Request,
) -> @account_system.AccountContext {
  guard self.accounts.resolve_portable_transfer(
      header(request, "x-miniapp-session"),
      now_ms=(self.now)(),
    )
    is Some(context) else {
    reject(401, "missing_expired_or_invalid_account_session")
    fail("unreachable")
  }
  ignore(@town_portable_transfer.actor_for_account(context))
  context
}

///|
async fn TransferService::require_source(
  self : TransferService,
  binding : @town_marketplace.PortableListingBinding,
) -> Unit {
  guard self.marketplace.portable_transfer_binding(binding.listing_id)
    is Some(current) &&
    current == binding else {
    reject(403, "package_access_denied")
  }
}

///|
async fn TransferService::recheck(
  self : TransferService,
  request : @http.Request,
  initial : @town_portable_transfer.TransferActor,
  binding : @town_marketplace.PortableListingBinding,
) -> Unit {
  let fresh = @town_portable_transfer.actor_for_account(self.resolve(request))
  if fresh != initial {
    reject(403, "account_authority_changed")
  }
  self.require_source(binding)
}

///|
/// Handles only exact known feature paths. Authoritative session resolution is
/// inside this production core, including after long upload/download preflight.
pub async fn TransferService::handle(
  self : TransferService,
  request : @http.Request,
  body : &@io.Reader,
  sink : ResponseSink,
) -> Bool {
  if !is_transfer_path(request.path) {
    return false
  }
  sink.idle_timeout_ms = self.limits.idle_timeout_ms
  // A single deadline includes admission, preflight, reauthorization, stream
  // and response completion, rather than resetting the budget per phase.
  @async.with_timeout(
    self.limits.total_timeout_ms,
    () => self.dispatch(request, body, sink),
    error=@town_portable_transfer.TransferError(408, "package_transfer_timeout"),
  ) catch {
    error => {
      // Never append JSON to an already-started package response. Closing the
      // connection makes an interrupted stream fail the recipient's hash/count.
      if !sink.started {
        let (code, reason) = match error {
          @town_portable_transfer.TransferError(code, reason) => (code, reason)
          @async.TimeoutError => (408, "transfer_timeout")
          _ => (503, "package_storage_unavailable")
        }
        sink.json(code, { "ok": false, "error": reason }) catch {
          _ => ()
        }
      }
      // Includes unauthorized/oversized writes whose request body was unread.
      (sink.close_connection)()
    }
  }
  true
}

///|
async fn TransferService::dispatch(
  self : TransferService,
  request : @http.Request,
  body : &@io.Reader,
  sink : ResponseSink,
) -> Unit {
  let context = self.resolve(request)
  let actor = @town_portable_transfer.actor_for_account(context)
  let path = path_only(request.path)
  if path == @town_contract.portable_package_content_path() {
    if request.meth is @http.Put {
      if !actor.publisher {
        reject(403, "package_access_denied")
      }
      identity_framing(request)
      if header(request, "content-type").to_lower() !=
        "application/octet-stream" {
        reject(415, "application_octet_stream_required")
      }
      let length = bounded_length(request, self.limits.max_package_bytes)
      let listing_id = query_id(request.path, "listing_id")
      guard self.marketplace.portable_transfer_binding(listing_id)
        is Some(binding) else {
        reject(403, "package_access_denied")
        return
      }
      if binding.publisher_principal_id != actor.principal_id ||
        binding.tenant_id != actor.tenant_id {
        reject(403, "package_access_denied")
      }
      if header(request, "x-town-binding-digest") != binding.binding_digest {
        reject(409, "binding_mismatch")
      }
      if length != binding.source.package_size_bytes {
        reject(422, "body_length_mismatch")
      }
      let view = self.store.upload(
        actor,
        binding,
        body,
        () => self.recheck(request, actor, binding),
        self.now,
      )
      sink.json(200, { "ok": true, "payload": view.to_json() })
      return
    }
    if request.meth is @http.Get {
      if request.headers.contains("range") {
        reject(400, "range_not_supported")
      }
      let id = query_id(request.path, "package_id")
      let digest = header(request, "x-town-binding-digest")
      let view = self.store.get(actor, id, digest, (self.now)())
      self.require_source(view.binding)
      let download = self.store.download(actor, id, digest, (self.now)())
      defer download.close()
      self.recheck(request, actor, view.binding)
      // Revocation/withdrawal during preflight must still deny response start.
      if self.store.get(actor, id, digest, (self.now)()).status != "available" {
        reject(403, "package_access_denied")
      }
      sink.start(200, {
        "content-type": "application/octet-stream",
        "content-length": view.binding.source.package_size_bytes.to_string(),
        "cache-control": "private, no-store, no-transform",
        "x-content-type-options": "nosniff",
        "content-disposition": "attachment; filename=\"\{id}.moonbook-agent\"",
        "x-town-package-id": id,
        "x-town-binding-digest": digest,
        "x-town-package-sha256": view.binding.source.package_sha256,
      })
      download.stream(sink)
      @async.with_timeout(self.limits.idle_timeout_ms, () => {
        (sink.end_response)()
      })
      return
    }
    reject(405, "method_not_allowed")
  }
  if path == @town_contract.portable_packages_path() {
    if !(request.meth is @http.Get) {
      reject(405, "method_not_allowed")
    }
    let visible : Array[@town_portable_transfer.PackageView] = []
    for view in self.store.list(actor, (self.now)()) {
      if self.marketplace.portable_transfer_binding(view.binding.listing_id)
        is Some(binding) &&
        binding == view.binding {
        visible.push(view)
      }
    }
    sink.json(200, { "ok": true, "payload": { "packages": visible.to_json() } })
    return
  }
  if !(request.meth is @http.Post) {
    reject(405, "method_not_allowed")
  }
  if !actor.publisher {
    reject(403, "package_access_denied")
  }
  let value = control_body(request, body)
  // Resolve again after even bounded control body IO.
  let fresh_context = self.resolve(request)
  if @town_portable_transfer.actor_for_account(fresh_context) != actor {
    reject(403, "account_authority_changed")
  }
  if path == @town_contract.portable_package_preview_path() ||
    path == @town_contract.portable_package_grants_path() {
    let draft = grant_draft(value)
    let view = self.store.get(
      actor,
      draft.package_id,
      draft.binding_digest,
      (self.now)(),
    )
    if view.binding.publisher_principal_id != actor.principal_id ||
      view.status != "available" {
      reject(403, "package_access_denied")
    }
    self.require_source(view.binding)
    if !self.accounts.portable_transfer_recipient_active(
        fresh_context,
        draft.grantee_principal_id,
      ) {
      reject(403, "known_active_same_tenant_recipient_required")
    }
    if path == @town_contract.portable_package_preview_path() {
      if draft.expires_at_ms <= (self.now)() {
        reject(400, "future_expiry_required")
      }
      sink.json(200, {
        "ok": true,
        "payload": {
          "package": view.to_json(),
          "recipient_principal_id": draft.grantee_principal_id,
          "tenant_id": actor.tenant_id,
          "expires_at_ms": draft.expires_at_ms.to_json(),
          "package_size_bytes": view.binding.source.package_size_bytes,
          "package_sha256": view.binding.source.package_sha256,
          "included_output_count": view.binding.source.included_output_count,
          "reference_only_count": view.binding.source.reference_only_count,
          "disclosure": "This grants the entire exact package, including accepted learning, identity files and included output bytes. Metadata/card grants remain separate. Download does not install or execute it.",
          "granted": false,
        },
      })
    } else {
      let grant = self.store.grant(actor, draft, (self.now)())
      sink.json(200, { "ok": true, "payload": grant.to_json() })
    }
    return
  }
  if path == @town_contract.portable_package_revoke_path() {
    let fields = exact_object(value, ["grant_id"])
    let grant = self.store.revoke(
      actor,
      control_string(fields, "grant_id"),
      (self.now)(),
    )
    sink.json(200, { "ok": true, "payload": grant.to_json() })
    return
  }
  if path == @town_contract.portable_package_withdraw_path() {
    let fields = exact_object(value, ["package_id", "binding_digest"])
    // Withdrawal/revoke remain possible for archived listings, since they only
    // remove byte authority and do not change the immutable source declaration.
    let view = self.store.withdraw(
      actor,
      control_string(fields, "package_id"),
      control_string(fields, "binding_digest"),
      (self.now)(),
    )
    sink.json(200, { "ok": true, "payload": view.to_json() })
    return
  }
  reject(405, "method_not_allowed")
}
