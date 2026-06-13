///|
pub fn policy_context_metadata(book_type : String, policy : BookPolicy) -> Json {
  {
    "book_type": book_type,
    "book_policy": policy,
    "book_loop_plan": loop_plan(policy),
    "book_internal_distance_plan": internal_distance_plan(policy),
  }
}

///|
pub fn policy_context_metadata_for_type(book_type : String) -> Json {
  policy_context_metadata(book_type, policy_for_type(book_type))
}

///|
pub fn catalog_policy_context_metadata(
  id : String,
  name : String,
  tags : Array[String],
) -> Json {
  let book_type = catalog_entry_type(id, name, tags)
  policy_context_metadata_for_type(book_type)
}
