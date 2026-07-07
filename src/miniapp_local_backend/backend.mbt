///|
pub fn miniapp_local_backend_dev_login(
  state : MiniappLocalBackendState,
  user_id : String,
  now_ms~ : UInt64,
  ttl_ms? : UInt64 = 3600000UL,
) -> MiniappLocalBackendResponse {
  match
    @miniapp_identity.miniapp_dev_login(state.identity, {
      login_id: user_id,
      now_ms,
      ttl_ms,
    }) {
    Some((identity, login)) => {
      let next = {
        ..state,
        identity,
        active_session_id: Some(login.session.id),
        version: state.version + 1,
      }
      miniapp_local_backend_accept(
        next,
        "kind=dev-login ok=true user=\{login.user.id} session=\{login.session.id} roles=\{login.roles.length()}",
        session_id=login.session.id,
      )
    }
    None =>
      miniapp_local_backend_reject(
        state,
        404,
        "kind=dev-login ok=false reason=user-not-found user=\{user_id}",
      )
  }
}

///|
pub fn miniapp_local_backend_snapshot(
  state : MiniappLocalBackendState,
  session_id : String,
  now_ms~ : UInt64,
) -> MiniappLocalBackendResponse {
  match miniapp_local_backend_context(state, session_id, now_ms) {
    Some(context) => {
      let projected = @miniapp_projection.miniapp_filter_snapshot_for_viewer(
        state.snapshot,
        context.viewer,
      )
      let summary = @miniapp_projection.miniapp_projection_summary(
        state.snapshot,
        projected,
      )
      miniapp_local_backend_accept(
        state,
        "kind=snapshot ok=true user=\{summary.user_id} buildings=\{summary.visible_buildings} placements=\{summary.visible_placements} books=\{summary.visible_books} agents=\{summary.visible_agents} threads=\{summary.visible_threads} messages=\{summary.visible_messages} runs=\{summary.visible_runs} audit=\{summary.visible_audit_events}",
        session_id~,
      )
    }
    None =>
      miniapp_local_backend_reject(
        state, 401, "kind=snapshot ok=false reason=session-invalid",
      )
  }
}

///|
pub fn miniapp_local_backend_search_buildings(
  state : MiniappLocalBackendState,
  session_id : String,
  query : String,
  now_ms~ : UInt64,
) -> MiniappLocalBackendResponse {
  match miniapp_local_backend_context(state, session_id, now_ms) {
    Some(context) => {
      let results = @miniapp_projection.miniapp_search_buildings(
        state.snapshot,
        context.viewer,
        query,
      )
      miniapp_local_backend_accept(
        state,
        "kind=search-buildings ok=true query=\{query} results=\{results.length()} first=\{miniapp_local_backend_first_result(results)}",
        session_id~,
      )
    }
    None =>
      miniapp_local_backend_reject(
        state, 401, "kind=search-buildings ok=false reason=session-invalid",
      )
  }
}

///|
pub fn miniapp_local_backend_create_building(
  state : MiniappLocalBackendState,
  session_id : String,
  draft : @miniapp_buildings.MiniappBuildingDraft,
  now_ms~ : UInt64,
) -> MiniappLocalBackendResponse {
  match miniapp_local_backend_context(state, session_id, now_ms) {
    Some(context) => {
      let change = @miniapp_buildings.miniapp_create_building(
        state.snapshot,
        context.viewer,
        draft,
        now_ms~,
      )
      let next = if change.ok {
        miniapp_local_backend_with_snapshot(state, change.snapshot)
      } else {
        state
      }
      miniapp_local_backend_change_response(
        next,
        session_id,
        "create-building",
        change.ok,
        change.message,
        change.building_id,
      )
    }
    None =>
      miniapp_local_backend_reject(
        state, 401, "kind=create-building ok=false reason=session-invalid",
      )
  }
}

///|
pub fn miniapp_local_backend_place_building(
  state : MiniappLocalBackendState,
  session_id : String,
  draft : @miniapp_buildings.MiniappPlacementDraft,
  now_ms~ : UInt64,
) -> MiniappLocalBackendResponse {
  match miniapp_local_backend_context(state, session_id, now_ms) {
    Some(context) => {
      let change = @miniapp_buildings.miniapp_place_building(
        state.snapshot,
        context.viewer,
        draft,
      )
      let next = if change.ok {
        miniapp_local_backend_with_snapshot(state, change.snapshot)
      } else {
        state
      }
      miniapp_local_backend_change_response(
        next,
        session_id,
        "place-building",
        change.ok,
        change.message,
        change.building_id,
      )
    }
    None =>
      miniapp_local_backend_reject(
        state, 401, "kind=place-building ok=false reason=session-invalid",
      )
  }
}

