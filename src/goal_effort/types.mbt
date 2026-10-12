///|
priv struct EffortPeriod {
  source_data_row : Int
  period_start : String
  period_end : String
  outcome : String
  manual_period_start : String?
  manual_period_end : String?
  manual_minutes : Int?
  review_minutes : Int?
  supervision_minutes : Int?
  followup_minutes : Int?
  town_minutes : Int?
  manual_minus_town_minutes : Int?
  note : String
}

///|
priv struct EffortTotals {
  period_count : Int
  complete_town_periods : Int
  paired_periods : Int
  manual_minutes : Int?
  review_minutes : Int?
  supervision_minutes : Int?
  followup_minutes : Int?
  town_minutes : Int?
  manual_minus_town_minutes : Int?
}

///|
priv struct GoalEffort {
  source_goal : Int
  goal_id : String
  title : String
  target_book_id : String?
  enabled : Bool
  periods : Array[EffortPeriod]
  totals : EffortTotals
}

///|
priv struct EffortSource {
  digest : String
  size_bytes : Int
} derive(ToJson)

///|
priv struct EffortReport {
  contract : String
  goal_source : EffortSource
  diary_source : EffortSource
  measurement_policy : String
  goals : Array[GoalEffort]
} derive(ToJson)
