///|
pub struct BookTask {
  id : String
  goal : String?
  title : String
  kind : String
  prompt : String
  priority : Int
  requires_review : Bool
  target_pages : Array[String]
  required_role : @core.WorkerRole?
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn BookTask::new(
  id~ : String,
  goal? : String? = None,
  title~ : String,
  kind~ : String,
  prompt~ : String,
  priority~ : Int,
  requires_review~ : Bool,
  target_pages? : Array[String] = [],
  required_role? : @core.WorkerRole? = None,
) -> BookTask {
  {
    id,
    goal,
    title,
    kind,
    prompt,
    priority,
    requires_review,
    target_pages,
    required_role,
  }
}

///|
pub struct BookTaskBatch {
  goal_id : String
  goal : String
  summary : String
  tasks : Array[BookTask]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct BookGoalAcceptance {
  goal_id : String
  accepted : Bool
  reason : String
  task_count : Int
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
struct ExternalBookTask {
  id : String
  title : String
  kind : String
  prompt : String
  priority : Int
  requires_review : Bool
  target_pages : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
struct ExternalBookTaskBatch {
  goal_id : String
  goal : String
  summary : String
  tasks : Array[ExternalBookTask]
} derive(Debug, Eq, ToJson, FromJson)