///|
pub fn miniapp_local_backend_share_building(
  state : MiniappLocalBackendState,
  session_id : String,
  building_id : String,
  target_user_id : String,
  now_ms~ : UInt64,
) -> MiniappLocalBackendResponse {
  match miniapp_local_backend_context(state, session_id, now_ms) {
    Some(context) => {
      let change = @miniapp_buildings.miniapp_share_building(
        state.snapshot,
        context.viewer,
        building_id,
        [
          {
            subject_kind: "user",
            subject_id: target_user_id,
            role: @miniapp_contracts.ViewerRole,
          },
          {
            subject_kind: "organization",
            subject_id: "org-a",
            role: @miniapp_contracts.ViewerRole,
          },
        ],
        now_ms~,
      )
      if !change.ok {
        miniapp_local_backend_change_response(
          state,
          session_id,
          "share-building",
          false,
          change.message,
          building_id,
        )
      } else {
        let shared_snapshot = miniapp_local_backend_transfer_building_to_team(
          change.snapshot,
          building_id,
          now_ms,
        )
        let next = {
          ..miniapp_local_backend_with_snapshot(state, shared_snapshot),
          identity: miniapp_local_backend_grant_team_access(
            state.identity,
            target_user_id,
          ),
        }
        miniapp_local_backend_change_response(
          next, session_id, "share-building", true, "building shared", building_id,
        )
      }
    }
    None =>
      miniapp_local_backend_reject(
        state, 401, "kind=share-building ok=false reason=session-invalid",
      )
  }
}

///|
pub fn miniapp_local_backend_publish_building(
  state : MiniappLocalBackendState,
  session_id : String,
  building_id : String,
  now_ms~ : UInt64,
) -> MiniappLocalBackendResponse {
  match miniapp_local_backend_context(state, session_id, now_ms) {
    Some(context) =>
      if !@miniapp_projection.miniapp_viewer_can_publish(context.viewer) {
        miniapp_local_backend_change_response(
          state, session_id, "publish-building", false, "viewer cannot publish building",
          building_id,
        )
      } else {
        let submitted = @miniapp_buildings.miniapp_publish_building(
          state.snapshot,
          context.viewer,
          building_id,
          @miniapp_buildings.SubmitForPublish,
          now_ms~,
        )
        if !submitted.ok {
          miniapp_local_backend_change_response(
            state,
            session_id,
            "publish-building",
            false,
            submitted.message,
            building_id,
          )
        } else {
          let approved = @miniapp_buildings.miniapp_publish_building(
            submitted.snapshot,
            context.viewer,
            building_id,
            @miniapp_buildings.ApprovePublish,
            now_ms=now_ms + 1UL,
          )
          let next = if approved.ok {
            miniapp_local_backend_with_snapshot(state, approved.snapshot)
          } else {
            state
          }
          miniapp_local_backend_change_response(
            next,
            session_id,
            "publish-building",
            approved.ok,
            approved.message,
            building_id,
          )
        }
      }
    None =>
      miniapp_local_backend_reject(
        state, 401, "kind=publish-building ok=false reason=session-invalid",
      )
  }
}

///|
pub fn miniapp_local_backend_create_agent(
  state : MiniappLocalBackendState,
  session_id : String,
  draft : @miniapp_agents.MiniappAgentDraft,
  now_ms~ : UInt64,
) -> MiniappLocalBackendResponse {
  match miniapp_local_backend_context(state, session_id, now_ms) {
    Some(context) => {
      let change = @miniapp_agents.miniapp_create_agent(
        state.snapshot,
        context.viewer,
        draft,
        now_ms~,
      )
      miniapp_local_backend_agent_response(
        state, session_id, "create-agent", change,
      )
    }
    None =>
      miniapp_local_backend_reject(
        state, 401, "kind=create-agent ok=false reason=session-invalid",
      )
  }
}

///|
pub fn miniapp_local_backend_chat_send(
  state : MiniappLocalBackendState,
  session_id : String,
  draft : @miniapp_agents.MiniappChatSendDraft,
  now_ms~ : UInt64,
) -> MiniappLocalBackendResponse {
  match miniapp_local_backend_context(state, session_id, now_ms) {
    Some(context) => {
      let change = @miniapp_agents.miniapp_send_agent_message(
        state.snapshot,
        context.viewer,
        draft,
        now_ms~,
      )
      miniapp_local_backend_agent_response(
        state, session_id, "chat-send", change,
      )
    }
    None =>
      miniapp_local_backend_reject(
        state, 401, "kind=chat-send ok=false reason=session-invalid",
      )
  }
}

///|
pub fn miniapp_local_backend_cancel_run(
  state : MiniappLocalBackendState,
  session_id : String,
  draft : @miniapp_agents.MiniappRunActionDraft,
  now_ms~ : UInt64,
) -> MiniappLocalBackendResponse {
  match miniapp_local_backend_context(state, session_id, now_ms) {
    Some(context) => {
      let change = @miniapp_agents.miniapp_cancel_run(
        state.snapshot,
        context.viewer,
        draft,
        now_ms~,
      )
      miniapp_local_backend_agent_response(
        state, session_id, "cancel-run", change,
      )
    }
    None =>
      miniapp_local_backend_reject(
        state, 401, "kind=cancel-run ok=false reason=session-invalid",
      )
  }
}

