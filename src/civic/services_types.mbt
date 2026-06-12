///|
pub struct CivicServiceDefinition {
  id : String
  title : String
  book_id : String
  service_kind : String
  module_mode : String
  persistence_mode : String
  book_role : String
  skill_mode : String
  purpose : String
  workflow : Array[String]
  agent_work : Array[String]
  place_work : Array[String]
  schema_pages : Array[String]
  wiki_pages : Array[String]
  review_queues : Array[String]
  skill_pack : String
  skill_path : String
  output_contract : String
  worker_role : @core.WorkerRole
  target_pages : Array[String]
  acceptance : Array[String]
  projection_summary : String
} derive(Debug, Eq)
