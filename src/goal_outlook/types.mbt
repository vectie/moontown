///|
#derive(ToJson)
priv struct GoalView {
  source_position : Int32
  goal : @core.StandingGoal
  state : String
  effective_cadence_ticks : Int32
  occurrence_count : Int32
  occurrence_ticks : Array[Int32]
}

///|
#derive(ToJson)
priv struct Slot {
  tick : Int32
  goal_positions : Array[Int32]
}

///|
#derive(ToJson)
priv struct Outlook {
  contract : String
  policy : String
  source_digest : String
  source_size_bytes : Int32
  start_tick : Int32
  end_tick_exclusive : Int32
  occurrence_count : Int32
  occupied_tick_count : Int32
  shared_tick_count : Int32
  peak_goals_at_tick : Int32
  goals : Array[GoalView]
  slots : Array[Slot]
}

///|
#derive(ToJson)
priv struct Change {
  goal_id : String
  state : String
  settings_changed : Bool
  outlook_changed : Bool
  occurrence_delta : Int32
  before : GoalView?
  after : GoalView?
}

///|
#derive(ToJson)
priv struct Comparison {
  contract : String
  policy : String
  start_tick : Int32
  end_tick_exclusive : Int32
  before_digest : String
  after_digest : String
  before_size_bytes : Int32
  after_size_bytes : Int32
  before_occurrences : Int32
  after_occurrences : Int32
  occurrence_delta : Int32
  before_shared_ticks : Int32
  after_shared_ticks : Int32
  before_peak_goals : Int32
  after_peak_goals : Int32
  changes : Array[Change]
}
