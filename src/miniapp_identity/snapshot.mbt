///|
pub fn miniapp_snapshot_for_session(
  state : MiniappIdentityState,
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  session_id : String,
  now_ms~ : UInt64,
) -> @miniapp_contracts.MiniappTownSnapshot? {
  match miniapp_session_context(state, session_id, now_ms~) {
    Some(context) =>
      Some(
        @miniapp_projection.miniapp_filter_snapshot_for_viewer(
          snapshot,
          context.viewer,
        ),
      )
    None => None
  }
}

///|
pub fn miniapp_search_for_session(
  state : MiniappIdentityState,
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  session_id : String,
  now_ms~ : UInt64,
  query : String,
) -> Array[@miniapp_contracts.MiniappSearchResult] {
  match miniapp_session_context(state, session_id, now_ms~) {
    Some(context) =>
      @miniapp_projection.miniapp_search_buildings(
        snapshot,
        context.viewer,
        query,
      )
    None => []
  }
}
