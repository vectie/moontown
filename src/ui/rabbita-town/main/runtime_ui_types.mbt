///|
priv struct VitalityMetric {
  label : String
  value : String
  fill : Int
  tone : String
  detail : String
}

///|
priv struct WorkerSim {
  id : String
  title : String
  role : String
  book_id : String
  status : @core.WorkerStatus
  zone_key : String
  energy : Int
  load : Int
  summary : String
}

///|
priv struct FeedItem {
  title : String
  detail : String
  tone : String
}
