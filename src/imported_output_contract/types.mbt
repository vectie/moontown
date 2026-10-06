///|
pub(all) struct OutputFile {
  path : String
  size_bytes : Int
  digest : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct Output {
  artifact_id : String
  label : String
  mime_type : String
  included : Bool
  reference : String?
  declared_digest : String?
  files : Array[OutputFile]
  preview_path : String?
  app_entrypoint : String?
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct Source {
  agent_id : String
  agent_version : String
  package_sha256 : String
  outputs_manifest_digest : String?
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct Book {
  handle : String
  book_id : String
  name : String
  state : String
  message : String
  source : Source?
  outputs : Array[Output]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct Catalog {
  contract : String
  state : String
  message : String
  books : Array[Book]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct Selection {
  book_handle : String
  package_sha256 : String
  manifest_sha256 : String
  artifact_id : String
  path : String
  digest : String
  size_bytes : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TextReply {
  contract : String
  state : String
  message : String
  selection : Selection
  content : String?
} derive(Debug, Eq, ToJson, FromJson)
