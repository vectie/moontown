///|
pub(all) struct CookbookArtifact {
  path : String
  kind : String
  owner : String
  stable_role : String
  required : Bool
  exists : Bool
} derive(Debug, Eq, ToJson)

///|
pub(all) struct MoontownCookbookManifest {
  book_id : String
  title : String
  generated_by : String
  managed_by : String
  consumed_by : String
  workspace_root : String
  manifest_path : String
  artifacts : Array[CookbookArtifact]
} derive(Debug, Eq, ToJson)

///|
pub(all) struct MoontownCookbookStatus {
  book_id : String
  workspace_root : String
  manifest_path : String
  docs_count : Int
  definition_count : Int
  runtime_state_count : Int
  required_missing_count : Int
  required_missing_paths : Array[String]
  ready : Bool
} derive(Debug, Eq, ToJson)
