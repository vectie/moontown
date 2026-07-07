///|
pub fn miniapp_create_agent(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  draft : MiniappAgentDraft,
  now_ms~ : UInt64,
) -> MiniappAgentRuntimeChange {
  if miniapp_agent_exists(snapshot, draft.id) {
    miniapp_agent_reject(snapshot, "agent already exists", agent_id=draft.id)
  } else if !miniapp_actor_can_own(viewer, draft.owner_kind, draft.owner_id) {
    miniapp_agent_reject(snapshot, "viewer cannot own agent", agent_id=draft.id)
  } else {
    match draft.building_id {
      Some(building_id) =>
        miniapp_create_agent_for_building(
          snapshot,
          viewer,
          draft,
          building_id,
          now_ms~,
        )
      None => miniapp_create_agent_unattached(snapshot, viewer, draft, now_ms~)
    }
  }
}

///|
fn miniapp_create_agent_unattached(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  draft : MiniappAgentDraft,
  now_ms~ : UInt64,
) -> MiniappAgentRuntimeChange {
  let agent = miniapp_agent_from_draft(draft)
  miniapp_agent_accept(
    {
      ..snapshot,
      agents: snapshot.agents + [agent],
      audit_events: snapshot.audit_events +
      [
        miniapp_audit_event(
          "audit-\{agent.id}-created",
          viewer,
          "agent",
          agent.id,
          "agent.created",
          "Agent created without a building attachment.",
          now_ms,
        ),
      ],
      version: snapshot.version + 1,
    },
    "agent created",
    agent_id=agent.id,
  )
}

///|
fn miniapp_create_agent_for_building(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  draft : MiniappAgentDraft,
  building_id : String,
  now_ms~ : UInt64,
) -> MiniappAgentRuntimeChange {
  match miniapp_building_by_id(snapshot, building_id) {
    None =>
      miniapp_agent_reject(snapshot, "building not found", agent_id=draft.id)
    Some(building) =>
      if !@miniapp_projection.miniapp_can_edit_building(viewer, building) {
        miniapp_agent_reject(
          snapshot,
          "viewer cannot attach agent to building",
          agent_id=draft.id,
        )
      } else {
        let agent = miniapp_agent_from_draft(draft)
        miniapp_agent_accept(
          {
            ..snapshot,
            agents: snapshot.agents + [agent],
            audit_events: snapshot.audit_events +
            [
              miniapp_audit_event(
                "audit-\{agent.id}-created",
                viewer,
                "agent",
                agent.id,
                "agent.created",
                "Agent created and attached to \{building.id}.",
                now_ms,
              ),
            ],
            version: snapshot.version + 1,
          },
          "agent created",
          agent_id=agent.id,
        )
      }
  }
}

///|
fn miniapp_agent_from_draft(
  draft : MiniappAgentDraft,
) -> @miniapp_contracts.MiniappAgent {
  {
    id: draft.id,
    display_name: draft.display_name,
    owner_kind: draft.owner_kind,
    owner_id: draft.owner_id,
    building_id: draft.building_id,
    capabilities: draft.capabilities,
    version: 1,
  }
}

///|
pub fn miniapp_attach_agent_to_building(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  draft : MiniappAgentAttachDraft,
  now_ms~ : UInt64,
) -> MiniappAgentRuntimeChange {
  match miniapp_agent_by_id(snapshot, draft.agent_id) {
    None =>
      miniapp_agent_reject(snapshot, "agent not found", agent_id=draft.agent_id)
    Some(agent) =>
      if !miniapp_agent_owned_by_viewer(viewer, agent) {
        miniapp_agent_reject(
          snapshot,
          "viewer cannot update agent",
          agent_id=agent.id,
        )
      } else {
        match miniapp_building_by_id(snapshot, draft.building_id) {
          None =>
            miniapp_agent_reject(
              snapshot,
              "building not found",
              agent_id=agent.id,
            )
          Some(building) =>
            if !@miniapp_projection.miniapp_can_edit_building(viewer, building) {
              miniapp_agent_reject(
                snapshot,
                "viewer cannot attach agent to building",
                agent_id=agent.id,
              )
            } else {
              let next = {
                ..agent,
                building_id: Some(building.id),
                version: agent.version + 1,
              }
              miniapp_agent_accept(
                {
                  ..snapshot,
                  agents: miniapp_replace_agent(snapshot.agents, next),
                  audit_events: snapshot.audit_events +
                  [
                    miniapp_audit_event(
                      "audit-\{agent.id}-attached-\{building.id}",
                      viewer,
                      "agent",
                      agent.id,
                      "agent.attached",
                      "Agent attached to \{building.id}.",
                      now_ms,
                    ),
                  ],
                  version: snapshot.version + 1,
                },
                "agent attached",
                agent_id=agent.id,
              )
            }
        }
      }
  }
}

