///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct FinalIntegrationManifest {
  id : String
  title : String
  domain_watches : Array[FinalIntegrationWatchSpec]
  civic_pattern_manifests : Array[FinalIntegrationTemplateSpec]
  civic_scenarios : Array[FinalIntegrationTemplateSpec]
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct FinalIntegrationWatchSpec {
  order : Int32
  domain : String
  form : String
  id : String
  title : String
  prompt : String
  target_book_id : String
  cadence_ticks : Int32
  quality_threshold : Int32
  source_policy : String
  initial_stagger_ticks : Int32
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct FinalIntegrationTemplateSpec {
  order : Int32
  form : String
  path : String
  note : String
}
