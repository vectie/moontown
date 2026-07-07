///|
pub fn miniapp_owner_kind_id(kind : MiniappOwnerKind) -> String {
  match kind {
    UserOwner => "user"
    OrganizationOwner => "organization"
    SystemOwner => "system"
  }
}

///|
pub fn miniapp_visibility_state_id(state : MiniappVisibilityState) -> String {
  match state {
    PrivateDraft => "private_draft"
    SharedPrivate => "shared_private"
    SubmittedForPublish => "submitted_for_publish"
    Published => "published"
    Archived => "archived"
  }
}

///|
pub fn miniapp_scope_id(scope : MiniappScope) -> String {
  match scope {
    PersonalScope => "personal"
    TeamScope => "team"
    TownPublicScope => "town_public"
    SystemPublicScope => "system_public"
  }
}

///|
pub fn miniapp_permission_role_id(role : MiniappPermissionRole) -> String {
  match role {
    OwnerRole => "owner"
    EditorRole => "editor"
    ViewerRole => "viewer"
    PublisherRole => "publisher"
    AdminRole => "admin"
  }
}

///|
pub fn miniapp_run_status_id(status : MiniappRunStatus) -> String {
  match status {
    RunPending => "pending"
    RunRunning => "running"
    RunWaitingReview => "waiting_review"
    RunDone => "done"
    RunFailed => "failed"
    RunCancelled => "cancelled"
  }
}

///|
pub fn miniapp_building_kind_id(kind : MiniappBuildingKind) -> String {
  match kind {
    AgentLab => "agent_lab"
    PolicyHall => "policy_hall"
    KnowledgeHouse => "knowledge_house"
    ProjectStudio => "project_studio"
    MarketSquare => "market_square"
    ReviewCouncil => "review_council"
    SystemGateway => "system_gateway"
    CustomBuilding(id) => id
  }
}
