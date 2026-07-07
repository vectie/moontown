///|
pub fn miniapp_local_backend_fixture_state() -> MiniappLocalBackendState {
  {
    identity: @miniapp_identity.miniapp_identity_fixture_state(),
    snapshot: @miniapp_projection.miniapp_projection_fixture_mixed_snapshot(),
    active_session_id: None,
    version: 1,
  }
}

///|
fn miniapp_local_backend_accept(
  state : MiniappLocalBackendState,
  body : String,
  session_id? : String = "",
) -> MiniappLocalBackendResponse {
  {
    ok: true,
    status: 200,
    body,
    state,
    session_id: if session_id == "" {
      state.active_session_id
    } else {
      Some(session_id)
    },
  }
}

///|
fn miniapp_local_backend_reject(
  state : MiniappLocalBackendState,
  status : Int,
  body : String,
) -> MiniappLocalBackendResponse {
  { ok: false, status, body, state, session_id: state.active_session_id }
}

///|
fn miniapp_local_backend_context(
  state : MiniappLocalBackendState,
  session_id : String,
  now_ms : UInt64,
) -> @miniapp_identity.MiniappSessionContext? {
  @miniapp_identity.miniapp_session_context(state.identity, session_id, now_ms~)
}

///|
fn miniapp_local_backend_with_snapshot(
  state : MiniappLocalBackendState,
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
) -> MiniappLocalBackendState {
  { ..state, snapshot, version: state.version + 1 }
}
