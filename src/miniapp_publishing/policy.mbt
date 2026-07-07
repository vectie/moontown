///|
pub fn miniapp_default_publication_policy() -> MiniappPublicationPolicy {
  {
    required_capabilities: ["query"],
    allowed_category_ids: [
      "agent_lab", "policy_hall", "knowledge_house", "project_studio", "market_square",
      "review_council", "system_gateway", "custom",
    ],
    allowed_asset_refs: [
      "moontown-building", "agent-lab", "policy-hall", "knowledge-house", "project-studio",
      "market-square", "review-council", "system-gateway",
    ],
    banned_terms: [
      "secret", "private_key", "token=", ".moontown/", "/Users/", "file://",
    ],
    max_tags: 8,
    max_summary_chars: 280,
    min_summary_chars: 12,
  }
}

///|
fn miniapp_building_category_id(
  kind : @miniapp_contracts.MiniappBuildingKind,
) -> String {
  match kind {
    @miniapp_contracts.AgentLab => "agent_lab"
    @miniapp_contracts.PolicyHall => "policy_hall"
    @miniapp_contracts.KnowledgeHouse => "knowledge_house"
    @miniapp_contracts.ProjectStudio => "project_studio"
    @miniapp_contracts.MarketSquare => "market_square"
    @miniapp_contracts.ReviewCouncil => "review_council"
    @miniapp_contracts.SystemGateway => "system_gateway"
    @miniapp_contracts.CustomBuilding(_) => "custom"
  }
}

///|
fn miniapp_public_owner_label(
  building : @miniapp_contracts.MiniappBuilding,
) -> String {
  match building.owner_kind {
    @miniapp_contracts.SystemOwner => "official"
    @miniapp_contracts.OrganizationOwner => "organization:\{building.owner_id}"
    @miniapp_contracts.UserOwner => "user:\{building.owner_id}"
  }
}
