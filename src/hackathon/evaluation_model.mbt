///|
pub struct MetricValue {
  metric_id : String
  value : Double
} derive(Debug, ToJson, FromJson)

///|
pub struct BenchmarkRun {
  id : String
  submission_id : String
  reviewer_id : String
  worker_run_id : String
  state : String
  reason : String
  input_hash : String
  output_hash : String
  benchmark_version : Int
  metrics : Array[MetricValue]
  evidence : Array[String]
  queued_ms : UInt64
  finished_ms : UInt64
} derive(Debug, ToJson, FromJson)

///|
pub struct CompetitionAppeal {
  id : String
  submission_id : String
  member_id : String
  reason : String
  state : String
  resolution : String
  created_ms : UInt64
  resolved_ms : UInt64
} derive(Debug, ToJson, FromJson)

///|
pub struct CompetitionBoardEntry {
  rank : Int
  team_id : String
  team_name : String
  submission_id : String
  score : Double
  metrics : Array[MetricValue]
  reviewed_ms : UInt64
  status : String
} derive(Debug, ToJson, FromJson)

///|
struct QueueBenchmarkRequest {
  id : String
  submission_id : String
  reviewer_id : String
} derive(FromJson)

///|
pub struct BenchmarkResult {
  run_id : String
  worker_run_id : String
  metrics : Array[MetricValue]
  evidence : Array[String]
  input_hash : String
  output_hash : String
  success : Bool
  reason : String
} derive(Debug, ToJson, FromJson)

///|
struct ApproveBenchmarkRequest {
  run_id : String
  reviewer_id : String
} derive(FromJson)

///|
struct RunIdRequest {
  run_id : String
} derive(FromJson)

///|
struct RecoverBenchmarkRequest {
  run_id : String
  reason : String
} derive(FromJson)

///|
struct AppealRequest {
  id : String
  submission_id : String
  member_id : String
  reason : String
} derive(FromJson)

///|
struct ResolveAppealRequest {
  appeal_id : String
  resolution : String
} derive(FromJson)
