///|
pub(all) struct MiniappLocalBackendRoute {
  http_method : String
  path : String
  name : String
  auth_required : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappLocalBackendState {
  identity : @miniapp_identity.MiniappIdentityState
  snapshot : @miniapp_contracts.MiniappTownSnapshot
  active_session_id : String?
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappLocalBackendResponse {
  ok : Bool
  status : Int
  body : String
  state : MiniappLocalBackendState
  session_id : String?
} derive(Debug, Eq, ToJson, FromJson)
