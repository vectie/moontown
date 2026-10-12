///|
priv struct GoalView {
  source_position : Int
  goal : @core.StandingGoal
  state : String
  effective_cadence_ticks : Int
  occurrence_count : Int
  occurrence_ticks : Array[Int]
} derive(ToJson)

///|
priv struct Slot {
  tick : Int
  goal_positions : Array[Int]
} derive(ToJson)

///|
priv struct Outlook {
  contract : String
  policy : String
  source_digest : String
  source_size_bytes : Int
  start_tick : Int
  end_tick_exclusive : Int
  occurrence_count : Int
  occupied_tick_count : Int
  shared_tick_count : Int
  peak_goals_at_tick : Int
  goals : Array[GoalView]
  slots : Array[Slot]
} derive(ToJson)

///|
priv struct Change {
  goal_id : String
  state : String
  settings_changed : Bool
  outlook_changed : Bool
  occurrence_delta : Int
  before : GoalView?
  after : GoalView?
} derive(ToJson)

///|
priv struct Comparison {
  contract : String
  policy : String
  start_tick : Int
  end_tick_exclusive : Int
  before_digest : String
  after_digest : String
  before_size_bytes : Int
  after_size_bytes : Int
  before_occurrences : Int
  after_occurrences : Int
  occurrence_delta : Int
  before_shared_ticks : Int
  after_shared_ticks : Int
  before_peak_goals : Int
  after_peak_goals : Int
  changes : Array[Change]
} derive(ToJson)
