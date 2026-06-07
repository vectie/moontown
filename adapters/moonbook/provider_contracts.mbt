///|
struct BookTaskProviderMetadata {
  command : String
  args : Array[String]
  cwd : String
  workspace_root : String
} derive(Debug, Eq, ToJson, FromJson)

///|
struct BookTaskProviderManifestEntry {
  name : String
  title : String
  description : String
  kind : String
  capabilities : Array[String]
  metadata : BookTaskProviderMetadata
} derive(Debug, Eq, ToJson, FromJson)
