///|
/// Contest Express adds its competition calendar and policies to a civic brief.
pub struct CompetitionProgram {
  challenge_id : String
  state : String
  organizer : String
  timezone : String
  registration_open_ms : UInt64
  registration_close_ms : UInt64
  submission_open_ms : UInt64
  review_close_ms : UInt64
  max_team_size : Int
  daily_submission_limit : Int
  contact_url : String
  tracks : Array[CompetitionTrack]
  prizes : Array[CompetitionPrize]
  partners : Array[CompetitionPartner]
  faq : Array[CompetitionFAQ]
  announcements : Array[CompetitionAnnouncement]
  evaluator_ids : Array[String]
} derive(Debug, ToJson, FromJson)

///|
pub struct CompetitionTrack {
  id : String
  name : String
  description : String
  scoring_mode : String
  runner_key : String
  required_materials : Array[String]
  metrics : Array[MetricRule]
  gates : Array[QualificationRule]
} derive(Debug, ToJson, FromJson)

///|
pub struct MetricRule {
  id : String
  label : String
  unit : String
  direction : String
  baseline : Double
  weight : Double
} derive(Debug, ToJson, FromJson)

///|
pub struct QualificationRule {
  id : String
  label : String
  metric_id : String
  comparison : String
  threshold : Double
} derive(Debug, ToJson, FromJson)

///|
pub struct CompetitionPrize {
  track_id : String
  place : String
  description : String
} derive(Debug, ToJson, FromJson)

///|
pub struct CompetitionPartner {
  name : String
  url : String
} derive(Debug, ToJson, FromJson)

///|
pub struct CompetitionFAQ {
  category : String
  question : String
  answer : String
} derive(Debug, ToJson, FromJson)

///|
pub struct CompetitionAnnouncement {
  id : String
  title : String
  body : String
  published_ms : UInt64
} derive(Debug, ToJson, FromJson)

///|
struct SaveProgramRequest {
  program : CompetitionProgram
  brief : Challenge
} derive(FromJson)

///|
struct ProgramIdentityRequest {
  challenge_id : String
} derive(FromJson)

///|
struct ProgramTransitionRequest {
  challenge_id : String
  state : String
  reason : String
} derive(FromJson)

///|
struct AnnouncementRequest {
  challenge_id : String
  id : String
  title : String
  body : String
} derive(FromJson)
