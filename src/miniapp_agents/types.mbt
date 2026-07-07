///|
pub(all) struct MiniappAgentDraft {
  id : String
  display_name : String
  owner_kind : @miniapp_contracts.MiniappOwnerKind
  owner_id : String
  building_id : String?
  capabilities : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappAgentAttachDraft {
  agent_id : String
  building_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappChatSendDraft {
  message_id : String
  run_id : String
  thread_id : String
  building_id : String
  agent_id : String?
  body : String
  answer_summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappRunActionDraft {
  run_id : String
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappAgentRuntimeChange {
  ok : Bool
  snapshot : @miniapp_contracts.MiniappTownSnapshot
  message : String
  agent_id : String?
  thread_id : String?
  run_id : String?
} derive(Debug, Eq, ToJson, FromJson)
