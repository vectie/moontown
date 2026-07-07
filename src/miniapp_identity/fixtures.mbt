///|
pub fn miniapp_identity_fixture_state() -> MiniappIdentityState {
  let user_a = @miniapp_contracts.miniapp_fixture_user(id="user-a")
  let user_b = {
    ..@miniapp_contracts.miniapp_fixture_user(id="user-b"),
    display_name: "User B",
  }
  let org_a : @miniapp_contracts.MiniappOrganization = {
    id: "org-a",
    name: "Org A",
    owner_user_id: user_a.id,
    version: 1,
  }
  let workspace_a = @miniapp_contracts.miniapp_fixture_workspace(
    user_id=user_a.id,
  )
  let workspace_b = @miniapp_contracts.miniapp_fixture_workspace(
    user_id=user_b.id,
  )
  let team_workspace : @miniapp_contracts.MiniappWorkspace = {
    id: "workspace-org-a",
    owner_kind: @miniapp_contracts.OrganizationOwner,
    owner_id: org_a.id,
    name: "Org A shared town",
    scope: @miniapp_contracts.TeamScope,
    version: 1,
  }
  {
    users: [user_a, user_b],
    organizations: [org_a],
    workspaces: [workspace_a, workspace_b, team_workspace],
    memberships: [
      {
        user_id: user_a.id,
        organization_id: org_a.id,
        roles: [
          @miniapp_contracts.OwnerRole,
          @miniapp_contracts.EditorRole,
          @miniapp_contracts.PublisherRole,
        ],
        active: true,
        version: 1,
      },
    ],
    workspace_access: [
      {
        user_id: user_a.id,
        workspace_id: workspace_a.id,
        roles: [@miniapp_contracts.OwnerRole, @miniapp_contracts.EditorRole],
        active: true,
        version: 1,
      },
      {
        user_id: user_b.id,
        workspace_id: workspace_b.id,
        roles: [@miniapp_contracts.OwnerRole, @miniapp_contracts.EditorRole],
        active: true,
        version: 1,
      },
      {
        user_id: user_a.id,
        workspace_id: team_workspace.id,
        roles: [@miniapp_contracts.EditorRole, @miniapp_contracts.PublisherRole],
        active: true,
        version: 1,
      },
    ],
    sessions: [],
    version: 1,
  }
}
