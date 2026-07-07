///|
pub fn miniapp_projection_fixture_mixed_snapshot() -> @miniapp_contracts.MiniappTownSnapshot {
  let base = @miniapp_contracts.miniapp_fixture_snapshot()
  let private_base = @miniapp_contracts.miniapp_fixture_building(
    id="private-lab",
    owner_id="user-a",
    owner_kind=@miniapp_contracts.UserOwner,
    visibility=@miniapp_contracts.PrivateDraft,
    scope=@miniapp_contracts.PersonalScope,
  )
  let private_building = {
    ..private_base,
    kind: @miniapp_contracts.AgentLab,
    title: "Private Agent Lab",
    summary: "Draft agent experiments for one user.",
    tags: ["agent", "private", "draft"],
    capabilities: ["query", "create-agent"],
    primary_book_id: "book-private-lab",
  }
  let shared_base = @miniapp_contracts.miniapp_fixture_building(
    id="team-studio",
    owner_id="org-a",
    owner_kind=@miniapp_contracts.OrganizationOwner,
    visibility=@miniapp_contracts.SharedPrivate,
    scope=@miniapp_contracts.TeamScope,
  )
  let shared_building = {
    ..shared_base,
    kind: @miniapp_contracts.ProjectStudio,
    title: "Team Project Studio",
    summary: "Shared project planning for organization members.",
    tags: ["project", "team", "shared"],
    capabilities: ["query", "review"],
    primary_book_id: "book-team-studio",
  }
  let hidden_base = @miniapp_contracts.miniapp_fixture_building(
    id="other-private-lab",
    owner_id="user-b",
    owner_kind=@miniapp_contracts.UserOwner,
    visibility=@miniapp_contracts.PrivateDraft,
    scope=@miniapp_contracts.PersonalScope,
  )
  let hidden_building = {
    ..hidden_base,
    kind: @miniapp_contracts.KnowledgeHouse,
    title: "Other Private Lab",
    summary: "Private building owned by another user.",
    tags: ["hidden", "private"],
    capabilities: ["query"],
    primary_book_id: "book-other-private-lab",
  }
  {
    ..base,
    buildings: [
      base.buildings[0],
      private_building,
      shared_building,
      hidden_building,
    ],
    placements: [
      base.placements[0],
      @miniapp_contracts.miniapp_fixture_placement(
        building_id=private_building.id,
        layer_id=base.layers[0].id,
      ),
      @miniapp_contracts.miniapp_fixture_placement(
        building_id=shared_building.id,
        layer_id=base.layers[0].id,
      ),
      @miniapp_contracts.miniapp_fixture_placement(
        building_id=hidden_building.id,
        layer_id="layer-personal-user-b",
      ),
    ],
    books: [
      base.books[0],
      @miniapp_contracts.miniapp_fixture_book(
        id=private_building.primary_book_id,
      ),
      @miniapp_contracts.miniapp_fixture_book(
        id=shared_building.primary_book_id,
      ),
      @miniapp_contracts.miniapp_fixture_book(
        id=hidden_building.primary_book_id,
      ),
    ],
  }
}
