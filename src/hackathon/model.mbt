///|
pub using @competition_brief {type Challenge, type RubricCriterion}

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
  programs : Array[CompetitionProgram]
  team_profiles : Array[TeamProfile]
  invitations : Array[TeamInvitation]
  submission_packages : Array[SubmissionPackage]
  benchmark_runs : Array[BenchmarkRun]
  appeals : Array[CompetitionAppeal]
  program_history : Array[CompetitionProgram]
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
    programs: [],
    team_profiles: [],
    invitations: [],
    submission_packages: [],
    benchmark_runs: [],
    appeals: [],
    program_history: [],
  }
}