///|
pub fn miniapp_send_agent_message(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  draft : MiniappChatSendDraft,
  now_ms~ : UInt64,
) -> MiniappAgentRuntimeChange {
  if miniapp_message_exists(snapshot, draft.message_id) {
    miniapp_agent_reject(
      snapshot,
      "message already exists",
      thread_id=draft.thread_id,
      run_id=draft.run_id,
    )
  } else if miniapp_run_by_id(snapshot, draft.run_id) is Some(_) {
    miniapp_agent_reject(
      snapshot,
      "run already exists",
      thread_id=draft.thread_id,
      run_id=draft.run_id,
    )
  } else {
    match miniapp_building_by_id(snapshot, draft.building_id) {
      None =>
        miniapp_agent_reject(
          snapshot,
          "building not found",
          thread_id=draft.thread_id,
          run_id=draft.run_id,
        )
      Some(building) =>
        if !@miniapp_projection.miniapp_can_view_building(viewer, building) {
          miniapp_agent_reject(
            snapshot,
            "viewer cannot chat with building",
            thread_id=draft.thread_id,
            run_id=draft.run_id,
          )
        } else if !miniapp_agent_can_answer(
            snapshot,
            draft.agent_id,
            building.id,
          ) {
          miniapp_agent_reject(
            snapshot,
            "agent cannot answer for building",
            thread_id=draft.thread_id,
            run_id=draft.run_id,
          )
        } else {
          let thread = miniapp_thread_for_chat(
            snapshot,
            building,
            draft.thread_id,
          )
          let user_message : @miniapp_contracts.MiniappMessage = {
            id: draft.message_id,
            thread_id: thread.id,
            actor_id: viewer.user_id,
            actor_label: "user",
            body: draft.body,
            created_at_ms: now_ms,
            version: 1,
          }
          let run : @miniapp_contracts.MiniappRun = {
            id: draft.run_id,
            user_id: viewer.user_id,
            building_id: building.id,
            book_id: building.primary_book_id,
            agent_id: draft.agent_id,
            thread_id: thread.id,
            status: @miniapp_contracts.RunWaitingReview,
            summary: draft.answer_summary,
            created_at_ms: now_ms,
            updated_at_ms: now_ms,
            version: 1,
          }
          miniapp_agent_accept(
            {
              ..snapshot,
              threads: miniapp_replace_thread(snapshot.threads, thread),
              messages: snapshot.messages + [user_message],
              runs: snapshot.runs + [run],
              audit_events: snapshot.audit_events +
              [
                miniapp_audit_event(
                  "audit-\{run.id}-sent",
                  viewer,
                  "run",
                  run.id,
                  "chat.sent",
                  "Chat message recorded for reviewable agent run.",
                  now_ms,
                ),
              ],
              version: snapshot.version + 1,
            },
            "chat sent",
            thread_id=thread.id,
            run_id=run.id,
          )
        }
    }
  }
}

///|
fn miniapp_agent_can_answer(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  agent_id : String?,
  building_id : String,
) -> Bool {
  match agent_id {
    None => true
    Some(id) =>
      match miniapp_agent_by_id(snapshot, id) {
        None => false
        Some(agent) =>
          match agent.building_id {
            None => true
            Some(attached) => attached == building_id
          }
      }
  }
}

///|
fn miniapp_thread_for_chat(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building : @miniapp_contracts.MiniappBuilding,
  thread_id : String,
) -> @miniapp_contracts.MiniappThread {
  match miniapp_thread_by_id(snapshot, thread_id) {
    Some(thread) =>
      {
        ..thread,
        message_count: thread.message_count + 1,
        unread_count: thread.unread_count + 1,
        version: thread.version + 1,
      }
    None =>
      {
        id: thread_id,
        building_id: building.id,
        title: "\{building.title} chat",
        message_count: 1,
        unread_count: 1,
        version: 1,
      }
  }
}

///|
pub fn miniapp_cancel_run(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  draft : MiniappRunActionDraft,
  now_ms~ : UInt64,
) -> MiniappAgentRuntimeChange {
  miniapp_update_run_status(
    snapshot,
    viewer,
    draft,
    @miniapp_contracts.RunCancelled,
    "run.cancelled",
    "run cancelled",
    now_ms~,
  )
}

///|
pub fn miniapp_retry_run(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  draft : MiniappRunActionDraft,
  now_ms~ : UInt64,
) -> MiniappAgentRuntimeChange {
  miniapp_update_run_status(
    snapshot,
    viewer,
    draft,
    @miniapp_contracts.RunPending,
    "run.retry",
    "run queued for retry",
    now_ms~,
  )
}

///|
pub fn miniapp_accept_run_for_review(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  draft : MiniappRunActionDraft,
  now_ms~ : UInt64,
) -> MiniappAgentRuntimeChange {
  miniapp_update_run_status(
    snapshot,
    viewer,
    draft,
    @miniapp_contracts.RunDone,
    "review.accepted",
    "run accepted into book memory",
    now_ms~,
  )
}

///|
fn miniapp_update_run_status(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  draft : MiniappRunActionDraft,
  status : @miniapp_contracts.MiniappRunStatus,
  action : String,
  message : String,
  now_ms~ : UInt64,
) -> MiniappAgentRuntimeChange {
  match miniapp_run_by_id(snapshot, draft.run_id) {
    None => miniapp_agent_reject(snapshot, "run not found", run_id=draft.run_id)
    Some(run) =>
      if run.user_id != viewer.user_id &&
        !@miniapp_projection.miniapp_viewer_is_admin(viewer) {
        miniapp_agent_reject(
          snapshot,
          "viewer cannot update run",
          run_id=run.id,
        )
      } else {
        let next = {
          ..run,
          status,
          summary: draft.summary,
          updated_at_ms: now_ms,
          version: run.version + 1,
        }
        miniapp_agent_accept(
          {
            ..snapshot,
            runs: miniapp_replace_run(snapshot.runs, next),
            audit_events: snapshot.audit_events +
            [
              miniapp_audit_event(
                "audit-\{run.id}-\{action}",
                viewer,
                "run",
                run.id,
                action,
                draft.summary,
                now_ms,
              ),
            ],
            version: snapshot.version + 1,
          },
          message,
          thread_id=run.thread_id,
          run_id=run.id,
        )
      }
  }
}
