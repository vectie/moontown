///|
pub fn SupervisorAuthorityCeiling::id(
  self : SupervisorAuthorityCeiling,
) -> String {
  match self {
    SuggestOnly => "suggest_only"
    DelegateBoundedWork => "delegate_bounded_work"
    RequestBookkeeperReview => "request_bookkeeper_review"
  }
}

///|
pub fn SupervisorLifecycle::id(self : SupervisorLifecycle) -> String {
  match self {
    SupervisorDraft => "draft"
    SupervisorReady => "ready"
    SupervisorPendingRuntime => "pending_runtime"
    SupervisorActive => "active"
  }
}

///|
pub fn SupervisorProfile::ready(self : SupervisorProfile) -> Bool {
  !self.identity.display_name.is_blank() &&
  !self.role.is_blank() &&
  !self.mission.is_blank() &&
  !self.tone.is_blank() &&
  !self.capabilities.is_empty() &&
  !self.bindings.workspace_id.is_blank() &&
  !self.bindings.building_id.is_blank() &&
  !self.bindings.book_ids.is_empty() &&
  self.bindings.max_active_workers > 0 &&
  !self.consent.terms_version.is_blank() &&
  self.consent.profile_activation &&
  (self.authority_ceiling == SuggestOnly || self.consent.runtime_delegation) &&
  (
    self.authority_ceiling != RequestBookkeeperReview ||
    self.consent.bookkeeper_review
  )
}

///|
pub fn empty_supervisor_setup_store() -> SupervisorSetupStore {
  {
    schema: supervisor_store_schema(),
    cursor: 0,
    profiles: [],
    activation_handoffs: [],
    execution_handoffs: [],
    runtime_observations: [],
    review_requests: [],
    audit_events: [],
    idempotency: [],
  }
}

///|
pub fn supervisor_setup_application(
  state_root : String,
) -> SupervisorSetupApplication {
  { state_root, }
}

///|
pub fn default_supervisor_setup_application() -> SupervisorSetupApplication {
  supervisor_setup_application(@storage.moontown_product_state_dir())
}

///|
fn latest_profile_for_owner(
  store : SupervisorSetupStore,
  owner_user_id : String,
) -> SupervisorProfile? {
  let mut latest : SupervisorProfile? = None
  for profile in store.profiles {
    if profile.owner_user_id == owner_user_id &&
      latest.map(item => item.revision < profile.revision).unwrap_or(true) {
      latest = Some(profile)
    }
  }
  latest
}
