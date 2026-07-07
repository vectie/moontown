///|
pub(all) struct MiniappViewerContext {
  user_id : String
  organization_ids : Array[String]
  workspace_ids : Array[String]
  roles : Array[@miniapp_contracts.MiniappPermissionRole]
  include_public : Bool
  include_system : Bool
} derive(Debug, Eq)

///|
pub(all) struct MiniappProjectionSummary {
  user_id : String
  visible_buildings : Int
  visible_placements : Int
  visible_books : Int
  visible_agents : Int
  visible_threads : Int
  visible_runs : Int
  hidden_buildings : Int
  hidden_placements : Int
} derive(Debug, Eq)

///|
pub fn miniapp_viewer_context(
  user_id~ : String,
  organization_ids? : Array[String] = [],
  workspace_ids? : Array[String] = [],
  roles? : Array[@miniapp_contracts.MiniappPermissionRole] = [],
  include_public? : Bool = true,
  include_system? : Bool = true,
) -> MiniappViewerContext {
  {
    user_id,
    organization_ids,
    workspace_ids,
    roles,
    include_public,
    include_system,
  }
}
