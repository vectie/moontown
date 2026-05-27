///|
pub enum CivicSalonReductionMode {
  MoonClawReducer
  PersistedReducer
  FixtureReducer
} derive(Debug, Eq)

///|
struct CivicSalonReductionResult {
  ideas : Array[CivicSalonIdea]
  status : @core.TaskExecutionStatus
  summary : String
  packet_id : String?
  packet_path : String?
  proposal_id : String?
  run_id : String?
  workspace_root : String
  reducer_kind : String
} derive(Eq)

///|
pub struct CivicSalonParticipantBook {
  book_id : String
  title : String
  focus_area : String
  perspective : String
  cadence : String
  current_question : String
  contribution : String
  next_artifact : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct CivicSalonIdea {
  id : String
  title : String
  summary : String
  participating_books : Array[String]
  research_questions : Array[String]
  why_it_matters : String
  next_experiment : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct CivicSalonMetric {
  participant_count : Int
  idea_count : Int
  research_question_count : Int
  participant_idea_links : Int
  participating_book_coverage_count : Int
  idea_return_home_count : Int
  average_books_per_idea : String
  structural_effectiveness_score : Int
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct CivicSalonHomeReturn {
  id : String
  building_id : String
  idea_id : String
  target_book_id : String
  target_path : String
  summary : String
  review_status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct CivicSalonScenario {
  id : String
  title : String
  building_id : String
  building_book_id : String
  domain_label : String
  topic : String
  cadence : String
  skill_name : String
  skill_description : String
  protocol_channel : String
  reduction_kind : String
  output_channel : String
  review_gate : String
  review_owner : String
  review_reason : String
  backlog_path : String
  synthesis_path : String
  metrics_path : String
  review_path : String
  returned_ideas_path : String
  participant_contract_path : String
  quality_rules : Array[String]
  skill_rules : Array[String]
  participants : Array[CivicSalonParticipantBook]
  ideas : Array[CivicSalonIdea]
} derive(Debug, Eq, ToJson, FromJson)
