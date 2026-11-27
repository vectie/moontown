///|
priv struct EffortPeriod {
  source_data_row : Int32
  period_start : String
  period_end : String
  outcome : String
  manual_period_start : String?
  manual_period_end : String?
  manual_minutes : Int32?
  review_minutes : Int32?
  supervision_minutes : Int32?
  followup_minutes : Int32?
  town_minutes : Int32?
  manual_minus_town_minutes : Int32?
  note : String
}

///|
priv struct EffortTotals {
  period_count : Int32
  complete_town_periods : Int32
  paired_periods : Int32
  manual_minutes : Int32?
  review_minutes : Int32?
  supervision_minutes : Int32?
  followup_minutes : Int32?
  town_minutes : Int32?
  manual_minus_town_minutes : Int32?
}

///|
priv struct GoalEffort {
  source_goal : Int32
  goal_id : String
  title : String
  target_book_id : String?
  enabled : Bool
  periods : Array[EffortPeriod]
  totals : EffortTotals
}

///|
#derive(ToJson)
priv struct EffortSource {
  digest : String
  size_bytes : Int32
}

///|
#derive(ToJson)
priv struct EffortReport {
  contract : String
  goal_source : EffortSource
  diary_source : EffortSource
  measurement_policy : String
  goals : Array[GoalEffort]
}