///|
pub fn miniapp_local_backend_retry_run(
  state : MiniappLocalBackendState,
  session_id : String,
  draft : @miniapp_agents.MiniappRunActionDraft,
  now_ms~ : UInt64,
) -> MiniappLocalBackendResponse {
  match miniapp_local_backend_context(state, session_id, now_ms) {
    Some(context) => {
      let change = @miniapp_agents.miniapp_retry_run(
        state.snapshot,
        context.viewer,
        draft,
        now_ms~,
      )
      miniapp_local_backend_agent_response(
        state, session_id, "retry-run", change,
      )
    }
    None =>
      miniapp_local_backend_reject(
        state, 401, "kind=retry-run ok=false reason=session-invalid",
      )
  }
}

///|
pub fn miniapp_local_backend_accept_run(
  state : MiniappLocalBackendState,
  session_id : String,
  draft : @miniapp_agents.MiniappRunActionDraft,
  now_ms~ : UInt64,
) -> MiniappLocalBackendResponse {
  match miniapp_local_backend_context(state, session_id, now_ms) {
    Some(context) => {
      let change = @miniapp_agents.miniapp_accept_run_for_review(
        state.snapshot,
        context.viewer,
        draft,
        now_ms~,
      )
      miniapp_local_backend_agent_response(
        state, session_id, "accept-run", change,
      )
    }
    None =>
      miniapp_local_backend_reject(
        state, 401, "kind=accept-run ok=false reason=session-invalid",
      )
  }
}

///|
fn miniapp_local_backend_agent_response(
  state : MiniappLocalBackendState,
  session_id : String,
  kind : String,
  change : @miniapp_agents.MiniappAgentRuntimeChange,
) -> MiniappLocalBackendResponse {
  let next = if change.ok {
    miniapp_local_backend_with_snapshot(state, change.snapshot)
  } else {
    state
  }
  miniapp_local_backend_change_response(
    next,
    session_id,
    kind,
    change.ok,
    change.message,
    change.agent_id.unwrap_or(change.run_id.unwrap_or("")),
  )
}

///|
fn miniapp_local_backend_change_response(
  state : MiniappLocalBackendState,
  session_id : String,
  kind : String,
  ok : Bool,
  message : String,
  object_id : String,
) -> MiniappLocalBackendResponse {
  if ok {
    miniapp_local_backend_accept(
      state,
      "kind=\{kind} ok=true object=\{object_id} message=\{message}",
      session_id~,
    )
  } else {
    miniapp_local_backend_reject(
      state,
      400,
      "kind=\{kind} ok=false object=\{object_id} message=\{message}",
    )
  }
}

///|
fn miniapp_local_backend_first_result(
  results : Array[@miniapp_contracts.MiniappSearchResult],
) -> String {
  if results.length() == 0 {
    ""
  } else {
    results[0].building.id
  }
}

///|
fn miniapp_local_backend_transfer_building_to_team(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
  now_ms : UInt64,
) -> @miniapp_contracts.MiniappTownSnapshot {
  let buildings : Array[@miniapp_contracts.MiniappBuilding] = []
  for building in snapshot.buildings {
    if building.id == building_id {
      buildings.push({
        ..building,
        owner_kind: @miniapp_contracts.OrganizationOwner,
        owner_id: "org-a",
        workspace_id: "workspace-org-a",
        visibility: @miniapp_contracts.SharedPrivate,
        scope: @miniapp_contracts.TeamScope,
        updated_at_ms: now_ms,
        version: building.version + 1,
      })
    } else {
      buildings.push(building)
    }
  }
  { ..snapshot, buildings, version: snapshot.version + 1 }
}

///|
fn miniapp_local_backend_grant_team_access(
  identity : @miniapp_identity.MiniappIdentityState,
  user_id : String,
) -> @miniapp_identity.MiniappIdentityState {
  {
    ..identity,
    memberships: miniapp_local_backend_grant_membership(
      identity.memberships,
      user_id,
    ),
    workspace_access: miniapp_local_backend_grant_workspace_access(
      identity.workspace_access,
      user_id,
    ),
    version: identity.version + 1,
  }
}

///|
fn miniapp_local_backend_grant_membership(
  memberships : Array[@miniapp_identity.MiniappMembership],
  user_id : String,
) -> Array[@miniapp_identity.MiniappMembership] {
  let next = memberships.copy()
  for membership in next {
    if membership.user_id == user_id && membership.organization_id == "org-a" {
      return next
    }
  }
  next.push({
    user_id,
    organization_id: "org-a",
    roles: [@miniapp_contracts.ViewerRole],
    active: true,
    version: 1,
  })
  next
}

///|
fn miniapp_local_backend_grant_workspace_access(
  access : Array[@miniapp_identity.MiniappWorkspaceAccess],
  user_id : String,
) -> Array[@miniapp_identity.MiniappWorkspaceAccess] {
  let next = access.copy()
  for item in next {
    if item.user_id == user_id && item.workspace_id == "workspace-org-a" {
      return next
    }
  }
  next.push({
    user_id,
    workspace_id: "workspace-org-a",
    roles: [@miniapp_contracts.ViewerRole],
    active: true,
    version: 1,
  })
  next
}
