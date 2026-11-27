///|
#derive(Debug, Eq)
pub(all) struct MiniappViewerContext {
  user_id : String
  organization_ids : Array[String]
  workspace_ids : Array[String]
  roles : Array[@miniapp_contracts.MiniappPermissionRole]
  include_public : Bool
  include_system : Bool
}

///|
#derive(Debug, Eq)
pub(all) struct MiniappProjectionSummary {
  user_id : String
  visible_buildings : Int32
  visible_placements : Int32
  visible_books : Int32
  visible_agents : Int32
  visible_threads : Int32
  visible_messages : Int32
  visible_runs : Int32
  visible_audit_events : Int32
  hidden_buildings : Int32
  hidden_placements : Int32
}

///|
pub fn miniapp_viewer_context(
  user_id~ : String,
  organization_ids~ : Array[String] = [],
  workspace_ids~ : Array[String] = [],
  roles~ : Array[@miniapp_contracts.MiniappPermissionRole] = [],
  include_public~ : Bool = true,
  include_system~ : Bool = true,
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
