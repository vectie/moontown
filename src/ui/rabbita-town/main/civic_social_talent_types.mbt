///|
priv struct ResidentSim {
  name : String
  venture : String
  need : String
  mood : String
  agent_goal : String
  plan : String
  recent_action : String
  privacy_scope : String
  zone : String
}

///|
priv struct CivicQuestSim {
  title : String
  area : String
  stage : String
  reward : String
  status : String
  status_class : String
  detail : String
  next_action : String
}

///|
priv struct SocialMatchSim {
  left : String
  right : String
  reason : String
  next_step : String
  confidence : Int
}

///|
priv struct TalentSignalSim {
  name : String
  domain : String
  project : String
  skills : String
  recent_achievement : String
  evidence_status : String
  reception_note : String
  activity : Int
}

///|
priv struct TalentRouteStopSim {
  order : Int
  stop_title : String
  signal_name : String
  talking_point : String
  operator_note : String
  evidence_status : String
  readiness : Int
}
