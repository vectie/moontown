///|
pub(all) struct FinalIntegrationManifest {
  id : String
  title : String
  domain_watches : Array[FinalIntegrationWatchSpec]
  civic_pattern_manifests : Array[FinalIntegrationTemplateSpec]
  civic_scenarios : Array[FinalIntegrationTemplateSpec]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct FinalIntegrationWatchSpec {
  order : Int
  domain : String
  form : String
  id : String
  title : String
  prompt : String
  target_book_id : String
  cadence_ticks : Int
  quality_threshold : Int
  source_policy : String
  initial_stagger_ticks : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct FinalIntegrationTemplateSpec {
  order : Int
  form : String
  path : String
  note : String
} derive(Debug, Eq, ToJson, FromJson)
