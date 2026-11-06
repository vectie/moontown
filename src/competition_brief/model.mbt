///|
/// Shared public brief for the Contest Express, including weekly showcases.
pub(all) struct Challenge {
  id : String
  name : String
  topic : String
  scope : String
  possibility_wiki : String
  first_person_solution : String
  deadline_ms : UInt64
  benchmark_version : Int32
  benchmark_materials : Array[String]
  evaluation_materials : Array[String]
  rubric : Array[RubricCriterion]
  published : Bool
} derive(Debug, ToJson, FromJson)

///|
pub(all) struct RubricCriterion {
  id : String
  label : String
  max_points : Int32
} derive(Debug, ToJson, FromJson)
