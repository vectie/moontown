///|
priv struct WorkerSim {
  id : String
  title : String
  role : String
  book_id : String
  status : @core.WorkerStatus
  zone_key : String
  energy : Int32
  load : Int32
  summary : String
}

///|
priv struct FeedItem {
  title : String
  detail : String
  tone : String
}
