///|
pub fn miniapp_fixture_publication(
  state? : MiniappVisibilityState = Published,
) -> MiniappBuildingPublication {
  {
    state,
    submitted_at_ms: Some(1000UL),
    published_at_ms: if state == Published {
      Some(2000UL)
    } else {
      None
    },
    review_summary: if state == Published {
      "approved for public town discovery"
    } else {
      "not published"
    },
  }
}

///|
pub fn miniapp_fixture_user(id? : String = "user-a") -> MiniappUser {
  { id, display_name: "User A", avatar_url: None, version: 1 }
}

///|
pub fn miniapp_fixture_workspace(
  user_id? : String = "user-a",
) -> MiniappWorkspace {
  {
    id: "workspace-\{user_id}",
    owner_kind: UserOwner,
    owner_id: user_id,
    name: "Personal town",
    scope: PersonalScope,
    version: 1,
  }
}

///|
pub fn miniapp_fixture_layer(user_id? : String = "user-a") -> MiniappTownLayer {
  {
    id: "layer-personal-\{user_id}",
    title: "Personal map",
    scope: PersonalScope,
    owner_kind: UserOwner,
    owner_id: user_id,
    version: 1,
  }
}

///|
pub fn miniapp_fixture_book(
  id? : String = "book-policy-hall",
) -> MiniappBookSummary {
  {
    id,
    title: "Policy Hall Memory",
    summary: "Accepted public policy answers and pending review items.",
    visibility: Published,
    accepted_memory_count: 3,
    pending_review_count: 1,
    version: 1,
  }
}

///|
pub fn miniapp_fixture_building(
  id? : String = "policy-hall",
  owner_id? : String = "system",
  owner_kind? : MiniappOwnerKind = SystemOwner,
  visibility? : MiniappVisibilityState = Published,
  scope? : MiniappScope = TownPublicScope,
) -> MiniappBuilding {
  {
    id,
    kind: PolicyHall,
    title: "Policy Hall",
    summary: "Ask for policy checklists and routed review.",
    owner_kind,
    owner_id,
    workspace_id: "workspace-system",
    visibility,
    scope,
    tags: ["policy", "review", "public"],
    capabilities: ["query", "review", "publish"],
    primary_book_id: "book-policy-hall",
    publication: miniapp_fixture_publication(state=visibility),
    version: 1,
    updated_at_ms: 2000UL,
  }
}

///|
pub fn miniapp_fixture_placement(
  building_id? : String = "policy-hall",
  layer_id? : String = "layer-personal-user-a",
) -> MiniappBuildingPlacement {
  {
    id: "placement-\{layer_id}-\{building_id}",
    building_id,
    layer_id,
    x: 42,
    y: 24,
    region_id: "central-plaza",
    pinned: true,
    version: 1,
  }
}

///|
pub fn miniapp_fixture_agent(
  building_id? : String = "policy-hall",
) -> MiniappAgent {
  {
    id: "agent-policy-guide",
    display_name: "Policy Guide",
    owner_kind: SystemOwner,
    owner_id: "system",
    building_id: Some(building_id),
    capabilities: ["answer", "review", "route"],
    version: 1,
  }
}

///|
pub fn miniapp_fixture_thread(
  building_id? : String = "policy-hall",
) -> MiniappThread {
  {
    id: "thread-policy-hall",
    building_id,
    title: "Policy Hall chat",
    message_count: 1,
    unread_count: 0,
    version: 1,
  }
}

///|
pub fn miniapp_fixture_run() -> MiniappRun {
  {
    id: "run-policy-hall-1",
    user_id: "user-a",
    building_id: "policy-hall",
    book_id: "book-policy-hall",
    agent_id: Some("agent-policy-guide"),
    thread_id: "thread-policy-hall",
    status: RunWaitingReview,
    summary: "Waiting for human review before accepting memory.",
    created_at_ms: 2000UL,
    updated_at_ms: 2500UL,
    version: 1,
  }
}

///|
pub fn miniapp_fixture_snapshot() -> MiniappTownSnapshot {
  let user = miniapp_fixture_user()
  let workspace = miniapp_fixture_workspace(user_id=user.id)
  let layer = miniapp_fixture_layer(user_id=user.id)
  let building = miniapp_fixture_building()
  let placement = miniapp_fixture_placement(
    building_id=building.id,
    layer_id=layer.id,
  )
  let book = miniapp_fixture_book(id=building.primary_book_id)
  let agent = miniapp_fixture_agent(building_id=building.id)
  let thread = miniapp_fixture_thread(building_id=building.id)
  {
    id: "snapshot-user-a-1",
    user,
    workspace,
    layers: [layer],
    buildings: [building],
    placements: [placement],
    books: [book],
    agents: [agent],
    threads: [thread],
    runs: [miniapp_fixture_run()],
    permissions: [
      { subject_kind: "user", subject_id: user.id, role: OwnerRole },
    ],
    generated_at_ms: 3000UL,
    version: 1,
  }
}
