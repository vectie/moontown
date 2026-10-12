///|
priv struct Claim {
  claim_id : String
  book_id : String
  topic : String
  context : String
  value : String
  source_path : String
  quote : String
} derive(ToJson)

///|
priv struct Source {
  path : String
  digest : String
  size_bytes : Int
} derive(ToJson)

///|
priv struct Group {
  topic : String
  context : String
  state : String
  books : Array[String]
  claims : Array[Claim]
} derive(ToJson)

///|
priv struct Comparison {
  contract : String
  state : String
  policy : String
  table_digest : String
  table_size_bytes : Int
  sources : Array[Source]
  groups : Array[Group]
} derive(ToJson)
