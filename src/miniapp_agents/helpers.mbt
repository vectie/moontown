///|
fn miniapp_agent_accept(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  message : String,
  agent_id? : String = "",
  thread_id? : String = "",
  run_id? : String = "",
) -> MiniappAgentRuntimeChange {
  {
    ok: true,
    snapshot,
    message,
    agent_id: if agent_id == "" {
      None
    } else {
      Some(agent_id)
    },
    thread_id: if thread_id == "" {
      None
    } else {
      Some(thread_id)
    },
    run_id: if run_id == "" {
      None
    } else {
      Some(run_id)
    },
  }
}

///|
fn miniapp_agent_reject(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  message : String,
  agent_id? : String = "",
  thread_id? : String = "",
  run_id? : String = "",
) -> MiniappAgentRuntimeChange {
  {
    ok: false,
    snapshot,
    message,
    agent_id: if agent_id == "" {
      None
    } else {
      Some(agent_id)
    },
    thread_id: if thread_id == "" {
      None
    } else {
      Some(thread_id)
    },
    run_id: if run_id == "" {
      None
    } else {
      Some(run_id)
    },
  }
}

///|
fn miniapp_agent_by_id(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  agent_id : String,
) -> @miniapp_contracts.MiniappAgent? {
  for agent in snapshot.agents {
    if agent.id == agent_id {
      return Some(agent)
    }
  }
  None
}

///|
fn miniapp_building_by_id(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
) -> @miniapp_contracts.MiniappBuilding? {
  for building in snapshot.buildings {
    if building.id == building_id {
      return Some(building)
    }
  }
  None
}

///|
fn miniapp_thread_by_id(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  thread_id : String,
) -> @miniapp_contracts.MiniappThread? {
  for thread in snapshot.threads {
    if thread.id == thread_id {
      return Some(thread)
    }
  }
  None
}

///|
fn miniapp_run_by_id(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  run_id : String,
) -> @miniapp_contracts.MiniappRun? {
  for run in snapshot.runs {
    if run.id == run_id {
      return Some(run)
    }
  }
  None
}

///|
fn miniapp_agent_exists(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  agent_id : String,
) -> Bool {
  miniapp_agent_by_id(snapshot, agent_id) is Some(_)
}

///|
fn miniapp_message_exists(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  message_id : String,
) -> Bool {
  for message in snapshot.messages {
    if message.id == message_id {
      return true
    }
  }
  false
}

///|
fn miniapp_replace_agent(
  agents : Array[@miniapp_contracts.MiniappAgent],
  next : @miniapp_contracts.MiniappAgent,
) -> Array[@miniapp_contracts.MiniappAgent] {
  agents.map(agent => if agent.id == next.id { next } else { agent })
}

///|
fn miniapp_replace_thread(
  threads : Array[@miniapp_contracts.MiniappThread],
  next : @miniapp_contracts.MiniappThread,
) -> Array[@miniapp_contracts.MiniappThread] {
  let replaced = threads.map(thread => {
    if thread.id == next.id {
      next
    } else {
      thread
    }
  })
  for thread in threads {
    if thread.id == next.id {
      return replaced
    }
  }
  replaced + [next]
}

///|
fn miniapp_replace_run(
  runs : Array[@miniapp_contracts.MiniappRun],
  next : @miniapp_contracts.MiniappRun,
) -> Array[@miniapp_contracts.MiniappRun] {
  runs.map(run => if run.id == next.id { next } else { run })
}

///|
fn miniapp_actor_can_own(
  viewer : @miniapp_projection.MiniappViewerContext,
  owner_kind : @miniapp_contracts.MiniappOwnerKind,
  owner_id : String,
) -> Bool {
  @miniapp_projection.miniapp_viewer_is_admin(viewer) ||
  @miniapp_projection.miniapp_viewer_owns_owner(viewer, owner_kind, owner_id)
}

///|
fn miniapp_agent_owned_by_viewer(
  viewer : @miniapp_projection.MiniappViewerContext,
  agent : @miniapp_contracts.MiniappAgent,
) -> Bool {
  miniapp_actor_can_own(viewer, agent.owner_kind, agent.owner_id)
}

///|
fn miniapp_audit_event(
  id : String,
  viewer : @miniapp_projection.MiniappViewerContext,
  object_kind : String,
  object_id : String,
  action : String,
  summary : String,
  now_ms : UInt64,
) -> @miniapp_contracts.MiniappAuditEvent {
  {
    id,
    actor_user_id: viewer.user_id,
    object_kind,
    object_id,
    action,
    summary,
    created_at_ms: now_ms,
  }
}
