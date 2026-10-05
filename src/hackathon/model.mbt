///|
/// A Mayor-published challenge lives in the existing Contest Express lane.
pub struct Challenge {
  id : String
  name : String
  topic : String
  scope : String
  possibility_wiki : String
  first_person_solution : String
  deadline_ms : UInt64
  benchmark_version : Int
  benchmark_materials : Array[String]
  evaluation_materials : Array[String]
  rubric : Array[RubricCriterion]
  published : Bool
} derive(Debug, ToJson, FromJson)

///|
pub struct RubricCriterion {
  id : String
  label : String
  max_points : Int
} derive(Debug, ToJson, FromJson)

///|
pub struct Team {
  id : String
  challenge_id : String
  name : String
  members : Array[String]
} derive(Debug, ToJson, FromJson)

///|
pub struct Submission {
  id : String
  challenge_id : String
  team_id : String
  version : Int
  artifact_url : String
  first_person_solution : String
  submitted_ms : UInt64
} derive(Debug, ToJson, FromJson)

///|
pub struct CriterionScore {
  criterion_id : String
  points : Int
  evidence : String
} derive(Debug, ToJson, FromJson)

///|
pub struct Evaluation {
  submission_id : String
  benchmark_version : Int
  reviewer : String
  scores : Array[CriterionScore]
  total : Int
  evaluated_ms : UInt64
} derive(Debug, ToJson, FromJson)

///|
pub struct LeaderboardEntry {
  rank : Int
  team_id : String
  team_name : String
  submission_id : String
  total : Int
  evaluated_ms : UInt64
} derive(Debug, ToJson, FromJson)

///|
pub struct HackathonState {
  schema : String
  revision : Int
  challenges : Array[Challenge]
  challenge_history : Array[Challenge]
  teams : Array[Team]
  submissions : Array[Submission]
  evaluations : Array[Evaluation]
} derive(Debug, ToJson, FromJson)

///|
pub fn empty_hackathon_state() -> HackathonState {
  {
    schema: "moontown.contest-express.hackathon.v1",
    revision: 0,
    challenges: [],
    challenge_history: [],
    teams: [],
    submissions: [],
    evaluations: [],
  }
}
