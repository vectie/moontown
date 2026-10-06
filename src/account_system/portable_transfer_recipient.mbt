///|
/// Read-only recipient prerequisite for explicit same-tenant package sharing.
/// This does not create a principal, session, membership, or grant. The caller
/// context must come from the existing request-scoped account resolver.
pub async fn AccountApplication::portable_transfer_recipient_active(
  self : AccountApplication,
  context : AccountContext,
  recipient_id : String,
) -> Bool {
  if !context.has_entitlement(PublishTownContent) ||
    !context.has_entitlement(UseMarketplaceActions) {
    return false
  }
  account_store_mutex.acquire()
  defer account_store_mutex.release()
  let state = self.load_portable_transfer_state()
  guard account_principal_record_by_id(state, recipient_id) is Some(recipient) &&
    recipient.active else {
    return false
  }
  match context.active_tenant_id {
    Some(tenant_id) =>
      recipient.tenant_access.any(access => {
        access.tenant_id == tenant_id && access.active
      })
    None => recipient.user_id == context.user_id
  }
}

///|
async fn AccountApplication::load_portable_transfer_state(
  self : AccountApplication,
) -> AccountState {
  let state = if @fs.exists(self.state_path) {
    let decoded : AccountState = @json.from_json(
      migrate_account_state_json(
        @json.parse(@fs.read_file(self.state_path).text()),
      ),
    )
    normalize_account_state(decoded)
  } else {
    empty_account_state()
  }
  validate_account_state(state)
  let state = self.ensure_bootstrap(state)
  validate_account_state(state)
  state
}

///|
/// Same authoritative session and AccountContext policy as resolve. Only the
/// feature-local loader differs: existing malformed account state is never
/// mistaken for an absent store and cannot resurrect bootstrap authority.
pub async fn AccountApplication::resolve_portable_transfer(
  self : AccountApplication,
  opaque_token : String,
  now_ms~ : UInt64,
) -> AccountContext? {
  account_store_mutex.acquire()
  defer account_store_mutex.release()
  let state = self.load_portable_transfer_state()
  let pruned = self.prune_state(state, now_ms)
  if pruned != state {
    self.save_state(pruned)
  }
  account_context_for_session(pruned, opaque_token, now_ms~)
}
